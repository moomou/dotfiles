import csv
import os

from m_base import Base


class AudioData(Base):
    def __init__(self):
        super().__init__([
            'm_audio.ass',
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
