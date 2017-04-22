import argparse
import logging
import logging.config
import os
import os
import shutil
import subprocess
import ruamel.yaml as yaml

from m_base import Base

class Chef(Base):
    def reheat(self, role):
        # cp chef folder to ~/.chef
        chef_run_dir = os.path.expanduser('~/.chef')

        if not os.path.exists(chef_run_dir):
            os.mkdir(chef_run_dir)

        # copy over chef
        print(path('dotfiles/chef'), chef_run_dir)

        self.shell('cp -r %s/* %s' % (path('dotfiles/chef'), chef_run_dir))
        # run bash install.sh' "$role"
        self.shell('cd %s && sudo bash install.sh %s' % (chef_run_dir, role))
