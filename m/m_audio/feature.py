import os

from m_base import Base


class AudioFeature(Base):
    def __init__(self):
        super().__init__([
            'python_speech_features',
            'scipy.io.wavfile',
            'h5py',
            'numpy',
        ])

    def extract_features_mfcc(self, in_file, out_h5, freq=48e3):
        '''Given `in_file` (must be wav), write mfcc feature into `out_h5`'''
        assert in_file.endswith('.wav'), 'Invalid filename:: must end in wav'

        psf = self._module('python_speech_features')
        wavfile = self._module('scipy.io.wavfile')
        h5py = self._module('h5py')

        freq, sig = wavfile.read(in_file)
        mfcc_feature = psf.mfcc(sig, freq)

        with h5py.File(out_h5, mode='a') as h5:
            mfcc_grp = h5.get('mfcc') or h5.create_group('mfcc')

            dataset_name, _ = os.path.splitext(os.path.basename(in_file))
            mfcc_grp.create_dataset(dataset_name, mfcc_feature, dtype='i')

            h5.close()
