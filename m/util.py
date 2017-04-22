import os

def path(folder):
    return os.path.join(constant.ROOT, folder)

def get_config_yml():
    if os.path.isfile('./config.yml'):
        with open('./config.yml') as f:
            config_yml = yaml.safe_load(f)
            return config_yml
    return {}
