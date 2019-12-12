import os

from m_base import Base
from util import m_path


class Watcher(Base):
    def run(self, directory, script, exclude=None, include="*"):
        raise NotImplementedError
