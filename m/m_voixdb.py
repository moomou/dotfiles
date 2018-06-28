import os
import io
import json

import requests

from m_base import Base
from util import m_path

SAMPLE_RATE = 16000


class Voixdb(Base):
    def __init__(self):
        super().__init__([
            'm_audio.ass',
            'm_audio.audio_util',
            'pydub',
            'librosa',
        ])

    def _process(
            self,
            dir,
            dataset_id,
            server,
            svc,
            duration=5,
            # TODO: not used yet
            random_offset_set=False):
        librosa = self._module('librosa')

        for f in os.listdir(dir):
            if f.endswith('mp3'):
                _, spkid, _, _, _ = f[:-4].split('~')
                data, _ = librosa.core.load(
                    os.path.join(dir, f),
                    sr=SAMPLE_RATE,
                    duration=duration,
                    mono=True)

                # skip '[' and ']'
                file = io.BytesIO(
                    json.dumps(data.tolist())[1:-1].encode('utf-8'))

                if svc == 'register':
                    url = server + '/%s/%s/%s' % (svc, dataset_id, spkid)
                elif svc == 'identify':
                    url = server + '/%s/%s' % (svc, dataset_id)
                else:
                    raise NotImplementedError

                result = requests.post(
                    url,
                    files={
                        'bin': file,
                    },
                    data={'meta': json.dumps({
                        'sr': SAMPLE_RATE,
                    })})

                print(svc, spkid, result.json())

    def identify(self,
                 dir,
                 duration=5,
                 dataset_id='0',
                 server='http://localhost:5000'):
        return self._process(
            dir, dataset_id, server, 'identify', duration=duration)

    def register(self,
                 dir,
                 duration=30,
                 dataset_id='0',
                 server='http://localhost:5000'):
        '''
        Given a data dir prepared by m_audio.gather_youtube_segments, register these
        voixdb instance.
        '''
        return self._process(
            dir, dataset_id, server, 'register', duration=duration)
