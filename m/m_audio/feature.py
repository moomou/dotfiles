import os

from m_base import Base


class AudioFeature(Base):
    def __init__(self):
        super().__init__([
            'librosa',
            'h5py',
            'numpy',
            'm_audio.audio_util',
        ])

    def _split_frames(self, sig, sr, frame_size=100):
        audio_util = self._module('m_audio.audio_util')
        librosa = self._module('librosa')

        frame_len = audio_util.frame_size_in_ms(sr, 200)
        hop_len = frame_len // 2
        frames = librosa.util.frame(sig, frame_len, hop_len)
        frames = librosa.util.normalize(frames)

        self._logger.debug('Frame:: %s', frames.shape)
        return frames

    def _save_frames(self, h5, row_id, frames):
        for i in range(frames.shape[1]):
            fr = frames[:, i]
            frame_id = row_id + 'f%d' % i
            self._logger.debug('%s :: %s, %s', frame_id, fr.shape, fr)
            h5.create_dataset(frame_id, data=fr, dtype='float32')

    def extract_raw(self, in_file, h5_id=None, out_h5=None, prefix='raw'):
        '''Given `in_file` (must be wav), write raw feature into `out_h5`'''
        h5py = self._module('h5py')
        audio_util = self._module('m_audio.audio_util')

        sig, sr = audio_util.open_wav(in_file)

        basename, _ = os.path.splitext(os.path.basename(in_file))
        row_id = h5_id + '.' + basename

        if out_h5:

            with h5py.File(out_h5, mode='a') as h5:
                raw_grp = h5.get(prefix) or h5.create_group(prefix)

                frames = self._split_frames(sig, sr)
                self._save_frames(raw_grp, row_id, frames)
        else:
            self._logger.info('id:: %s', row_id)

    def extract_mfcc(self,
                     in_file,
                     h5_id=None,
                     out_h5=None,
                     prefix='mfcc_13',
                     sr=None,
                     max_freq=8000):
        '''Given `in_file` (must be wav), write mfcc feature into `out_h5`'''

        librosa = self._module('librosa')
        h5py = self._module('h5py')
        audio_util = self._module('m_audio.audio_util')

        extra_args = {}
        if sr:
            extra_args['sr'] = sr

        sig, sr = audio_util.open_wav(in_file, **extra_args)
        mfcc_feature = librosa.feature.mfcc(sig, sr, n_mfcc=13, fmax=max_freq)
        self._logger.debug('Mfcc:: %s, %s', mfcc_feature.shape, mfcc_feature)
        basename, _ = os.path.splitext(os.path.basename(in_file))
        row_id = (h5_id or '') + '.' + basename

        if out_h5:
            with h5py.File(out_h5, mode='a') as h5:
                mfcc_grp = h5.get(prefix) or h5.create_group(prefix)
                mfcc_grp.create_dataset(
                    row_id, data=mfcc_feature, dtype='float32')
        else:
            self._logger.info('sig:: %s, %s' % (sig, sig.shape))
            self._logger.info('mfcc:: %s, %s' % (mfcc_feature,
                                                 mfcc_feature.shape))
            self._logger.info('id:: %s', row_id)
