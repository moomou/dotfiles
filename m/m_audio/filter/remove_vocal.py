#!/usr/bin/env python

import sys
import scipy.io.wavfile as wavfile
import numpy as np

FRAME_LEN_MS = 0.02


def remove_center_vocal(
    sampling_freq,
    signal,
    frame_duration=FRAME_LEN_MS,  # 32 ms as 1 frame length
    frame_shift=FRAME_LEN_MS / 2,
    threshold=0.15,
):
    frame_len = int(frame_duration * sampling_freq)  # this is per sec
    frame_shift_len = int(frame_shift * sampling_freq)  # this is per sec

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


def task(fpath):
    freq, signal = wavfile.read(fpath)
    signal_out = remove_center_vocal(freq, signal)
    wavfile.write("vocal_center_" + fpath, freq, signal_out)
    return fpath


def main():
    task(sys.argv[1])  # , sys.argv[2])


if __name__ == "__main__":
    main()

# vim: foldmethod=marker
