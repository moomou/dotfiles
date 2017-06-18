import os

from m_base import Base


class AudioFilter(Base):
    _FRAME_LEN_MS = 0.03

    def __init__(self):
        super().__init__([
            'python_speech_features',
            'scipy.io.wavfile',
            'h5py',
            'numpy',
        ])

    def _write_wav_file(self, in_file, out_file, op, freq, filtered_sig):
        wavfile = self._module('scipy.io.wavfile')

        fname, _ = os.path.splitext(os.path.basename(in_file))
        dir_prefix = os.path.dirname(in_file)

        out_file = out_file or os.path.join(dir_prefix, fname + '_%s.wav' % op)
        wavfile.write(out_file, freq, filtered_sig)

    def _remove_silence_vad(self,
                            freq,
                            signal,
                            frame_duration=None,
                            frame_shift=None,
                            threshold=0.25):
        '''
        This operates in time domain
        Calculates the average energy of the signal.
        Then calculates a window of the signal and if the energy is lower
        than threshold, make it zero.
        '''
        np = self._module('numpy')

        frame_duration = frame_duration or AudioFilter._FRAME_LEN_MS
        frame_shift = frame_shift or frame_duration / 2

        frame_len = int(frame_duration * freq)  # this is per sec
        frame_shift_len = int(frame_shift * freq)  # this is per sec

        orig_dtype = signal.dtype
        typeinfo = np.iinfo(orig_dtype)
        is_unsigned = typeinfo.min >= 0

        signal = signal.astype(np.int64)

        if is_unsigned:
            signal = signal - (typeinfo.max + 1) / 2

        # calculate energy
        avg_energy = np.sum(signal**2) / float(len(signal))
        self._logger.info('Avg energy::', avg_energy)
        self._logger.info('Frame len::', frame_len)
        self._logger.info('Frame shift len::', frame_shift_len)

        i = 0
        retsig_len = 0
        retsig = np.zeros(signal.shape, dtype=np.int64)

        while i < len(signal):
            part = signal[i:i + frame_len]
            part_energy = np.sum(part**2) / float(len(part))

            if part_energy < avg_energy * threshold:
                i += frame_len
            else:
                part_len = min(len(part), frame_shift_len)
                retsig[retsig_len:retsig_len + part_len] = part[:part_len]
                retsig_len += part_len
                i += frame_shift_len

        retsig = retsig[:retsig_len]

        if is_unsigned:
            retsig = retsig + typeinfo.max / 2

        return retsig.astype(orig_dtype)

    def remove_silence_vad(self,
                           in_file,
                           out_file=None,
                           frame_duration=None,
                           frame_shift=None,
                           threshold=0.25):
        '''
        Rewrite `in_file` to remove silence based on average energy threshold
        '''
        wavfile = self._module('scipy.io.wavfile')

        freq, signal = wavfile.read(in_file)
        filtered_sig = self._remove_silence_vad(freq, signal, frame_duration,
                                                frame_shift, threshold)

        self._write_wav_file(in_file, out_file, 'en_vad', freq, filtered_sig)

    def _exp_remove_center_vocal(self, sampling_freq, signal):
        np = self._module('numpy')

        orig_dtype = signal.dtype
        typeinfo = np.iinfo(orig_dtype)
        is_unsigned = typeinfo.min >= 0

        if is_unsigned:
            signal = signal - (typeinfo.max + 1) / 2

        retsig = np.zeros(signal.shape)
        retsig[:, 0] = signal[:, 0] - signal[:, 1]
        retsig[:, 1] = signal[:, 0] - signal[:, 1]

        if is_unsigned:
            retsig = retsig + typeinfo.max / 2

        return retsig.astype(orig_dtype)

    def remove_vocal_exp(self,
                         in_file,
                         out_file=None,
                         frame_duration=None,
                         frame_shift=None):
        wavfile = self._module('scipy.io.wavfile')

        freq, signal = wavfile.read(in_file)
        filtered_sig = self._exp_remove_center_vocal(freq, signal)

        self._write_wav_file(in_file, out_file, 'rm_vocal', freq, filtered_sig)
