#!/usr/bin/env python
# -*- coding: utf-8 -*-

import wave
import numpy as np
import sys
import scipy as sp
import scipy.io.wavfile as wavfile

from pyssp_ltsd import (LTSD, AdaptiveLTSD, get_frame, read_signal)

WINSIZE=8192
MAGIC_NUMBER = 0.04644

def mononize_signal(signal):
    if signal.ndim > 1:
        signal = signal[:,0]
    return signal

class LTSD_VAD:
    ltsd = None
    order = 5

    fs = 0
    window_size = 0
    window = 0

    lambda0 = 0
    lambda1 = 0

    bg_signal = None

    def __init__(self, fs, signal, bg_signal=None, adaptive=False):
        self.signal = signal
        self.adaptive = adaptive

        self._init_window(fs)

        if bg_signal is not None:
            self._init_params_by_noise(fs, bg_signal)

    def _init_params_by_noise(self, fs, bg_signal):
        bg_signal = mononize_signal(bg_signal)
        self.bg_signal = np.array(bg_signal)

        ltsd = LTSD(self.window_size, self.window, self.order)
        res, ltsds = ltsd.compute_with_noise(bg_signal, bg_signal)

        max_ltsd = max(ltsds)

        self.lambda0 = max_ltsd * 1.1
        self.lambda1 = self.lambda0 * 2.0

        print('max_ltsd =', max_ltsd)
        print('lambda0 =', self.lambda0)
        print('lambda1 =', self.lambda1)

    def _init_window(self, sampling_freq):
        self.fs = sampling_freq
        self.window_size = WINSIZE
        self.window = np.hanning(self.window_size)

    def _get_ltsd(self, sampling_freq=None):
        if sampling_freq is not None and sampling_freq != self.fs:
            self._init_window(fs)

        if self.adaptive:
            return AdaptiveLTSD(self.window_size, self.window, self.order,
                lambda0=self.lambda0, lambda1=self.lambda1)

        return LTSD(self.window_size, self.window, self.order,
                lambda0=self.lambda0, lambda1=self.lambda1)

    def filter(self, signal, bg_signal=None):
        signal = mononize_signal(signal)

        if bg_signal:
            res, ltsds = self._get_ltsd().compute_with_noise(signal, bg_signal)
        else:
            print(self.fs/float(WINSIZE)/3.0)
            noise_frame_size = WINSIZE*int(self.fs/float(WINSIZE)/3.0)
            print('Noise Frame Size::', noise_frame_size)
            res, ltsds = self._get_ltsd().compute_without_noise(signal, noise_frame_size)

        voice_signals = []
        res = [(start * self.window_size / 2, (finish + 1) * self.window_size / 2) for start, finish in res]

        print(res, len(ltsds) * self.window_size / 2)
        for start, finish in res:
            voice_signals.append(signal[start:finish])
        try:
            return np.concatenate(voice_signals), res
        except:
            return np.array([]), []

if __name__ == '__main__':
    fpath = sys.argv[1]

    if len(sys.argv) >= 3:
        bg_fpath = sys.argv[2]
    else:
        bg_fpath = None

    if bg_fpath:
        bg_freq, bg_signal = wavfile.read(bg_fpath)
    else:
        bg_signal = None

    freq, signal = wavfile.read(fpath)

    if bg_fpath:
        assert bg_freq == freq, 'bg fs != fs'

    lstd_vad = LTSD_VAD(freq, signal, bg_signal, adaptive=True)
    vaded_signal, params = lstd_vad.filter(signal)
    print(vaded_signal)

    wavfile.write('vaded.wav', freq, vaded_signal)
