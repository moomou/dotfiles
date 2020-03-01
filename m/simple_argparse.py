import logging.config

from constant import TAB

logger = logging.getLogger()


def parse(args):
    pos = []
    named = {}
    key = None

    for arg in args:
        if arg.startswith("--"):
            if key:
                named[key] = True
            key = arg[2:]
        elif key:
            named[key] = arg
            key = None
        else:
            pos.append(arg)
    if key:
        named[key] = True

    return pos, named


def print_commands(options, top_lv="M"):
    logger.debug(options)

    cmds = f"\n{TAB}".join(sorted(options))
    header = f"\nCommands under [{top_lv}]"
    print(f"{header}: \n\n{TAB}{cmds}\n")
