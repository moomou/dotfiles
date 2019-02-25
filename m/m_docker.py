import os
import contextlib
import shutil

import constant
from util import get_config_yml, m_path

from m_base import Base

GCR_TAG = "gcr.io/euraio/{img}:{tag}"


class Docker(Base):
    def build(self, app, build_args=""):
        extra_args = []
        if build_args:
            extra_args.extend(["--build-arg %s" % kv for kv in build_args.split(",")])
        self.shell(
            "docker build -t {tag} -f app/{app}/Dockerfile {extra} .".format(
                tag=GCR_TAG.format(img=app, tag="latest"),
                app=app,
                extra=' '.join(extra_args),
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
