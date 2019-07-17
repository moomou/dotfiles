class PipeException(Exception):
    pass


class PanicException(PipeException):
    pass


class Error(PipeException):
    pass


class PipeTask:
    def __init__(self, task_id, queue):
        self.task_id = task_id
        self.failed = False
        self._queue = queue

    def __enter__(self):
        pass

    def __exit__(self, exception_type, exception_value, traceback):
        if exception_value is not None:
            if exception_type is PanicException:
                return False
            self.failed = True
            self._queue.put((self.task_id, 1))
        else:
            self._queue.put((self.task_id, 0))

        # return True to swallow exception
        return True
