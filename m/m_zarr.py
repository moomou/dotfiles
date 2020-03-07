import os

from m_base import Base


class MZarr(Base):
    def __init__(self):
        super(MZarr, self).__init__(["zarr", "pprint"])

    def ls(self, path, key=None):
        zarr = self._module("zarr")
        pprint = self._module("pprint")

        if not path or not path.endswith("zarr"):
            self._logger.warn("Requires a single path ending in zarr")
            return

        arr = zarr.open(path, mode="r")
        if key is not None:
            for k in key.split("/"):
                arr = arr[k]

        if isinstance(arr, zarr.hierarchy.Group):
            self._logger.info("Keys")
            pprint.pprint(list(arr.keys()))
        elif isinstance(arr, zarr.core.Array):
            self._logger.info("Array shape")
            pprint.pprint(arr.shape)
        else:
            self._logger.warn(f"Unsupported type:: [{arr.__class__.__name__}]")
