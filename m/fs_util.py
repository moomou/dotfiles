import os


def mkdir(dirname, exist_ok=True):
    os.makedirs(dirname, exist_ok=True)
    return dirname


def mkdir_data(dirname, **kwargs):
    data_dir = os.path.join(dirname, "data")
    return mkdir(data_dir, **kwargs)


class Cwd:
    def __init__(self, dst_dir):
        self.dst_dir = dst_dir

    def __enter__(self):
        self.prev_dir = os.getcwd()
        os.chdir(self.dst_dir)

    def __exit__(self, exc_type, exc_val, exc_tb):
        os.chdir(self.prev_dir)
