import os

PIPE_DATA_DIR = os.expanduser("~/dev/data/pipe")

os.makedirs(PIPE_DATA_DIR, exist_ok=True)


class PipeWorker:
    """
    Base class for pipe worker, responsible for
    setting up data directory

    TODO
        * connecting pipelines

    """

    def __init__(self, name):
        self.data_dir = os.path.join(PIPE_DATA_DIR, name)
        os.makedirs(self.data_dir, exist_ok=True)
