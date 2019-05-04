import logging
import os
import shutil
import constant
import contextlib

from util import get_config_yml, m_path

from git_util import groot
from m_base import Base

DEFAULT_GCR_TAG = "gcr.io/euraio/{img}:{tag}"

DOCKERIGNORE = ".dockerignore"
DOCKERUNIGNORE = "dockerunignore"


class WithTempFile:
    def __init__(self, existing_file, tmp_file, merge_fn=None):
        self.existing_file = existing_file
        self.merge_fn = merge_fn
        self.tmp_file = tmp_file

        self.logger = logging.getLogger(type(self).__name__)

    def __bak_name(self, existing_name):
        return os.path.join(existing_name + ".bak")

    def __enter__(self):
        if not os.path.exists(self.tmp_file):
            self.logger.debug("__enter__ skipped due to missing %s" % self.tmp_file)
            return

        # mv the file
        bak_path = self.__bak_name(self.existing_file)
        shutil.move(self.existing_file, bak_path)

        # create new file
        if self.merge_fn:
            with open(bak_path) as fbak:
                with open(self.tmp_file) as tmpfile:
                    with open(self.existing_file, "wb") as f:
                        self.logger.debug("merged files to %s", self.existing_file)
                        f.write(self.merge_fn(fbak.read(), tmpfile.read()))
        else:
            self.logger.debug("copied files to %s", self.existing_file)
            shutil.copy(self.tmp_file, self.existing_file)

        self.logger.debug("__enter__")

    def __exit__(self, exception_type, exception_val, trc):
        if not os.path.exists(self.tmp_file):
            self.logger.debug("__exit__ skipped")
            return

        # mv back the file
        shutil.move(self.__bak_name(self.existing_file), self.existing_file)
        self.logger.debug("__exit__")


def merge_ignore_unignore(ignore, unignore) -> bytes:
    ignore = ignore.split("\n")
    unignore = set(unignore.split("\n"))

    merged = []
    for line in ignore:
        if line in unignore:
            continue
        merged.append(line)

    return "\n".join(merged).encode("utf-8")


class Docker(Base):
    def build(self, app, build_args=""):
        """
        Default docker build that works with $GROOT/app folder structure.
        Also supports serunignore files
        """
        extra_args = []

        if build_args:
            extra_args.extend(["--build-arg %s" % kv for kv in build_args.split(",")])

        unignore_path = os.path.join(
            os.path.curdir, "app/{app}/{cfg}".format(app=app, cfg=DOCKERUNIGNORE)
        )
        with WithTempFile(
            os.path.join(os.path.curdir, DOCKERIGNORE),
            unignore_path,
            merge_ignore_unignore,
        ):
            self._logger.info("Starting to build")
            self.shell(
                "docker build -t {tag} -f app/{app}/Dockerfile {extra} .".format(
                    tag=DEFAULT_GCR_TAG.format(img=app, tag="latest"),
                    app=app,
                    extra=" ".join(extra_args),
                )
            )

    def load(self, app):
        """Load a docker gz file into docker images"""
        self.shell("docker load < %s.gz" % app)

    def build_2_gz(self, app, name=None):
        name = name or app

        self.build(app)
        self.shell("docker save %s | gzip -c > %s.gz" % (app, name))

    def build_2_gcloud(self, app, name=None):
        name = name or app

        self.build_2_gz(app, name)

        self.shell(
            "gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp %s.gz gs://moomou2/%s.gz"
            % (name, name)
        )

    def build_2_chub(self, app, name=None):
        self.build(app, True)

        self.shell("docker save %s | gzip -c > ~/dev/chub/%s.gz" % (app, app))
        cmd = (
            "cd %s && git add . && git ci -m updated %s.gz && git push origin master"
            % (m_path("chub"), app)
        )
        self.shell(cmd)

    def xbuild(self, app, include_cert=False):
        """Build a docker image of the app and push to remote repo"""
        config_yml = get_config_yml()
        remove_after = ["./.dockerignore", "./gitlab_rsa"]

        if config_yml.get("resolve"):
            for src, dst in config_yml.get("resolve").items():
                shutil.copy2(src, dst)
                remove_after.append(dst)

        # Copy gitlab cert
        if include_cert:
            shutil.copy2(
                os.path.join(constant.SSH_DIR, "key", "gitlab_rsa"), "./gitlab_rsa"
            )

        # Copy over dockerignore
        shutil.copy2(os.path.join(constant.M_ROOT, ".dockerignore"), "./.dockerignore")

        self.shell("docker build . -t %s" % app)

        with contextlib.suppress(FileNotFoundError):
            for f in remove_after:
                os.remove(f)
