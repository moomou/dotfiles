import contextlib
import logging
import os
import pathlib as pl
import shutil
from enum import Enum

import yaml

import constant
from m_base import Base
from util import get_config_yml, m_path

DEFAULT_CR_TAG = "ghcr.io/mou-dev-org/{img}:{tag}"
DOCKERIGNORE = ".dockerignore"
DOCKERUNIGNORE = "dockerunignore"
DOCKERFILE = "Dockerfile"


class AppLang(Enum):
    golang = 0
    nodejs = 1
    rust = 2


class Docker(Base):
    def build(
        self,
        app,
        build_args="",
        tag="latest",
    ):
        """
        Default docker build that works with $GROOT/app folder structure.
        Also supports dockerunignore files
        """
        apps_dir = pl.Path(os.path.curdir) / "app"
        app_dir = apps_dir / app
        if not app_dir.exists():
            self._logger.fatal(f"app `{app}` not found")

        app_dockerfile = app_dir / "Dockerfile"
        app_cfg = {"config": {}}
        if not app_dockerfile.exists():
            app_yml = app_dir / "app.yml"

            if not app_yml.exists():
                self._logger.fatal("Missing `app.yml`")

            with open(app_yml) as f:
                app_cfg = yaml.safe_load(f)

            try:
                lang = AppLang[app_cfg["lang"]]
            except KeyError:
                self._logger.fatal(f"`{app_cfg['lang']}` not supported")

            df_path = constant.M_ROOT / "dockerfiles" / f"{DOCKERFILE}.{lang.name}"
            app_dockerfile = df_path

            self._logger.debug(f"Using dockerfile:: `{df_path}`")

        extra_args = [f"--build-arg APP={app}"]
        if build_args:
            extra_args.extend(["--build-arg %s" % kv for kv in build_args.split(",")])
        if app_cfg.get("config", None):
            cfg_build_arg = app_cfg["config"].get("build_arg", "")
            if cfg_build_arg:
                extra_args.extend(
                    ["--build-arg %s" % kv for kv in cfg_build_arg.split(",")]
                )

        unignore_path = os.path.join(
            os.path.curdir, "app/{app}/{cfg}".format(app=app, cfg=DOCKERUNIGNORE)
        )

        container_tag_template = app_cfg.get("tag_template", DEFAULT_CR_TAG)
        with WithTempFile(
            os.path.join(os.path.curdir, DOCKERIGNORE),
            unignore_path,
            merge_ignore_unignore,
        ):
            with WithCopySymlink(app_cfg["config"].get("symlinks", "")):
                self._logger.info("Starting to build")
                img_name = app.replace("_", "-")

                self.shell(
                    "docker build -t {tag} -f {df_path} {extra} .".format(
                        tag=container_tag_template.format(img=img_name, tag=tag),
                        df_path=str(app_dockerfile),
                        extra=" ".join(extra_args),
                    )
                )

    def clean(self):
        self.shell(
            "docker rmi $(docker images --filter 'dangling=true' -q --no-trunc)",
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


class WithCopySymlink:
    def __init__(self, links) -> None:
        """
        simple class to remember symlink and copy the target
        over on __enter__ and restore on __exit__
        """
        self.symlinks = [link for link in links.split(",")]
        self.symlink_target = {}

    def __enter__(self):
        for symlink in self.symlinks:
            p = pl.Path(symlink)

            if not p.is_symlink():
                continue

            resolved = self.symlink_target[symlink] = p.resolve()
            p.unlink()

            shutil.copytree(resolved, symlink)

    def __exit__(self, exception_type, exception_val, trc):
        for symlink, resolved in self.symlink_target.items():
            shutil.rmtree(symlink)

            symlink_path = pl.Path(symlink)
            os.symlink(
                os.path.relpath(resolved, symlink_path.parent),
                symlink,
            )


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
