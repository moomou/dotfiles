import os

from m_base import Base


class MZarr(Base):
    def __init__(self):
        super(MZarr, self).__init__(["zarr"])

    def ls(self, path, key=None):
        zarr = self._module("zarr")

        if not path or path.endswith("zarr"):
            self._logger.info("Requires a single path ending in zarr")

        arr = zarr.open(path, mode="r")
        if key is not None:
            for k in key.split("."):
                arr = arr[k]
            print(arr.keys())
        else:
            print(arr.keys())
