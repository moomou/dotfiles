import logging
import logging.config
import os
import subprocess

from importlib import import_module

import constant
from util import run_once


class Base(object):
    def __init__(self, lazy_import=[]):
        logging.config.fileConfig(os.path.join(constant.M_ROOT, './log.conf'))
        self.logger = logging.getLogger(__name__)
        self._modules = {}
        self._lazy_import = lazy_import

        if os.environ.get('DEBUG', None):
            self.logger.setLevel(logging.DEBUG)

    @run_once
    def setup(self):
        for m_name in self._lazy_import:
            m = import_module(m_name)
            self._modules[m_name] = m

    def shell(self, cmd, timeout=None):
        p = subprocess.Popen(cmd, shell=True)

        try:
            outs, errs = p.communicate()
        except Exception as e:
            p.kill()
            outs, errs = p.communicate()

        return p.returncode, outs, errs
