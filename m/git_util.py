from shell_util import shell


def groot():
    _, out, _ = shell("groot")
    return out
