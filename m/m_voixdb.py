import requests

from m_base import Base
from util import m_path


class Voixdb(Base):
    def register(self, input_file, dataset_id='0', server='localhost:5000'):
        '''Takes a new line delimited txt file to register against a voixdb instance

        file format
        # spkid, voice file (mp3 or wav), extract location in ffmpeg format
        '''
        pass