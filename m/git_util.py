from shell_util import shell


def groot():
    _, out, _ = shell("groot")
    return out


def stash():
    shell("git stash")


def stash_pop():
    shell("git stash pop")


def rebase():
    shell("rebase")
