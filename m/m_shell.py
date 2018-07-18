import getpass
import glob
import hashlib
import os
import pathlib
from collections import defaultdict

import deco
from m_base import Base
from shell_util import shell


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
    def encrypt(self, input_file, out_file=None):
        if out_file is None:
            out_file = os.path.basename(input_file) + '.enc'

        pwd = getpass.getpass('Passphrase: ')
        self.shell(
            'gpg --yes --batch --passphrase %s --output %s --symmetric --cipher-algo AES256 %s'
            % (pwd, out_file, input_file))

    def decrypt(self, input_file, out_file=None):
        if out_file is None:
            out_file = os.path.basename(input_file)
            if out_file.endswith('.enc'):
                out_file = out_file[:-4]

        pwd = getpass.getpass('Passphrase: ')
        self.shell('gpg --yes --batch --passphrase=%s --output %s %s' %
                   (pwd, out_file, input_file))

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
                self._logger.info(src, '->', target)
                src.rename(target)
                renamed.add(md5)

        self._logger.warning('Dup files: %s', dup)
