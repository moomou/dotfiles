import logging
import subprocess
from subprocess import PIPE, STDOUT


def shell(cmd, timeout=None, throw=False, **kwargs):
    if "quiet" in kwargs:
        logging.warning("quiet flag is deprecated")

    p = subprocess.Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
    try:
        outs, errs = p.communicate()
    except Exception as e:
        p.kill()
        outs, errs = p.communicate()
        if throw:
            raise e

    return p.returncode, outs, errs
