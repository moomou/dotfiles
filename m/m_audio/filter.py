import os

from m_base import Base


class AudioFilter(Base):
    _FRAME_LEN_MS = 0.03

    def __init__(self):
        super().__init__([
            'h5py', 'librosa', 'librosa.display', 'm_audio.audio_util',
            'matplotlib.pyplot', 'numpy', 'scipy.io.wavfile'
        ])

    def _write_wav_file(self, in_file, out_file, op, sr, filtered_sig):
        wavfile = self._module('scipy.io.wavfile')

        fname, _ = os.path.splitext(os.path.basename(in_file))
        dir_prefix = os.path.dirname(in_file)

        out_file = out_file or os.path.join(dir_prefix, fname + '_%s.wav' % op)
        wavfile.write(out_file, sr, filtered_sig)

    def _remove_silence_vad(self,
                            sr,
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

        frame_len = int(frame_duration * sr)  # this is per sec
        frame_shift_len = int(frame_shift * sr)  # this is per sec

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

        sr, signal = wavfile.read(in_file)
        filtered_sig = self._remove_silence_vad(sr, signal, frame_duration,
                                                frame_shift, threshold)

        self._write_wav_file(in_file, out_file, 'en_vad', sr, filtered_sig)

    def _exp_remove_center_vocal(self, signal):
        np = self._module('numpy')

        orig_dtype = signal.dtype
        # typeinfo = np.iinfo(orig_dtype)
        # is_unsigned = typeinfo.min >= 0

        # if is_unsigned:
        # signal = signal - (typeinfo.max + 1) / 2

        retsig = np.zeros(signal.shape)
        retsig[:, 0] = signal[:, 0] - signal[:, 1]
        retsig[:, 1] = signal[:, 0] - signal[:, 1]

        # if is_unsigned:
        # retsig = retsig + typeinfo.max / 2

        return retsig.astype(orig_dtype)

    def remove_vocal_exp2(self, in_file, in_file2):
        audio_util = self._module('m_audio.audio_util')
        librosa = self._module('librosa')
        np = self._module('numpy')

        sig, sr = audio_util.open_wav(in_file)
        sig_filter, sr = audio_util.open_wav(in_file2)

        S_full, phase = librosa.magphase(librosa.stft(sig))
        S_filter, phase = librosa.magphase(librosa.stft(sig_filter))

        S_filter = np.minimum(S_full, S_filter)

        mask_i = librosa.util.softmask(
            S_full, 2 * (S_full - S_filter), power=2)

        S_vocal = mask_i * S_full
        vocal = S_vocal * np.exp(1j * np.angle(phase))
        vocal_sig = librosa.istft(vocal)

        audio_util.write_wav(vocal_sig, sr, 'vocal.wav')

    def remove_vocal_exp(self,
                         in_file,
                         out_file=None,
                         frame_duration=None,
                         frame_shift=None):
        audio_util = self._module('m_audio.audio_util')
        librosa = self._module('librosa')
        np = self._module('numpy')
        wavfile = self._module('scipy.io.wavfile')

        sr, sig = wavfile.read(in_file)
        s_filter = self._exp_remove_center_vocal(sig)
        audio_util.write_wav(s_filter, sr, out_file or 'bg.wav')

        S_full, phase = librosa.magphase(librosa.stft(librosa.to_mono(sig)))
        S_filter, phase = librosa.magphase(
            librosa.stft(librosa.to_mono(s_filter)))

        S_filter = np.minimum(S_full, S_filter)

        mask_i = librosa.util.softmask(
            S_full, 2 * (S_full - S_filter), power=2)

        S_vocal = mask_i * S_full
        vocal = S_vocal * np.exp(1j * np.angle(phase))
        vocal_sig = librosa.istft(vocal)

        audio_util.write_wav(vocal_sig, sr, out_file or 'vocal2.wav')

    def repeat_sim(self, in_file):
        '''Uses https://librosa.github.io/librosa_gallery/auto_examples/plot_vocal_separation.html#sphx-glr-auto-examples-plot-vocal-separation-py
        to separate vocal from background
        '''
        audio_util = self._module('m_audio.audio_util')
        librosa = self._module('librosa')
        librosa_display = self._module('librosa.display')
        plt = self._module('matplotlib.pyplot')
        np = self._module('numpy')

        plt.ioff()

        sig, sr = audio_util.open_wav(in_file)
        S_full, phase = librosa.magphase(librosa.stft(sig))

        if self._debug_mode():
            idx = slice(*librosa.time_to_frames([0, 5], sr=sr))
            plt.figure(figsize=(12, 4))
            librosa_display.specshow(
                librosa.amplitude_to_db(S_full[:, idx], ref=np.max),
                y_axis='log',
                x_axis='time',
                sr=sr)
            plt.colorbar()
            plt.tight_layout()
            plt.savefig('input.png')

        S_filter = librosa.decompose.nn_filter(
            S_full,
            aggregate=np.median,
            metric='cosine',
            width=int(librosa.time_to_frames(2, sr=sr)))

        # The output of the filter shouldn't be greater than the input
        # if we assume signals are additive.  Taking the pointwise minimium
        # with the input spectrum forces this.
        S_filter = np.minimum(S_full, S_filter)

        # We can also use a margin to reduce bleed between the vocals and instrumentation masks.
        # Note: the margins need not be equal for foreground and background separation
        margin_i, margin_v = 2, 10
        power = 1

        mask_i = librosa.util.softmask(
            S_filter, margin_i * (S_full - S_filter), power=power)

        mask_v = librosa.util.softmask(
            S_full - S_filter, margin_v * S_filter, power=power)

        # Once we have the masks, simply multiply them with the input spectrum
        # to separate the components

        S_foreground = mask_v * S_full
        S_background = mask_i * S_full

        if self._debug_mode():
            # sphinx_gallery_thumbnail_number = 2
            plt.figure(figsize=(12, 8))
            plt.subplot(3, 1, 1)
            librosa.display.specshow(
                librosa.amplitude_to_db(S_full[:, idx], ref=np.max),
                y_axis='log',
                sr=sr)
            plt.title('Full spectrum')
            plt.colorbar()

            plt.subplot(3, 1, 2)
            librosa.display.specshow(
                librosa.amplitude_to_db(S_background[:, idx], ref=np.max),
                y_axis='log',
                sr=sr)
            plt.title('Background')
            plt.colorbar()
            plt.subplot(3, 1, 3)
            librosa.display.specshow(
                librosa.amplitude_to_db(S_foreground[:, idx], ref=np.max),
                y_axis='log',
                x_axis='time',
                sr=sr)
            plt.title('Foreground')
            plt.colorbar()
            plt.tight_layout()
            plt.savefig('full.png')

        self._logger.info('FORE:: %s', S_foreground)
        fore = S_foreground * np.exp(1j * np.angle(phase))
        self._logger.info('FORE:: %s', fore)
        back = S_background * np.exp(1j * np.angle(phase))

        fore_sig = librosa.istft(fore)
        self._logger.info('FORE_SIG:: %s', fore_sig)
        back_sig = librosa.istft(back)

        audio_util.write_wav(fore_sig, sr, './fore.wav')
        audio_util.write_wav(back_sig, sr, './back.wav')
