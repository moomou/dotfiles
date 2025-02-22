import logging
import subprocess
import sys
from subprocess import PIPE, STDOUT


def shell(cmd,
    timeout=None,
    throw=False,
    *,
    stdout=sys.stdout,
    stderr=sys.stderr,
    **kwargs
):
    if "quiet" in kwargs:
        logging.warning("quiet flag is deprecated")

    if kwargs.get("sudo", False):
        if not cmd.startswith("sudo"):
            cmd = "sudo " + cmd

    p = subprocess.Popen(
        cmd, shell=True, stdout=stdout, stderr=stdout,
    )
    try:
        outs, errs = p.communicate()
    except Exception as e:
        p.kill()
        outs, errs = p.communicate()
        if throw:
            raise e

    return p.returncode, outs, errs
