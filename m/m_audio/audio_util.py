import logging

import librosa

logger = logging.getLogger(__name__)


def open_wav(in_file, **kwargs):
    assert in_file.lower().endswith(
        '.wav'), 'Invalid filename:: must end in wav'

    sig, freq = librosa.load(in_file, **kwargs)

    logger.debug('wav freq:: %s' % freq)
    logger.debug('wav sig:: %s, %s, %s, %s', sig, sig.shape,
                 sig.min(), sig.max())

    return sig, freq


def write_wav(sig, freq, path, norm=True):
    logger.debug('wav sig:: %s, %s, %s, %s, %s', sig, freq, sig.shape,
                 sig.min(), sig.max())
    logger.debug('Writing wav to:: %s', path)

    librosa.output.write_wav(path, sig, freq, norm=norm)


def frame_size_in_ms(sr, ms):
    return int((sr / 1000) * ms)
