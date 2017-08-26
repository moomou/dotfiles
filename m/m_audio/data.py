import csv
import os
from collections import defaultdict

from tqdm import tqdm

from m_base import Base

YOUTUBE_PREFIX = 'https://www.youtube.com/watch?v=%s'
YOUTUBE_DL_CMD = 'youtube-dl -x --audio-format mp3 -o "%(id)s.%(ext)s" '


class AudioData(Base):
    def __init__(self):
        super().__init__([
            'm_audio.ass',
            'm_audio.audio_util',
            'librosa',
        ])

    def about(self, in_file):
        '''Uses ffmpeg to read file'''
        self.shell('ffmpeg -i %s' % in_file)

    def sph_2_riff_wav(self, in_file, out_file=None):
        '''Uses sox program to convert sph (aka NIST) to RIFF wav'''
        out_file = out_file if out_file is not None else in_file + '.riff.wav'
        self.shell('sox -t sph %s -b 16 -t wav %s' % (in_file, out_file))

    def extract_audio_line(self, in_file, out_file, start, end):
        '''Extract audio from `start` to `end` as wave'''
        cmd = '''ffmpeg -i %s -ss %s -t %s -f wav %s''' % (in_file, start,
                                                           end - start,
                                                           out_file)

        self.shell(cmd)

    def extract_audio_from_subtitle(self, output_folder, subtitle_file,
                                    audio_file):
        '''
        Converts a folder of videos and extract wav audio files
        using ffmpeg tool
        '''
        ass = self._modules['m_audio.ass']

        if not os.path.isdir(output_folder):
            os.mkdir(output_folder)

        basename = os.path.basename(audio_file)

        csv_fname = os.path.join(output_folder, '%s_details.csv' % basename)
        with open(csv_fname, 'wb') as csvfile:
            writer = csv.DictWriter(
                csvfile, fieldnames=['filename', 'line', 'speaker'])

            writer.writeheader()

            with open(subtitle_file) as sub:
                doc = ass.parse(sub)

                for idx, evt in enumerate(doc.events):
                    if not evt.fields['Style'].endswith('JP'):
                        continue

                    out_file = os.path.join(output_folder,
                                            basename + '_%d.wav' % idx)

                    self.extract_audio_line(audio_file, out_file, evt.start,
                                            evt.end)

                    writer.writerow({
                        'filename': out_file,
                        'line': evt.fields['Text'],
                        'speaker': '',
                    })

    def gather_youtube_clean(self, fname):
        au = self._module('m_audio.audio_util')

        data = au.parse_clean_txt(fname)

        try:
            os.mkdir('data')
        except:
            pass

        for row in tqdm(data):
            _ids = row.split(',')
            prefix = au.speaker_fname(_ids[0], 0)
            counter = 0

            for _id in _ids:
                url = YOUTUBE_PREFIX % _id
                self.shell(YOUTUBE_DL_CMD + url)
                self.shell('mv -- %s.mp3 ./data/%s_%d.mp3' % (_id, prefix,
                                                              counter))
                counter += 1

    def gather_youtube_info(self, fname):
        au = self._module('m_audio.audio_util')

        try:
            os.mkdir('data')
        except:
            pass

        data = au.parse_info_txt(fname)
        counter_dict = defaultdict(lambda: 0)
        for row in tqdm(data):
            url = YOUTUBE_PREFIX % row['file']
            fname = '%s.mp3' % row['file']

            speaker_prefix = au.speaker_fname(row['file'], row['id'])
            speaker_file = '%s_%d.mp3' % (speaker_prefix,
                                          counter_dict[speaker_prefix])
            counter_dict[speaker_prefix] += 1

            if not os.path.isfile(fname):
                # download file if not already there
                self.shell(YOUTUBE_DL_CMD + url)

            start_time, end_time, delta = au.parse_time(
                row['start_m_sec'], row['end_m_sec'])

            ffmpeg_exp = au.file_cut_ffmpeg_exp(fname,
                                                start_time.strftime('%M:%S'),
                                                delta.total_seconds(),
                                                speaker_file)

            self.shell(ffmpeg_exp)
            self.shell('mv -- %s ./data/%s' % (speaker_file, speaker_file))

    def resample_audio(self, input_wav, output_wav, sr=8000, duration=10):
        librosa = self._module('librosa')

        wav, sr = librosa.core.load(input_wav, sr=sr, duration=duration)
        librosa.output.write_wav(output_wav, wav, sr)
