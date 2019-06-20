import subprocess

import tqdm
import deco

from m_pipe.pipe_worker import PipeWorker


def shell(cmd):
    p = subprocess.Popen(cmd, shell=True)

    try:
        outs, errs = p.communicate()
    except Exception:
        p.kill()
        outs, errs = p.communicate()

    return p.returncode, outs, errs


@deco.concurrent
def process(cmds):
    for cmd in cmds:
        shell(cmd)


@deco.synchronized
def parallel(tasks):
    for cmds in tqdm.tqdm(tasks):
        process(cmds)


class Worker(PipeWorker):
    def __init__(self):
        self.name = "yt_pipe"

    def pp(self, filename):
        """Loads json file in format [
            [youtube_id, start, end],
            [youtube_id, start, end],
            [youtube_id, start, end],
            ...
        ] and downloads the youtube segment
        """
        json_util = self._module("json_util")
        fs_util = self._module("fs_util")
        au = self._module("audio_util")

        data_dir = fs_util.mkdir_data(self.name)
        ytids = json_util.load(filename)

        tasks = []
        for ytid, start, end in ytids:
            cmd, fname = au.ytid_dl_cmd(ytid)

            seg_fname = "seg_%s.mp3" % ytid
            ffmpeg_exp = au.file_cut_ffmpeg_exp(
                fname, start, float(end) - float(start), seg_fname
            )
            tasks.append(
                [cmd, ffmpeg_exp, "mv -- %s %s/%s" % (seg_fname, data_dir, seg_fname)]
            )

        parallel(tasks)
