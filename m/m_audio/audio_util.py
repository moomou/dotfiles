import logging

import librosa

logger = logging.getLogger(__name__)


def open_wav(in_file):
    assert in_file.lower().endswith(
        '.wav'), 'Invalid filename:: must end in wav'

    # remixed to mono and sampled at 22kHz
    sig, freq = librosa.load(in_file)

    logger.debug('wav freq:: %s' % freq)
    logger.debug('wav sig:: %s, %s, %s, %s', sig, sig.shape,
                 sig.min(), sig.max())

    return sig, freq
