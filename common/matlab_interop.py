from os import PathLike
from typing import Union

import mat73
import scipy.io


def load_matlab_file(path: Union[str, PathLike]):
    """Load a layer's activations from a Matlab file"""
    try:
        # this works
        # noinspection PyTypeChecker
        activations = scipy.io.loadmat(str(path))
    except NotImplementedError:
        # scipy can't load matlab v7.3 files, so we use a different library
        activations = mat73.loadmat(str(path))
    return activations
