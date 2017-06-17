import os

import ruamel.yaml as yaml

import constant


def memoize(fn):
    _cache = None

    def _cached(*args, **kwargs):
        nonlocal _cache
        if _cache is not None:
            return _cache
        _cache = fn(*args, **kwargs)
        return _cache

    return _cached


def m_path(folder, root=constant.ROOT):
    return os.path.join(root, folder)


def read_yml(path):
    with open(path) as f:
        config_yml = yaml.safe_load(f)
        return config_yml


def get_config_yml():
    if os.path.isfile('./config.yml'):
        return read_yml('./config.yml')
    return {}


def run_once(fn):
    ran = [False]

    def wrapper(*args, **kwargs):
        if not ran[0]:
            fn(*args, **kwargs)
        result = fn(*args, **kwargs)
        ran[0] = True
        return result

    return wrapper


def setup(fn):
    def wrapper(self, *args, **kwargs):
        self.setup()
        return fn(self, *args, **kwargs)

    return wrapper


@memoize
def get_gh_token():
    with open(os.path.join(constant.DOTFILES)) as f:
        return f.read()
