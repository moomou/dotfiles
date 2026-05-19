import os
import shutil
import sys
import tempfile
import unittest

# Make the m/ root importable when run from any cwd.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import m_dedup  # noqa: E402


class TieredDedupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="m_dedup_tests_")
        self.dedup = m_dedup.Dedup()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _write(self, name, payload):
        path = os.path.join(self.tmp, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(payload)
        return path

    def _scan(self, **overrides):
        kwargs = dict(
            roots=[self.tmp],
            min_size=1,
            follow_symlinks=False,
            head_size=m_dedup.DEFAULT_HEAD_BYTES,
            tail_size=m_dedup.DEFAULT_TAIL_BYTES,
            run_full=True,
            workers=2,
            progress=False,
        )
        kwargs.update(overrides)
        return self.dedup._find_duplicate_groups(**kwargs)

    # -- helpers --------------------------------------------------------

    @staticmethod
    def _paths(groups):
        return sorted(sorted(e[0] for e in entries) for _, entries in groups)

    # -- size tier ------------------------------------------------------

    def test_different_sizes_never_match(self):
        self._write("a", b"a" * 100)
        self._write("b", b"a" * 101)
        self.assertEqual(self._scan(), [])

    def test_identical_files_are_grouped(self):
        a = self._write("a", b"hello world" * 1000)
        b = self._write("sub/b", b"hello world" * 1000)
        self.assertEqual(self._paths(self._scan()), [[a, b]])

    # -- head tier ------------------------------------------------------

    def test_same_size_different_head_no_match(self):
        body = b"x" * (200 * 1024)
        self._write("a", b"AAA" + body)
        self._write("b", b"BBB" + body)
        self.assertEqual(self._scan(), [])

    def test_small_file_only_uses_head_hash(self):
        # File well under the head size; head hash should already cover
        # the whole file and tail/full tiers must be skipped silently.
        a = self._write("a", b"tiny payload")
        b = self._write("b", b"tiny payload")
        self.assertEqual(self._paths(self._scan(head_size=64, tail_size=64)),
                         [[a, b]])

    # -- tail tier ------------------------------------------------------

    def test_same_head_different_tail_no_match(self):
        head = b"H" * 4096
        body = b"x" * 8192
        self._write("a", head + body + b"AAA")
        self._write("b", head + body + b"BBB")
        self.assertEqual(
            self._scan(head_size=4096, tail_size=512),
            [],
            "files differ only at the tail; tail tier must eliminate them",
        )

    # -- full tier ------------------------------------------------------

    def test_same_head_same_tail_different_middle(self):
        # Files identical at head and tail but different in the middle.
        # Only the full-hash tier can catch this.
        head = b"H" * 1024
        tail = b"T" * 1024
        mid_a = b"a" * 8192
        mid_b = b"b" * 8192
        self._write("a", head + mid_a + tail)
        self._write("b", head + mid_b + tail)

        with_full = self._scan(head_size=1024, tail_size=1024, run_full=True)
        self.assertEqual(with_full, [], "full hash must catch middle-only divergence")

        without_full = self._scan(head_size=1024, tail_size=1024, run_full=False)
        self.assertEqual(len(without_full), 1,
                         "quick mode collides on head+tail-only-equal files")

    # -- hard links / symlinks -----------------------------------------

    def test_hardlinks_are_deduplicated_at_scan(self):
        a = self._write("a", b"same content " * 100)
        b = os.path.join(self.tmp, "b")
        os.link(a, b)
        # Only one of the aliases should survive the inode-dedupe; group
        # of one is not a duplicate group.
        self.assertEqual(self._scan(), [])

    def test_symlinks_skipped_by_default(self):
        a = self._write("a", b"payload " * 100)
        # A symlink whose target has identical content should not produce
        # a duplicate group, because the symlink is not a regular file.
        link = os.path.join(self.tmp, "link")
        os.symlink(a, link)
        self.assertEqual(self._scan(), [])


class CliInputTests(unittest.TestCase):
    def test_to_bool_handles_simple_argparse_outputs(self):
        self.assertTrue(m_dedup._to_bool(True))
        self.assertTrue(m_dedup._to_bool("true"))
        self.assertTrue(m_dedup._to_bool("Yes"))
        self.assertTrue(m_dedup._to_bool("1"))
        # Critically, strings like 'false' must NOT be truthy.
        self.assertFalse(m_dedup._to_bool("false"))
        self.assertFalse(m_dedup._to_bool("0"))
        self.assertFalse(m_dedup._to_bool(""))
        self.assertFalse(m_dedup._to_bool(None))

    def test_to_int_rejects_bad_input(self):
        self.assertEqual(m_dedup._to_int("42", "x"), 42)
        with self.assertRaises(ValueError):
            m_dedup._to_int("abc", "x")
        with self.assertRaises(ValueError):
            m_dedup._to_int("-1", "x", min_value=0)


class KeepStrategyTests(unittest.TestCase):
    def test_keep_strategies_pick_expected_path(self):
        paths = ["/a/b/long_name.txt", "/a/b/x.txt", "/z/y.txt"]
        self.assertEqual(m_dedup.KEEP_STRATEGIES["first"](paths), "/a/b/long_name.txt")
        self.assertEqual(m_dedup.KEEP_STRATEGIES["last"](paths), "/z/y.txt")
        self.assertEqual(m_dedup.KEEP_STRATEGIES["shortest"](paths), "/z/y.txt")
        self.assertEqual(m_dedup.KEEP_STRATEGIES["longest"](paths), "/a/b/long_name.txt")


class DeleteSafetyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="m_dedup_del_")
        self.dedup = m_dedup.Dedup()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _write(self, name, payload):
        path = os.path.join(self.tmp, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(payload)
        return path

    def test_dry_run_does_not_delete(self):
        a = self._write("a", b"same" * 1000)
        b = self._write("b", b"same" * 1000)
        self.dedup.delete(self.tmp)  # apply defaults to False
        self.assertTrue(os.path.exists(a))
        self.assertTrue(os.path.exists(b))

    def test_apply_deletes_duplicates_keeps_one(self):
        a = self._write("dir1/a", b"same" * 1000)
        b = self._write("dir2/a", b"same" * 1000)
        c = self._write("dir3/a", b"same" * 1000)
        self.dedup.delete(self.tmp, apply=True, keep="first")
        surviving = [p for p in (a, b, c) if os.path.exists(p)]
        self.assertEqual(len(surviving), 1)
        # `first` is lexicographically smallest path.
        self.assertEqual(surviving[0], min(a, b, c))

    def test_apply_with_string_false_is_still_dry_run(self):
        # simple_argparse turns "--apply false" into apply="false".
        # That must not be treated as truthy.
        a = self._write("a", b"same" * 1000)
        b = self._write("b", b"same" * 1000)
        self.dedup.delete(self.tmp, apply="false")
        self.assertTrue(os.path.exists(a))
        self.assertTrue(os.path.exists(b))

    def test_keep_dir_protects_files(self):
        canonical_dir = os.path.join(self.tmp, "canonical")
        os.makedirs(canonical_dir)
        a = self._write("canonical/a", b"same" * 1000)
        b = self._write("scratch/b", b"same" * 1000)
        c = self._write("scratch/c", b"same" * 1000)
        self.dedup.delete(self.tmp, apply=True, keep_dir=canonical_dir)
        self.assertTrue(os.path.exists(a), "file in keep_dir must survive")
        self.assertFalse(os.path.exists(b))
        self.assertFalse(os.path.exists(c))

    def test_keep_dir_multiple_protected_files_all_survive(self):
        canonical_dir = os.path.join(self.tmp, "canonical")
        os.makedirs(canonical_dir)
        a1 = self._write("canonical/a1", b"same" * 1000)
        a2 = self._write("canonical/a2", b"same" * 1000)
        b = self._write("scratch/b", b"same" * 1000)
        self.dedup.delete(self.tmp, apply=True, keep_dir=canonical_dir)
        self.assertTrue(os.path.exists(a1))
        self.assertTrue(os.path.exists(a2))
        self.assertFalse(os.path.exists(b))

    def test_modified_file_is_not_deleted(self):
        a = self._write("a", b"same" * 1000)
        b = self._write("b", b"same" * 1000)

        # Patch os.unlink to mutate `b` (whichever is the duplicate) before
        # the real unlink runs. Easier: override _find_duplicate_groups to
        # return a stale mtime so the re-stat check rejects deletion.
        groups = self.dedup._find_duplicate_groups(
            roots=[self.tmp], min_size=1, follow_symlinks=False,
            head_size=64, tail_size=64, run_full=True, workers=1,
            progress=False,
        )
        self.assertEqual(len(groups), 1)
        size, entries = groups[0]
        # Replace the recorded mtime_ns with a wrong value to simulate a
        # change between scan and delete.
        tampered = [(e[0], e[1], e[2], e[3], e[4] + 1) for e in entries]
        # Run the delete loop with tampered metadata by monkey-patching
        # _find_duplicate_groups for one call.
        original = self.dedup._find_duplicate_groups
        try:
            self.dedup._find_duplicate_groups = (  # type: ignore[assignment]
                lambda **kw: [(size, tampered)]
            )
            self.dedup.delete(self.tmp, apply=True, head_size=64, tail_size=64)
        finally:
            self.dedup._find_duplicate_groups = original  # type: ignore[assignment]
        # Both files must still exist because the re-stat detected the
        # (fake) change.
        self.assertTrue(os.path.exists(a))
        self.assertTrue(os.path.exists(b))


if __name__ == "__main__":
    unittest.main()
