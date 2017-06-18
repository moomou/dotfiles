import logging
import logging.config
import os
import subprocess

from importlib import import_module

import coloredlogs

import constant
from util import read_yml


class Base(object):
    def __init__(self, lazy_import=[]):
        logging.config.dictConfig(
            read_yml(os.path.join(constant.M_ROOT, './log.yml')))

        self._modules_cache = {}
        self._lazy_import = lazy_import

        self._logger = logging.getLogger(type(self).__name__)

        coloredlogs.install(level='INFO', logger=self._logger)

        if os.environ.get('DEBUG', None):
            coloredlogs.install(level='DEBUG', logger=self._logger)
            self._logger.setLevel(logging.DEBUG)

    def _module(self, m_name):
        if m_name not in self._modules_cache:
            assert m_name in self._lazy_import, 'Import not declared'
            m = import_module(m_name)
            self._modules_cache[m_name] = m

        return self._modules_cache[m_name]

    def _all_modules(self):
        for m_name in self._lazy_import:
            m = import_module(m_name)
            self._modules_cache[m_name] = m

        return self._modules_cache

    def shell(self, cmd, timeout=None):
        self._logger.debug(cmd)

        p = subprocess.Popen(cmd, shell=True)

        try:
            outs, errs = p.communicate()
        except Exception as e:
            p.kill()
            outs, errs = p.communicate()

        return p.returncode, outs, errs
