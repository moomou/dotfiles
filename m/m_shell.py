import glob
import hashlib
import os
import pathlib
from collections import defaultdict

import deco
from m_base import Base


@deco.concurrent
def concurrent_hash(fname):
    md5 = hashlib.md5()
    with open(fname, 'rb') as f:
        for chunk in iter(lambda: f.read(128 * md5.block_size), b''):
            md5.update(chunk)
    return md5.hexdigest()


@deco.synchronized
def file_hashes(files):
    hashes = {}
    for idx, fname in enumerate(files):
        hashes[idx] = concurrent_hash(fname)
    results = []
    for idx, md5 in hashes.items():
        results.append((files[idx], md5))
    return results


class Shell(Base):
    def rename_md5(self, glob_pattern):
        files = glob.glob(glob_pattern)

        renamed = set()
        dup = defaultdict(int)
        for fname, md5 in file_hashes(files):
            src = pathlib.Path(fname)
            if md5 in renamed:
                dup[md5] += 1
            else:
                target = pathlib.Path('%s.csv' % md5)
                self.__logger.info(src, '->', target)
                src.rename(target)
                renamed.add(md5)

        self.__logger.warning('Dup files: %s', dup)
