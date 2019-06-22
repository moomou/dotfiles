import subprocess


def shell(cmd, timeout=None, throw=False, quiet=True):
    stdout = None if not quiet else subprocess.DEVNULL
    p = subprocess.Popen(cmd, shell=True, stdout=stdout)

    try:
        outs, errs = p.communicate()
    except Exception as e:
        p.kill()
        outs, errs = p.communicate()
        if throw:
            raise e

    return p.returncode, outs, errs
