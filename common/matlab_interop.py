from pathlib import Path

import mat73
import scipy.io


def load_matlab_file(path: Path):
    """Load a layer's activations from a Matlab file"""
    try:
        # this works
        # noinspection PyTypeChecker
        activations = scipy.io.loadmat(path)
    except NotImplementedError:
        # scipy can't load matlab v7.3 files, so we use a different library
        activations = mat73.loadmat(path)
    return activations
