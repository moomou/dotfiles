import csv
import logging
import os
from datetime import datetime, timedelta

import librosa

logger = logging.getLogger(__name__)

YOUTUBE_PREFIX = "https://www.youtube.com/watch?v=%s"
YOUTUBE_DL_CMD = 'youtube-dl -x --audio-format mp3 -o "%(id)s.%(ext)s" '


def open_wav(in_file, **kwargs):
    assert in_file.lower().endswith(".wav"), "Invalid filename:: must end in wav"

    sig, freq = librosa.load(in_file, **kwargs)

    logger.debug("wav freq:: %s" % freq)
    logger.debug("wav sig:: %s, %s, %s, %s", sig, sig.shape, sig.min(), sig.max())

    return sig, freq


def write_wav(sig, freq, path, norm=True):
    logger.debug(
        "wav sig:: %s, %s, %s, %s, %s", sig, freq, sig.shape, sig.min(), sig.max()
    )
    logger.debug("Writing wav to:: %s", path)

    librosa.output.write_wav(path, sig, freq, norm=norm)


def frame_size_in_ms(sr, ms):
    return int((sr / 1000) * ms)


def parse_info_txt(fname):
    with open(fname) as csvfile:
        reader = csv.DictReader(csvfile)
        rows = [row for row in reader]
        return rows


def parse_clean_txt(fname):
    with open(fname) as f:
        _ids = f.read().split("\n")
        _ids = [_id.strip() for _id in _ids if _id]
        return _ids


def _parse_time(time_str):
    colon_count = time_str.count(":")

    if colon_count == 1:
        t = datetime.strptime(time_str, "%M:%S")
    else:
        t = datetime.strptime(time_str, "%S")

    return t


def parse_time(start_time_str, end_time_str):
    start_time = _parse_time(start_time_str)
    end_time = _parse_time(end_time_str)

    assert end_time > start_time, "Sanity check"

    delta = end_time - start_time
    return (start_time, end_time, delta)


def speaker_fname(fprefix, speaker_id):
    """
        `fprefix` + `speaker_id` makese a unique user and `counter` is
        used to different different files
    """
    return "%s~%s" % (fprefix, speaker_id)


def file_cut_ffmpeg_exp(input_f, start, duration, output_f):
    return """
        ffmpeg -ss %s -i '%s' -t %s -ac 1 -c copy -y %s
    """ % (
        start,
        input_f,
        duration,
        output_f,
    )


def file_split_ffmpeg_exp(input_f, seg_len, output_exp):
    return """
        ffmpeg -i '%s' -f segment -segment_time %s -c copy %s
    """ % (
        input_f,
        seg_len,
        output_exp,
    )


def ytid_dl_cmd(ytid):
    url = YOUTUBE_PREFIX % ytid
    fname = "%s.mp3" % ytid

    if not os.path.isfile(fname) or os.stat(fname).st_size == 0:
        # download file if not already there
        return (YOUTUBE_DL_CMD + url, fname)

    return ("echo %s exists" % fname, fname)
