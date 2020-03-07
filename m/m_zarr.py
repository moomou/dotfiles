import os

from m_base import Base


class MZarr(Base):
    def __init__(self):
        super(MZarr, self).__init__(["zarr", "pprint"])

    def ls(self, path, key=None):
        zarr = self._module("zarr")
        pprint = self._module("pprint")

        if not path or not path.endswith("zarr"):
            self._logger.info("Requires a single path ending in zarr")

        arr = zarr.open(path, mode="r")
        if key is not None:
            for k in key.split("/"):
                arr = arr[k]

        pprint.pprint(list(arr.keys()))