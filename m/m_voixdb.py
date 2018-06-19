import requests

from m_base import Base
from util import m_path


class Voixdb(Base):
    def register(self, input_file, dataset_id='0', server='localhost:5000'):
        '''
        Given a data dir prepared by m_audio.gather_youtube_segments, register these
        voixdb instance.
        '''
        pass