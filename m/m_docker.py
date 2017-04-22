import argparse
import logging
import logging.config
import os
import shutil
import subprocess

import ruamel.yaml as yaml

import constant

from m_base import Base

class Docker(Base):
    def load(self, app):
        '''Load a docker gz file into docker images'''
        self.shell('docker load < %s.gz' % (app, app))

    def build(self, app):
        '''Build a docker image of the app and push to remote repo'''
        config_yml = get_config_yml()
        remove_after = ['./gitlab_rsa', './.dockerignore']

        if config_yml.get('resolve'):
            for src, dst in config_yml.get('resolve').items():
                shutil.copy2(src, dst)
                remove_after.append(dst)

        # Copy gitlab cert
        shutil.copy2(os.path.join(constant.SSH_DIR, 'key', 'gitlab_rsa'), './gitlab_rsa')
        # Copy over dockerignore
        shutil.copy2(os.path.join(constant.M_ROOT, '.dockerignore'), './.dockerignore')

        self.shell('docker build . -t %s' % app)
        self.shell('docker save %s | gzip -c > ~/dev/chub/%s.gz' % (app, app))
        [os.remove(f) for f in remove_after]

        cmd = 'cd %s && git add . && git ci -m updated %s.gz && git push origin master' % (path('chub'), app)
        self.shell(cmd)
