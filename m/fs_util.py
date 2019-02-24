import os


def mkdir(dirname, exist_ok=True):
    os.makedirs(dirname, exist_ok=True)
    return dirname


def mkdir_data(dirname, **kwargs):
    data_dir = os.path.join(dirname, "data")
    return mkdir(data_dir, **kwargs)
