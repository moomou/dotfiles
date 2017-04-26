import argparse
import logging
import logging.config
import os
import shutil
import subprocess

import ruamel.yaml as yaml

import constant

class Base(object):
    def __init__(self):
        logging.config.fileConfig(os.path.join(constant.M_ROOT, './log.conf'))
        self.logger = logging.getLogger(__name__)

        if os.environ.get('DEBUG', None):
            self.logger.setLevel(logging.DEBUG)

    def shell(self, cmd, timeout=None):
        p = subprocess.Popen(cmd, shell=True)

        try:
            outs, errs = p.communicate()
        except Exception as e:
            p.kill()
            outs, errs = p.communicate()

        return p.returncode, outs, errs
