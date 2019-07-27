import getpass
import glob
import hashlib
import os
import pathlib
from collections import defaultdict

import deco
import requests
from m_base import Base
from shell_util import shell


@deco.concurrent
def concurrent_hash(fname):
    md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(128 * md5.block_size), b""):
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
    def generate_proxy_files(self, output_dir):
        base_url = "https://www.proxy-list.download/api/v0/get?l=en&t={type}"
        os.makedirs(output_dir, exist_ok=True)
        for ptype in ("socks5", "http", "https"):
            res = requests.get(base_url.format(type=ptype)).json()
            with open(os.path.join(output_dir, ptype), "w") as f:
                proxies = res["0"]["LISTA"]
                for p in proxies:
                    f.write("%s:%s" % (p["IP"], p["PORT"]))

    def encrypt_ssh_pub(self, pub_key_file, input_file, out_file=None, keep=False):
        if pub_key_url.startswith("http"):
            raise NotImplementedError
        if out_file is None:
            out_file = os.path.basename(input_file) + ".enc"

        self.shell(
            "openssl rsautl -encrypt -pubin -inkey %s -ssl -in %s -out %s"
            % (pub_key_file, input_file, out_file)
        )

        if not keep:
            self.shell("shred %s" % input_file)

    def encrypt(self, input_file, out_file=None, keep=False):
        if out_file is None:
            out_file = os.path.basename(input_file) + ".enc"

        if not keep:
            print("We will shred your file after")

        pwd = getpass.getpass("Passphrase: ")
        self.shell(
            "gpg --yes --batch --passphrase %s --output %s --symmetric --cipher-algo AES256 %s"
            % (pwd, out_file, input_file)
        )

        if not keep:
            self.shell("shred %s" % input_file)

    def decrypt(self, input_file, out_file=None):
        if out_file is None:
            out_file = os.path.basename(input_file)
            if out_file.endswith(".enc"):
                out_file = out_file[:-4]

        pwd = getpass.getpass("Passphrase: ")
        self.shell(
            "gpg --yes --batch --passphrase=%s --output %s --decrypt %s"
            % (pwd, out_file, input_file)
        )

    def rename_md5(self, glob_pattern, suffix=None):
        files = glob.glob(glob_pattern)

        renamed = set()
        dup = defaultdict(int)
        for fname, md5 in file_hashes(files):
            src = pathlib.Path(fname)
            if md5 in renamed:
                dup[md5] += 1
            else:
                target = pathlib.Path(md5 + ("" if suffix is None else ".%s" % suffix))
                self._logger.info("{0} -> {1}".format(src, target))
                src.rename(target)
                renamed.add(md5)

        if len(dup):
            self._logger.warning("Dup files: %s", dup)
