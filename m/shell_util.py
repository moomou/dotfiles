import subprocess


def shell(self, cmd, timeout=None):
    p = subprocess.Popen(cmd, shell=True)

    try:
        outs, errs = p.communicate()
    except Exception as e:
        p.kill()
        outs, errs = p.communicate()

    return p.returncode, outs, errs
