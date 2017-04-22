import subprocess
import os

from m_base import Base
from util import path

class Deploy(Base):
    def slothapp(self, app):
        cmd = 'cd %s && ./deploy_asset.sh' % path('dotfiles/m/ops/%s' % app)
        self.shell(cmd)

        cmd = 'cd %s && ./deploy.sh %s' % (path('dotfiles/m/ops'), app)
        self.shell(cmd)
