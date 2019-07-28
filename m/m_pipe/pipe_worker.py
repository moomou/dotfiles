import logging
import multiprocessing
import os
import pathlib
import threading

from m_base import Base
from fs_util import safe_move

FINAL = "__FINAL__"


class Committer(threading.Thread):
    def __init__(self, queue, commit_dir):
        super().__init__()

        self.queue = queue
        self.commit_dir = commit_dir

        self.log_path = os.path.join(commit_dir, "log")
        self.compact_log_path = os.path.join(commit_dir, "compact_log")

        self._completed, self._failed = self._parse_log(compact=True)

        pathlib.Path(self.log_path).touch()
        self.log = open(self.log_path, mode="ab")

    @property
    def completed(self):
        return self._completed

    def _parse_log(self, compact=False):
        completed = set()
        failed = set()

        if not os.path.exists(self.log_path):
            return completed, failed

        with open(self.log_path) as f:
            for line in f:
                task_id, status = line.split("~~")
                if status.strip() != "0":
                    failed.add(task_id)
                else:
                    completed.add(task_id)

        if not compact:
            return completed, failed

        with open(self.compact_log_path, "w") as f:
            for task_id in completed:
                f.write("%s~~0\n" % task_id)
            for task_id in failed:
                f.write("%s~~1\n" % task_id)

        safe_move(self.compact_log_path, self.log_path)
        return completed, failed

    def _encode(self, task_id, status):
        line = "%s~~%s\n" % (task_id, status)
        return line.encode("utf-8")

    def run(self):
        counter = 0
        while True:
            # Get a "work item" out of the queue.
            message = self.queue.get(True)

            if message == FINAL:
                logging.warning("Received final; committer exiting...")
                break

            task_id, status = message

            if (counter + 1) % (100) == 0:
                logging.info("Committing message:: %d", counter)

            self.log.write(self._encode(task_id, status))

            if str(status) != "0":
                self._failed.add(task_id)
            else:
                self._completed.add(task_id)

            counter += 1


class PipeWorker(Base):
    """
    Base class for pipe worker, responsible for
    setting up data directory
    """

    def __init__(self, name, log_dir=None):
        # these libraries for downstream workers
        super().__init__(
            [
                "csv_util",
                "fs_util",
                "json_util",
                "librosa",
                "m_audio.audio_util",
                "tqdm",
            ],
            {"audio_util": "m_audio.audio_util"},
        )

        self.name = name
        self.log_dir = log_dir or os.path.join(os.getcwd(), ".m_pipe_log")
        os.makedirs(self.log_dir, exist_ok=True)

        self._q = multiprocessing.Queue()
        self._c = Committer(self._q, self.log_dir)

    def _run(self, fn):
        """
        entry point for invoking the downstream task
        """
        self._c.start()

        fn()

        self._q.put(FINAL)
        self._c.join()


def get_ip():
    import socket

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    try:
        # doesn't even have to be reachable
        s.connect(("10.255.255.255", 1))
        ip = s.getsockname()[0]
    except:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def gcloud_external_ip():
    import requests

    return requests.get(
        "http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip",
        headers={"Metadata-Flavor": "Google"},
    ).content
