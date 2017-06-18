from constant import M_ROOT

from m_base import Base

from util import (
    m_path,
    setup,
)


class Keras(Base):
    @setup
    def encode_h5(self, fname):
        '''Convert keras h5 file for kerasjs use'''
        self.shell('%s/encoder.py %s' % (
            m_path('third_party', root=M_ROOT),
            fname
        ))
