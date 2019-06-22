import multiprocessing
import threading
import time

import deco

q = multiprocessing.Queue()


@deco.concurrent
def meh(tid):
    q.put((tid, 1))
    return tid


@deco.synchronized
def moo():
    result = {}
    for i in range(5):
        result[i] = meh(i)
    return result


class T(threading.Thread):
    def __init__(self):
        super().__init__()

    def run(self):
        print("listenngin...", q)
        for i in range(5):
            item = q.get()
            print("I AM THREADED", item)


t = T()
t.start()
moo()
t.join()
