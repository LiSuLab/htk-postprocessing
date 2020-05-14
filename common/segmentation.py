from __future__ import annotations
from enum import Enum, auto
from pathlib import Path
from typing import Dict, List

from pandas import DataFrame

from .matlab_interop import load_matlab_file
from .paths import LOAD_DIR


class PhoneSegmentationSet:
    """Represents a full collection of phonetic segmentations for a list of words."""
    def __init__(self, from_dict: Dict):
        # Extract relevant data from Matlab dict
        self._segmentation: Dict[str, PhoneSegmentation] = {
            word: [
                PhoneSegment(onset_sample=seg[0][0][0],
                             offset_sample=seg[1][0][0],
                             label=Phone.from_name(seg[2][0]))
                for seg in from_dict[word][0]
            ]
            for word in from_dict.keys()
            if "__" not in word
        }

    def __getitem__(self, key: str):
        if key not in self.words:
            raise KeyError(key)
        return self._segmentation[key]

    @property
    def words(self) -> List[str]:
        """Ordered list of words."""
        return sorted(self._segmentation.keys())

    @classmethod
    def load(cls) -> PhoneSegmentationSet:
        return cls(load_matlab_file(Path(LOAD_DIR, "triphone_boundaries.mat")))


class PhoneSegment:
    """Represents a segment of input, with a phone label."""

    _samples_per_frame = 100_000

    def __init__(self, onset_sample: int, offset_sample: int, label: Phone):
        self.label: Phone = label

        # samples
        self.onset_sample: int = onset_sample
        self.offset_sample: int = offset_sample

        # frames
        self.onset_frame: int = int(self.onset_sample / self._samples_per_frame)
        self.offset_frame: int = int(self.offset_sample / self._samples_per_frame)

    def __repr__(self):
        return f"PhoneSegment(onset_frame={self.onset_frame}, offset_frame={self.offset_frame}, label={self.label})"


class Phone(Enum):
    """Represents the different phone labels"""
    sil = 0
    aa  = 1
    ae  = 2
    ah  = 3
    ao  = 4
    aw  = 5
    ay  = 6
    b   = 7
    ch  = 8
    d   = 9
    ea  = 10
    eh  = 11
    er  = 12
    ey  = 13
    f   = 14
    g   = 15
    hh  = 16
    ia  = 17
    ih  = 18
    iy  = 19
    jh  = 20
    k   = 21
    l   = 22
    m   = 23
    n   = 24
    ng  = 25
    oh  = 26
    ow  = 27
    oy  = 28
    p   = 29
    r   = 30
    s   = 31
    sh  = 32
    t   = 33
    th  = 34
    ua  = 35
    uh  = 36
    uw  = 37
    v   = 38
    w   = 39
    y   = 40
    z   = 41

    @classmethod
    def from_name(cls, name: str):
        for pl in cls:
            if pl.name == name:
                return pl
        raise ValueError(name)

    @property
    def features(self) -> List[Feature]:
        return [feature
                for feature in Feature
                if self in feature.phones]


class Feature(Enum):
    sonorant = auto()
    voiced = auto()
    syllabic = auto()
    obstruent = auto()
    labial = auto()
    coronal = auto()
    dorsal = auto()
    stop = auto()
    affricate = auto()
    fricative = auto()
    sibilant = auto()
    approximant = auto()
    nasal = auto()
    front = auto()
    central = auto()
    back = auto()
    close = auto()
    close_mid = auto()
    open_mid = auto()
    open_ = auto()
    rounded = auto()

    @property
    def name(self) -> str:
        if self == Feature.open_:
            return "open"
        else:
            return super().name

    @property
    def phones(self) -> List[Phone]:
        return [Phone.from_name(p)
                for p in list(self._df[self._df[self.name] == 1].index)]

    @classmethod
    def from_name(cls, name: str) -> Feature:
        for feature in cls:
            if feature.name == name:
                return feature
        raise ValueError(name)

    @property
    def _df(self) -> DataFrame:
        df = DataFrame.from_dict(dict([
            ("Phone",                  ["aa", "ae", "ah", "ao", "aw", "ay", "b", "ch", "d", "ea", "eh", "er", "ey", "f", "g", "hh", "ia", "ih", "iy", "jh", "k", "l", "m", "n", "ng", "oh", "ow", "oy", "p", "r", "s", "sh", "t", "th", "uh", "uw", "v", "w", "y", "z"]),
            (Feature.sonorant.name,    [   1,    1,    1,    1,    1,    1,   0,    0,   0,    1,    1,    1,    1,   0,   0,    0,    1,    1,    1,    0,   0,   1,   1,   1,    1,    1,    1,    1,   0,   1,   0,    0,   0,    0,    1,    1,   0,   1,   1,   0]),
            (Feature.voiced.name,      [   1,    1,    1,    1,    1,    1,   1,    0,   1,    1,    1,    1,    1,   0,   1,    0,    1,    1,    1,    1,   0,   1,   1,   1,    1,    1,    1,    1,   0,   1,   0,    0,   0,    0,    1,    1,   1,   1,   1,   1]),
            (Feature.syllabic.name,    [   1,    1,    1,    1,    1,    1,   0,    0,   0,    1,    1,    1,    1,   0,   0,    0,    1,    1,    1,    0,   0,   0,   0,   0,    0,    1,    1,    1,   0,   0,   0,    0,   0,    0,    1,    1,   0,   0,   0,   0]),
            (Feature.obstruent.name,   [   0,    0,    0,    0,    0,    0,   1,    1,   1,    0,    0,    0,    0,   1,   1,    1,    0,    0,    0,    1,   1,   1,   1,   1,    1,    0,    0,    0,   1,   1,   1,    1,   1,    1,    0,    0,   1,   0,   0,   1]),
            (Feature.labial.name,      [   0,    0,    0,    0,    0,    0,   1,    0,   0,    0,    0,    0,    0,   1,   0,    0,    0,    0,    0,    0,   0,   0,   1,   0,    0,    0,    0,    0,   1,   0,   0,    0,   0,    0,    0,    0,   1,   0,   0,   0]),
            (Feature.coronal.name,     [   0,    0,    0,    0,    0,    0,   0,    1,   1,    0,    0,    0,    0,   0,   0,    0,    0,    0,    0,    1,   0,   1,   0,   1,    0,    0,    0,    0,   0,   1,   1,    1,   1,    1,    0,    0,   0,   0,   1,   1]),
            (Feature.dorsal.name,      [   0,    0,    0,    0,    0,    0,   0,    0,   0,    0,    0,    0,    0,   0,   1,    0,    0,    0,    0,    0,   1,   0,   0,   0,    1,    0,    0,    0,   0,   0,   0,    0,   0,    0,    0,    0,   0,   1,   0,   0]),
            (Feature.stop.name,        [   0,    0,    0,    0,    0,    0,   1,    0,   1,    0,    0,    0,    0,   0,   1,    0,    0,    0,    0,    0,   1,   0,   0,   0,    0,    0,    0,    0,   1,   0,   0,    0,   1,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.affricate.name,   [   0,    0,    0,    0,    0,    0,   0,    1,   0,    0,    0,    0,    0,   0,   0,    0,    0,    0,    0,    1,   0,   0,   0,   0,    0,    0,    0,    0,   0,   0,   0,    0,   0,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.fricative.name,   [   0,    0,    0,    0,    0,    0,   0,    0,   0,    0,    0,    0,    0,   1,   0,    1,    0,    0,    0,    0,   0,   0,   0,   0,    0,    0,    0,    0,   0,   0,   1,    1,   0,    1,    0,    0,   1,   0,   0,   1]),
            (Feature.sibilant.name,    [   0,    0,    0,    0,    0,    0,   0,    1,   0,    0,    0,    0,    0,   0,   0,    0,    0,    0,    0,    1,   0,   0,   0,   0,    0,    0,    0,    0,   0,   0,   1,    1,   0,    0,    0,    0,   0,   0,   0,   1]),
            (Feature.approximant.name, [   0,    0,    0,    0,    0,    0,   0,    0,   0,    0,    0,    0,    0,   0,   0,    1,    0,    0,    0,    0,   0,   1,   0,   0,    0,    0,    0,    0,   0,   1,   0,    0,   0,    0,    0,    0,   0,   1,   1,   0]),
            (Feature.nasal.name,       [   0,    0,    0,    0,    0,    0,   0,    0,   0,    0,    0,    0,    0,   0,   0,    0,    0,    0,    0,    0,   0,   0,   1,   1,    1,    0,    0,    0,   0,   0,   0,    0,   0,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.front.name,       [   0,    1,    0,    0,    0,    1,   0,    0,   0,    1,    1,    0,    1,   0,   0,    0,    1,    1,    1,    0,   0,   0,   0,   0,    0,    0,    0,    0,   0,   0,   0,    0,   0,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.central.name,     [   0,    0,    0,    0,    1,    1,   0,    0,   0,    1,    0,    1,    0,   0,   0,    0,    1,    0,    0,    0,   0,   0,   0,   0,    0,    0,    1,    1,   0,   0,   0,    0,   0,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.back.name,        [   1,    0,    1,    1,    1,    0,   0,    0,   0,    0,    0,    0,    0,   0,   0,    0,    0,    0,    0,    0,   0,   0,   0,   0,    0,    1,    1,    1,   0,   0,   0,    0,   0,    0,    1,    1,   0,   0,   0,   0]),
            (Feature.close.name,       [   0,    0,    0,    0,    0,    1,   0,    0,   0,    0,    0,    0,    0,   0,   0,    0,    1,    1,    1,    0,   0,   0,   0,   0,    0,    0,    0,    0,   0,   0,   0,    0,   0,    0,    1,    1,   0,   0,   0,   0]),
            (Feature.close_mid.name,   [   0,    0,    0,    0,    1,    0,   0,    0,   0,    0,    0,    0,    1,   0,   0,    0,    1,    0,    0,    0,   0,   0,   0,   0,    0,    0,    1,    1,   0,   0,   0,    0,   0,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.open_mid.name,    [   0,    1,    1,    1,    0,    0,   0,    0,   0,    1,    1,    1,    1,   0,   0,    0,    0,    0,    0,    0,   0,   0,   0,   0,    0,    0,    1,    1,   0,   0,   0,    0,   0,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.open_.name,       [   1,    0,    0,    0,    1,    1,   0,    0,   0,    0,    0,    0,    0,   0,   0,    0,    0,    0,    0,    0,   0,   0,   0,   0,    0,    1,    0,    0,   0,   0,   0,    0,   0,    0,    0,    0,   0,   0,   0,   0]),
            (Feature.rounded.name,     [   0,    0,    0,    1,    1,    0,   0,    0,   0,    0,    0,    0,    0,   0,   0,    0,    0,    0,    0,    0,   0,   0,   0,   0,    0,    1,    1,    1,   0,   0,   0,    0,   0,    0,    1,    1,   0,   0,   0,   0]),
        ]))
        df.set_index(keys="Phone", drop=True, inplace=True, verify_integrity=True)
        return df


PhoneSegmentation = List[PhoneSegment]
