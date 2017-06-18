import logging
import logging.config
import os
import subprocess

from importlib import import_module

import coloredlogs

import constant
from util import (
    read_yml,
    run_once,
)


class Base(object):
    def __init__(self, lazy_import=[]):
        logging.config.dictConfig(read_yml(
            os.path.join(constant.M_ROOT, './log.yml')))

        self._modules = {}
        self._lazy_import = lazy_import

        self.logger = logging.getLogger(type(self).__name__)

        coloredlogs.install(level='INFO', logger=self.logger)

        if os.environ.get('DEBUG', None):
            coloredlogs.install(level='DEBUG', logger=self.logger)
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
