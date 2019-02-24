import os

from m_base import Base


class AudioMixer(Base):
    def __init__(self):
        super().__init__(
            [
                "python_speech_features",
                "scipy.io.wavfile",
                "pydub.AudioSegment",
                "h5py",
                "numpy",
            ]
        )

    def _scale_unsigned(self, *sigs):
        np = self._module("numpy")

        assert len(sigs), "At least 1 signal must be passed"

        sig1 = sigs[0]
        assert all(
            sigs, lambda sig: sig.shape == sig1.shape and sig.dtype == sig1.dtype
        ), "Shape must match"

        orig_dtype = sig1.dtype
        typeinfo = np.iinfo(orig_dtype)
        is_unsigned = typeinfo.min >= 0

        if is_unsigned:
            for idx, sig in enumerate(sigs):
                sigs[idx] = sigs[idx] - (typeinfo.max + 1) / 2

        return sigs

    def _mix_time(self, *sigs):
        np = self._module("numpy")

        sigs = self._scale_unsigned(sigs)

        sig1 = sigs[0]
        out_sig = sig1.astype(np.float32)
        for idx, other_sig in enumerate(sigs[1:]):
            out_sig = out_sig + other_sig.astype(np.float32)
            out_sig = out_sig / np.abs(out_sig).max()

        clipped = np.clip(out_sig, -1, 1)
        return clipped

    def _mix_freq(self, *sigs):
        np = self._module("numpy")

        sigs = self._scale_unsigned(sigs)

        hns = [np.fft.fft(sig, axis=0) for sig in sigs]

        out_hn = hns[0]
        for idx, hn in enumerate(hns):
            # TODO: double check this logic
            out_hn = np.fft.ifft(out_hn - hn)

        signal = np.real(out_hn)
        signal = signal / np.abs(signal).max()

        clipped = np.clip(signal, -1, 1)
        return clipped

    def mix_freq(self, *in_file):
        wavfile = self._module("scipy.io.wavfile")
        pass

    def mix_time(self, *in_file):
        wavfile = self._module("scipy.io.wavfile")

        pass
