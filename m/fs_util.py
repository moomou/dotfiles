import errno
import os
import shutil


def safe_move(src, dst):
    """Rename a file from ``src`` to ``dst``.

    *   Moves must be atomic.  ``shutil.move()`` is not atomic.
        Note that multiple threads may try to write to the cache at once,
        so atomicity is required to ensure the serving on one thread doesn't
        pick up a partially saved image from another thread.

    *   Moves must work across filesystems.  Often temp directories and the
        cache directories live on different filesystems.  ``os.rename()`` can
        throw errors if run across filesystems.

    So we try ``os.rename()``, but if we detect a cross-filesystem copy, we
    switch to ``shutil.move()`` with some wrappers to make it atomic.
    """
    try:
        os.rename(src, dst)
    except OSError as err:

        if err.errno == errno.EXDEV:
            # Generate a unique ID, and copy `<src>` to the target directory
            # with a temporary name `<dst>.<ID>.tmp`.  Because we're copying
            # across a filesystem boundary, this initial copy may not be
            # atomic.  We intersperse a random UUID so if different processes
            # are copying into `<dst>`, they don't overlap in their tmp copies.
            copy_id = uuid.uuid4()
            tmp_dst = "%s.%s.tmp" % (dst, copy_id)
            shutil.copyfile(src, tmp_dst)

            # Then do an atomic rename onto the new name, and clean up the
            # source image.
            os.rename(tmp_dst, dst)
            os.unlink(src)
        else:
            raise


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
