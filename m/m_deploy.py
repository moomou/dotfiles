import subprocess
import os

from m_base import Base

from util import m_path

class Deploy(Base):
    def slothapp(self, app):
        cmd = 'cd %s && ./deploy_asset.sh' % m_path('dotfiles/m/ops/%s' % app)
        self.shell(cmd)

        cmd = 'cd %s && ./deploy.sh %s' % (m_path('dotfiles/m/ops'), app)
        self.shell(cmd)
