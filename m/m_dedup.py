"""Tiered duplicate-file finder/deleter for the m CLI.

The strategy avoids reading whole files when cheaper checks can already rule
out a match.  Each tier produces smaller candidate groups for the next.

  Tier 1: group by exact ``st_size``.
  Tier 2: hash the first ``head_size`` bytes (default 512 KiB).
  Tier 3: hash the last  ``tail_size`` bytes (default 512 KiB).
  Tier 4: full-file hash (always run for ``delete``; ``--quick`` for ``find``).

Tiers 3 and 4 are auto-skipped for groups whose files are already fully
covered by an earlier tier (e.g. a file smaller than ``head_size`` does not
need a tail or full hash because the head hash already saw every byte).
"""

import concurrent.futures as cf
import hashlib
import json
import os
import stat
import sys
from collections import defaultdict

from m_base import Base


DEFAULT_HEAD_BYTES = 512 * 1024
DEFAULT_TAIL_BYTES = 512 * 1024
IO_CHUNK_BYTES = 1024 * 1024
HASH_DIGEST_BYTES = 16


def _to_bool(value):
    """Robustly coerce CLI flag values to bool.

    The minimal CLI parser in ``simple_argparse`` produces ``True`` for a bare
    ``--flag`` and the string ``"value"`` for ``--flag value``.  We treat
    only the explicit truthy spellings as ``True`` so that
    ``--apply false`` does *not* accidentally enable destructive behaviour.
    """
    if value is True:
        return True
    if value is False or value is None:
        return False
    if isinstance(value, str):
        return value.strip().lower() in ("1", "true", "yes", "on")
    return bool(value)


def _to_int(value, name, *, min_value=None):
    try:
        i = int(value)
    except (TypeError, ValueError):
        raise ValueError(f"--{name} must be an integer; got {value!r}")
    if min_value is not None and i < min_value:
        raise ValueError(f"--{name} must be >= {min_value}; got {i}")
    return i


def _human_size(n):
    n = float(n)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if abs(n) < 1024.0:
            return f"{n:.1f} {unit}"
        n /= 1024.0
    return f"{n:.1f} PiB"


def _new_hasher():
    return hashlib.blake2b(digest_size=HASH_DIGEST_BYTES)


def _open_nofollow(path):
    """Open a file refusing symlink traversal where the platform supports it.

    Returns a raw fd. ``O_NOFOLLOW`` defends against TOCTOU swaps between
    ``lstat`` (during the scan) and ``open`` (during hashing/deletion).
    """
    flags = os.O_RDONLY
    flags |= getattr(os, "O_NOFOLLOW", 0)
    flags |= getattr(os, "O_CLOEXEC", 0)
    return os.open(path, flags)


def _hash_range(path, offset, length):
    """Hash ``length`` bytes starting at ``offset``.

    Returns ``(digest, error)`` where exactly one is ``None``.
    """
    h = _new_hasher()
    try:
        fd = _open_nofollow(path)
    except OSError as e:
        return None, e
    try:
        if offset:
            os.lseek(fd, offset, os.SEEK_SET)
        remaining = length
        while remaining > 0:
            chunk = os.read(fd, min(IO_CHUNK_BYTES, remaining))
            if not chunk:
                break
            h.update(chunk)
            remaining -= len(chunk)
    except OSError as e:
        return None, e
    finally:
        try:
            os.close(fd)
        except OSError:
            pass
    return h.digest(), None


def _hash_full(path):
    h = _new_hasher()
    try:
        fd = _open_nofollow(path)
    except OSError as e:
        return None, e
    try:
        while True:
            chunk = os.read(fd, IO_CHUNK_BYTES)
            if not chunk:
                break
            h.update(chunk)
    except OSError as e:
        return None, e
    finally:
        try:
            os.close(fd)
        except OSError:
            pass
    return h.digest(), None


KEEP_STRATEGIES = {
    "first":    lambda paths: min(paths),
    "last":     lambda paths: max(paths),
    "shortest": lambda paths: min(paths, key=lambda p: (len(p), p)),
    "longest":  lambda paths: max(paths, key=lambda p: (len(p), p)),
    "oldest":   lambda paths: min(paths, key=lambda p: (os.path.getmtime(p), p)),
    "newest":   lambda paths: max(paths, key=lambda p: (os.path.getmtime(p), p)),
}


class Dedup(Base):
    """Find and delete duplicate files with a tiered fingerprint strategy."""

    def __init__(self):
        super().__init__(lazy_import=["tqdm"])

    # ------------------------------------------------------------------ #
    # File enumeration                                                   #
    # ------------------------------------------------------------------ #

    def _iter_files(self, roots, *, min_size, follow_symlinks):
        seen_inodes = set()
        skipped = defaultdict(int)

        def emit(path):
            try:
                st = os.stat(path) if follow_symlinks else os.lstat(path)
            except OSError as e:
                skipped["stat_error"] += 1
                self._logger.debug("stat failed: %s: %s", path, e)
                return
            if not follow_symlinks and stat.S_ISLNK(st.st_mode):
                skipped["symlink"] += 1
                return
            if not stat.S_ISREG(st.st_mode):
                skipped["non_regular"] += 1
                return
            if st.st_size < min_size:
                skipped["below_min_size"] += 1
                return
            inode_key = (st.st_dev, st.st_ino)
            if inode_key in seen_inodes:
                skipped["hardlink_alias"] += 1
                return
            seen_inodes.add(inode_key)
            yield (path, st.st_size, st.st_dev, st.st_ino, st.st_mtime_ns)

        for root in roots:
            root = os.fspath(root)
            if not os.path.exists(root):
                self._logger.warning("path does not exist, skipping: %s", root)
                skipped["missing"] += 1
                continue
            if os.path.isfile(root):
                yield from emit(root)
                continue
            if not os.path.isdir(root):
                self._logger.warning("not a file or directory, skipping: %s", root)
                continue
            for dirpath, _dirs, filenames in os.walk(root, followlinks=follow_symlinks):
                for name in filenames:
                    yield from emit(os.path.join(dirpath, name))

        for reason, n in skipped.items():
            if n:
                self._logger.info("skipped %d files (%s)", n, reason)

    # ------------------------------------------------------------------ #
    # Tier refinement                                                    #
    # ------------------------------------------------------------------ #

    def _refine(self, sized_groups, label, *, hasher_for_size, workers,
                progress):
        """Split each ``(size, entries)`` group by a hash digest of each file.

        ``hasher_for_size(size)`` returns either a ``Callable[[path], (digest, err)]``
        or ``None`` to indicate the tier is unnecessary for that size — in which
        case the group passes through unchanged.
        """
        jobs = []
        passthrough = set()
        for idx, (size, entries) in enumerate(sized_groups):
            hf = hasher_for_size(size)
            if hf is None:
                passthrough.add(idx)
                continue
            for entry in entries:
                jobs.append((idx, entry[0], hf))

        fingerprints = {}
        errors = 0
        if jobs:
            bar = None
            if progress and len(jobs) >= 50:
                try:
                    tqdm_mod = self._module("tqdm")
                    bar = tqdm_mod.tqdm(total=len(jobs), desc=label, unit="file",
                                        leave=False, file=sys.stderr)
                except Exception:
                    bar = None
            with cf.ThreadPoolExecutor(max_workers=workers) as ex:
                futs = {
                    ex.submit(hf, path): (idx, path)
                    for idx, path, hf in jobs
                }
                for fut in cf.as_completed(futs):
                    key = futs[fut]
                    try:
                        digest, err = fut.result()
                    except Exception as e:  # pragma: no cover - defensive
                        digest, err = None, e
                    if err is not None:
                        errors += 1
                        self._logger.debug("hash error: %s: %s", key[1], err)
                    fingerprints[key] = digest
                    if bar is not None:
                        bar.update(1)
            if bar is not None:
                bar.close()
        if errors:
            self._logger.warning("%s: %d files unreadable, dropped", label, errors)

        out = []
        for idx, (size, entries) in enumerate(sized_groups):
            if idx in passthrough:
                out.append((size, entries))
                continue
            sub = defaultdict(list)
            for entry in entries:
                digest = fingerprints.get((idx, entry[0]))
                if digest is None:
                    continue
                sub[digest].append(entry)
            for bucket in sub.values():
                if len(bucket) > 1:
                    out.append((size, bucket))

        self._logger.info(
            "after %s: %d groups, %d candidate files",
            label, len(out), sum(len(e) for _, e in out),
        )
        return out

    def _find_duplicate_groups(self, roots, *, min_size, follow_symlinks,
                               head_size, tail_size, run_full, workers,
                               progress=True):
        entries = list(self._iter_files(
            roots, min_size=min_size, follow_symlinks=follow_symlinks))
        self._logger.info("scanned %d eligible files", len(entries))

        by_size = defaultdict(list)
        for entry in entries:
            by_size[entry[1]].append(entry)
        sized_groups = [(sz, es) for sz, es in by_size.items() if len(es) > 1]
        self._logger.info(
            "after size: %d groups, %d candidate files",
            len(sized_groups), sum(len(e) for _, e in sized_groups),
        )
        if not sized_groups:
            return []

        def head_hasher(size):
            length = min(head_size, size)
            return lambda p: _hash_range(p, 0, length)
        sized_groups = self._refine(sized_groups, "head hash",
                                    hasher_for_size=head_hasher,
                                    workers=workers, progress=progress)
        if not sized_groups:
            return []

        def tail_hasher(size):
            # If the head already saw the whole file, skip.
            if size <= head_size:
                return None
            # Cap tail length so head and tail never overlap (avoids
            # hashing the same byte twice while preserving correctness).
            length = min(tail_size, size - head_size)
            offset = size - length
            return lambda p: _hash_range(p, offset, length)
        sized_groups = self._refine(sized_groups, "tail hash",
                                    hasher_for_size=tail_hasher,
                                    workers=workers, progress=progress)
        if not sized_groups:
            return []

        if run_full:
            def full_hasher(size):
                # When head + tail (capped non-overlapping above) already
                # cover the entire file, a full hash adds no information.
                if size <= head_size + tail_size:
                    return None
                return _hash_full
            sized_groups = self._refine(sized_groups, "full hash",
                                        hasher_for_size=full_hasher,
                                        workers=workers, progress=progress)

        return sized_groups

    # ------------------------------------------------------------------ #
    # Public commands                                                    #
    # ------------------------------------------------------------------ #

    def find(self, *roots, min_size=1, follow_symlinks=False,
             head_size=DEFAULT_HEAD_BYTES, tail_size=DEFAULT_TAIL_BYTES,
             quick=False, workers=4, output=None):
        """Scan ``roots`` and print duplicate groups (read-only).

        Args:
            roots: one or more directories or files to scan
            min_size: ignore files smaller than this many bytes (default 1)
            follow_symlinks: descend into symlinked directories
            head_size: bytes to hash at the start of each file (default 524288)
            tail_size: bytes to hash at the end of each file (default 524288)
            quick: skip the full-file hash tier (faster, but for files
                   larger than head + tail bytes only the head/tail are
                   compared, so identical fingerprints there imply --
                   not prove -- equality)
            workers: number of concurrent hash workers (default 4)
            output: write the duplicate groups as JSON to this path
        """
        if not roots:
            self._logger.fatal("provide at least one path to scan")
        try:
            min_size = _to_int(min_size, "min_size", min_value=0)
            head_size = _to_int(head_size, "head_size", min_value=0)
            tail_size = _to_int(tail_size, "tail_size", min_value=0)
            workers = _to_int(workers, "workers", min_value=1)
        except ValueError as e:
            self._logger.fatal(str(e))

        follow_symlinks = _to_bool(follow_symlinks)
        quick = _to_bool(quick)

        groups = self._find_duplicate_groups(
            roots=list(roots),
            min_size=min_size,
            follow_symlinks=follow_symlinks,
            head_size=head_size,
            tail_size=tail_size,
            run_full=not quick,
            workers=workers,
        )

        if not groups:
            self._logger.info("no duplicates found")
            return

        groups.sort(key=lambda g: -(g[0] * (len(g[1]) - 1)))
        total_reclaim = 0
        for size, entries in groups:
            reclaim = size * (len(entries) - 1)
            total_reclaim += reclaim
            print(f"\n[{_human_size(size)}] {len(entries)} copies "
                  f"-- reclaim {_human_size(reclaim)}")
            for entry in sorted(entries, key=lambda e: e[0]):
                print(f"    {entry[0]}")

        self._logger.info(
            "found %d duplicate groups, %d redundant files, "
            "reclaimable %s%s",
            len(groups),
            sum(len(e) - 1 for _, e in groups),
            _human_size(total_reclaim),
            "  (quick mode: large files verified by head+tail only)"
            if quick else "",
        )

        if output:
            payload = [
                {"size": size,
                 "paths": [e[0] for e in sorted(entries, key=lambda e: e[0])]}
                for size, entries in groups
            ]
            with open(output, "w") as fh:
                json.dump(payload, fh, indent=2)
            self._logger.info("wrote %s", output)

    def delete(self, *roots, apply=False, keep="first", keep_dir=None,
               min_size=1, follow_symlinks=False,
               head_size=DEFAULT_HEAD_BYTES, tail_size=DEFAULT_TAIL_BYTES,
               workers=4):
        """Find duplicates and delete the redundant copies.

        Dry-run by default: pass ``--apply`` to actually unlink.  The
        full-file hash tier is always run for delete (no ``--quick``).
        Each file is re-stat'd immediately before unlinking and the call
        is aborted for that file if anything changed since the scan.

        Args:
            roots: one or more directories or files to scan
            apply: pass this flag to actually delete (else dry-run)
            keep: which file in each group survives
                  (first|last|shortest|longest|oldest|newest); default ``first``
                  = lexicographically smallest path
            keep_dir: path prefix; any file whose path is under this directory
                      is protected and will never be deleted, regardless of
                      ``--keep``.  If a group has at least one protected file,
                      every unprotected file in that group is treated as a
                      duplicate to delete.  Protection is *path-based*: hard-
                      linked aliases outside ``keep_dir`` are not protected.
            min_size: ignore files smaller than this many bytes (default 1)
            follow_symlinks: descend into symlinked directories
            head_size: bytes to hash at the start of each file
            tail_size: bytes to hash at the end of each file
            workers: number of concurrent hash workers (default 4)
        """
        if not roots:
            self._logger.fatal("provide at least one path to scan")
        try:
            min_size = _to_int(min_size, "min_size", min_value=0)
            head_size = _to_int(head_size, "head_size", min_value=0)
            tail_size = _to_int(tail_size, "tail_size", min_value=0)
            workers = _to_int(workers, "workers", min_value=1)
        except ValueError as e:
            self._logger.fatal(str(e))

        apply = _to_bool(apply)
        follow_symlinks = _to_bool(follow_symlinks)

        if keep not in KEEP_STRATEGIES:
            self._logger.fatal(
                "unknown --keep `%s`; choose one of: %s",
                keep, ", ".join(sorted(KEEP_STRATEGIES)),
            )

        keep_dir_abs = None
        if keep_dir:
            keep_dir_abs = os.path.abspath(keep_dir)
            if not os.path.isdir(keep_dir_abs):
                self._logger.fatal(
                    "--keep_dir does not exist or is not a directory: %s", keep_dir)

        groups = self._find_duplicate_groups(
            roots=list(roots),
            min_size=min_size,
            follow_symlinks=follow_symlinks,
            head_size=head_size,
            tail_size=tail_size,
            run_full=True,
            workers=workers,
        )

        if not groups:
            self._logger.info("no duplicates found")
            return

        keeper_picker = KEEP_STRATEGIES[keep]

        def is_protected(path):
            if keep_dir_abs is None:
                return False
            ap = os.path.abspath(path)
            return ap == keep_dir_abs or ap.startswith(keep_dir_abs + os.sep)

        groups.sort(key=lambda g: -(g[0] * (len(g[1]) - 1)))

        total_reclaim = 0
        total_dup_count = 0
        deleted_count = 0
        deleted_bytes = 0
        skipped_changed = 0

        for size, entries in groups:
            paths = [e[0] for e in entries]
            meta_by_path = {e[0]: e for e in entries}

            protected = [p for p in paths if is_protected(p)]
            if protected:
                keepers = set(protected)
            else:
                keepers = {keeper_picker(paths)}

            duplicates = [p for p in paths if p not in keepers]
            reclaim = size * len(duplicates)
            total_reclaim += reclaim
            total_dup_count += len(duplicates)

            action = "DEL " if apply else "dup "
            print(f"\n[{_human_size(size)}] {len(entries)} copies "
                  f"-- reclaim {_human_size(reclaim)}")
            for k in sorted(keepers):
                print(f"    KEEP {k}")
            for d in sorted(duplicates):
                print(f"    {action} {d}")

            if not apply:
                continue

            for d in duplicates:
                _, exp_size, exp_dev, exp_ino, exp_mtime_ns = meta_by_path[d]
                try:
                    st = os.lstat(d)
                except OSError as e:
                    skipped_changed += 1
                    self._logger.error("refusing to delete (stat failed): %s: %s", d, e)
                    continue
                if (st.st_dev != exp_dev
                        or st.st_ino != exp_ino
                        or st.st_size != exp_size
                        or st.st_mtime_ns != exp_mtime_ns):
                    skipped_changed += 1
                    self._logger.error(
                        "refusing to delete (changed since scan): %s", d)
                    continue
                try:
                    os.unlink(d)
                    deleted_count += 1
                    deleted_bytes += size
                except OSError as e:
                    self._logger.error("failed to delete %s: %s", d, e)

        if apply:
            tail = (f"; skipped {skipped_changed} (changed since scan)"
                    if skipped_changed else "")
            self._logger.info(
                "deleted %d files, reclaimed %s%s",
                deleted_count, _human_size(deleted_bytes), tail,
            )
        else:
            self._logger.info(
                "DRY-RUN: %d files would be deleted, reclaim %s; "
                "re-run with --apply to actually delete",
                total_dup_count, _human_size(total_reclaim),
            )
