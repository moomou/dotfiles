import subprocess


def shell(cmd, timeout=None, throw=False):
    p = subprocess.Popen(cmd, shell=True)

    try:
        outs, errs = p.communicate()
    except Exception as e:
        p.kill()
        outs, errs = p.communicate()
        if throw:
            raise e

    return p.returncode, outs, errs
