import logging
import multiprocessing
import os
import pathlib
import threading

from m_base import Base

FINAL = "__FINAL__"


class Committer(threading.Thread):
    def __init__(self, queue, commit_dir):
        super().__init__()

        self.queue = queue
        self.commit_dir = commit_dir
        self.log_path = os.path.join(commit_dir, "log")

        self._completed, self._failed = self._parse_log()

        pathlib.Path(self.log_path).touch()
        self.log = open(self.log_path, mode="ab")

    @property
    def completed(self):
        return self._completed

    def _parse_log(self):
        completed = set()
        failed = set()

        if os.path.exists(self.log_path):
            with open(self.log_path) as f:
                for line in f:
                    task_id, status = line.split("~~")
                    if status != "0":
                        failed.add(task_id)
                    else:
                        completed.add(task_id)

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
