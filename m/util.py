import os

import ruamel.yaml as yaml

import constant


def m_path(folder, root=constant.ROOT):
    return os.path.join(root, folder)


def get_config_yml():
    if os.path.isfile('./config.yml'):
        with open('./config.yml') as f:
            config_yml = yaml.safe_load(f)
            return config_yml
    return {}


def run_once(fn):
    ran = False

    def wrapper(*args, **kwargs):
        global ran
        if not ran:
            fn(*args, **kwargs)
        result = fn(*args, **kwargs)
        ran = True
        return result

    return wrapper


def setup(fn):
    def wrapper(self, *args, **kwargs):
        self.setup()
        return fn(self, *args, **kwargs)

    return wrapper
