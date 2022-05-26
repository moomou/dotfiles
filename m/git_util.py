from asyncio import subprocess

from shell_util import shell


def groot():
    # TODO: should be implemented without relying on shell alias
    _, out, _ = shell("groot")
    return out


def stash():
    shell("git stash")


def stash_pop():
    shell("git stash pop")


def rebase(branch="master"):
    shell("git pull --rebase origin %s" % branch)


def log(args):
    return shell("git log %s" % args, stdout=subprocess.PIPE)
