import inspect
import logging.config
import os
import subprocess
from importlib import import_module

import coloredlogs

import shell_util
import simple_argparse as sa

FMT = "[%(asctime)s %(filename)s:%(lineno)d %(levelname)s] %(message)s"


class Base(object):
    def __init__(self, *, lazy_import=[], renames=None, shell_sudo=False):
        self._modules_cache = {}
        self._lazy_import = lazy_import
        self._renames = renames or {}

        self._logger = logger = logging.getLogger(type(self).__name__)
        self._logger.fatal = fatal_wrapper(logger.fatal)
        coloredlogs.install(level="INFO", fmt=FMT)

        self._shell_sudo = shell_sudo
        self._debugging = False
        if os.environ.get("DEBUG", None):
            self._debugging = True
            coloredlogs.install(level="DEBUG", fmt=FMT)
            self._logger.setLevel(logging.DEBUG)

    def _module(self, m_name):
        if m_name not in self._modules_cache:
            m_name = self._renames.get(m_name, m_name)
            self._logger.debug("Loading:: %s", m_name)

            assert m_name in self._lazy_import, "Import not declared:: `%s`" % m_name

            m = import_module(m_name)
            self._modules_cache[m_name] = m

        return self._modules_cache[m_name]

    def _all_modules(self):
        for m_name in self._lazy_import:
            self._module(m_name)

        return self._modules_cache

    def _debug_mode(self):
        return self._debugging

    def list_cmds(self):
        return inspect.getmembers(
            self,
            predicate=lambda x: inspect.ismethod(x) and not x.__name__.startswith("_"),
        )

    def print_cmds(self):
        sa.print_commands(
            [name for (name, _) in self.list_cmds()], top_lv=self.__class__.__name__
        )

    def info(self):
        self._logger.info(self.__class__)

    def shell(self, cmd, timeout=None, **kwargs):
        self._logger.debug(f"running shell `{cmd}`")

        if "sudo" not in kwargs:
            kwargs["sudo"] = self._shell_sudo

        return shell_util.shell(cmd, timeout=timeout,
                **kwargs)


def fatal_wrapper(fn):
    import sys

    def fatal(*args, **kwargs):
        fn(*args, **kwargs)
        sys.exit(1)

    return fatal
