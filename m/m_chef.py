import os

from m_base import Base
from util import m_path


class Chef(Base):
    def _setup(self):
        # cp chef folder to ~/.chef
        chef_run_dir = os.path.expanduser("~/.chef")

        if not os.path.exists(chef_run_dir):
            os.mkdir(chef_run_dir)

        # copy over chef
        self._logger.debug("m_path chef at [%s]", m_path("dotfiles/chef"))
        self.shell("cp -r {}/* {}".format(m_path("dotfiles/chef"), chef_run_dir))

        return chef_run_dir

    def role(self, role):
        chef_run_dir = self._setup()

        self._logger.info(chef_run_dir)
        # run bash install.sh' "$role"
        self.shell("cd %s && sudo ./run_chef_role.sh %s" % (chef_run_dir, role))
