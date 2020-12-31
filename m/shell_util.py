import logging
import subprocess
import sys
from subprocess import PIPE, STDOUT


def exec(cmd, **kwargs):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=PIPE)
    for c in iter(lambda: p.stdout.read(1), b""):  
        sys.stdout.write(c.decode("utf-8"))


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
