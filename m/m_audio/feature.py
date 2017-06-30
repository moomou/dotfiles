import os

from m_base import Base


class AudioFeature(Base):
    def __init__(self):
        super().__init__([
            'librosa',
            'h5py',
            'numpy',
            'audio_util',
        ])

    def extract_raw(self, in_file, h5_id=None, out_h5=None, prefix='raw'):
        '''Given `in_file` (must be wav), write raw feature into `out_h5`'''
        h5py = self._module('h5py')
        audio_util = self._module('audio_util')

        sig, freq = audio_util.open_wav(in_file)
        basename, _ = os.path.splitext(os.path.basename(in_file))
        row_id = h5_id + '.' + basename

        if out_h5:
            with h5py.File(out_h5, mode='a') as h5:
                raw_grp = h5.get(prefix) or h5.create_group(prefix)
                raw_grp.create_dataset(row_id, sig, dtype='float32')
        else:
            self._logger.info('id:: %s', row_id)

    def extract_mfcc(self, in_file, h5_id=None, out_h5=None, prefix='mfcc_20'):
        '''Given `in_file` (must be wav), write mfcc feature into `out_h5`'''

        librosa = self._module('librosa')
        h5py = self._module('h5py')
        audio_util = self._module('audio_util')

        sig, freq = audio_util.open_wav(in_file)
        mfcc_feature = librosa.feature.mfcc(sig, freq, n_mfcc=20)
        basename, _ = os.path.splitext(os.path.basename(in_file))
        row_id = h5_id + '.' + basename

        if out_h5:
            with h5py.File(out_h5, mode='a') as h5:
                mfcc_grp = h5.get(prefix) or h5.create_group(prefix)
                mfcc_grp.create_dataset(row_id, mfcc_feature, dtype='float32')
        else:
            self._logger.info('sig:: %s, %s' % (sig, sig.shape))
            self._logger.info('mfcc:: %s, %s' % (mfcc_feature,
                                                 mfcc_feature.shape))
            self._logger.info('id:: %s', row_id)
