"""
===========================
A port and modernisation of scr_mds_HL_all_phones.m to Python, with some extra features.
===========================

Dr. Cai Wingfield
---------------------------
Embodied Cognition Lab
Department of Psychology
University of Lancaster
c.wingfield@lancaster.ac.uk
caiwingfield.net
---------------------------
2020
---------------------------
"""
from __future__ import annotations

from collections import defaultdict
from enum import Enum
from pathlib import Path
from typing import Dict, List, DefaultDict, Tuple

from numpy import array, mean
import scipy.io
import mat73
from sklearn.manifold import TSNE
from matplotlib import pyplot


LOAD_DIR = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping/scratch/py_out")
SAVE_DIR = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping/t-sne/new t-sne")


def main():

    phone_segmentations = PhoneSegmentationSet.load()

    for layer in DNNLayer:

        print(f"DNN layer {layer.name}")

        (
            activations_per_frame, labels_per_frame,
            activations_per_word_phone, labels_per_word_phone,
            activations_per_phone
        ) = stack_data_for_layer(layer, phone_segmentations)

        t_sne_positions = TSNE(
            n_components=2,
            perplexity=30,
            n_iter=1_000,
            learning_rate=200,
            method="barnes_hut",
        ).fit_transform(activations_per_word_phone)

        pyplot.figure(figsize=(16, 10))
        pyplot.scatter(
            x=t_sne_positions[:, 0],
            y=t_sne_positions[:, 1],
            c=array([l.value for l in labels_per_word_phone]),
            cmap='gist_rainbow',
            alpha=0.5,
        )
        pyplot.savefig(Path(SAVE_DIR, f"{layer.name} tsne.png"))


def stack_data_for_layer(layer, phone_segmentations) -> Tuple[
    array, List[PhoneSegment.Label],
    array, List[PhoneSegment.Label],
    Dict[PhoneSegment.Label, array]
]:
    """Load data for the specified layer, and distribute it in various ways."""

    # word -> (time x node) ndarrray
    layer_activations = load_activations(Path(LOAD_DIR, f"hidden_layer_{layer.name}_activations.mat"))

    # frame x node
    activations_per_frame = []
    labels_per_frame = []
    # phone -> frame x node (to be averaged later)
    activations_per_phone: DefaultDict[PhoneSegmentation.Label, List] = defaultdict(list)
    # frame (mean over segments) x node
    activations_per_word_phone = []
    labels_per_word_phone = []
    for word in phone_segmentations.words:
        for segment in phone_segmentations[word]:
            # Skip silence
            if segment.label == PhoneSegment.Label.sil:
                continue
            activations_this_segment = layer_activations[word][segment.onset_frame:segment.offset_frame, :]

            # activations for each frame
            activations_per_frame.extend(activations_this_segment.tolist())
            labels_per_frame.extend([segment.label for _ in range(len(activations_this_segment))])

            # activations for this phone
            activations_per_phone[segment.label].extend(activations_this_segment.tolist())

            # average activation for this segment of this word
            activations_per_word_phone.append(mean(activations_this_segment, 0).tolist())
            labels_per_word_phone.append(segment.label)

    # Convert to arrays and do averaging as necessary
    activations_per_frame: array = array(activations_per_frame)
    activations_per_word_phone: array = array(activations_per_word_phone)
    activations_per_phone: Dict[PhoneSegment.Label, array] = {
        phone: mean(activations, 0)
        for phone, activations in activations_per_phone.items()
    }

    return (
        activations_per_frame, labels_per_frame,
        activations_per_word_phone, labels_per_word_phone,
        activations_per_phone
    )


def load_activations(path: Path):
    try:
        activations = scipy.io.loadmat(path)
    except NotImplementedError:
        activations = mat73.loadmat(path)
    return activations


class PhoneSegmentationSet:
    def __init__(self, from_dict: Dict):
        # Extract relevant data from Matlab dict
        self._segmentation: Dict[str, PhoneSegmentation] = {
            word: [
                PhoneSegment(onset=seg[0][0][0],
                             offset=seg[1][0][0],
                             label=PhoneSegment.Label.from_name(seg[2][0]))
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
        return cls(scipy.io.loadmat(Path(LOAD_DIR, "triphone_boundaries.mat")))


class PhoneSegment:

    frame_step_ms = 10
    frame_width_ms = 25

    samples_per_frame = 100_000

    def __init__(self, onset: int, offset: int, label: PhoneSegment.Label):
        self.label: PhoneSegment.Label = label

        # samples
        self.onset_sample: int = onset
        self.offset_sample: int = offset

        # frames
        self.onset_frame: int = int(self.onset_sample / self.samples_per_frame)
        self.offset_frame: int = int(self.offset_sample / self.samples_per_frame)


    def __repr__(self):
        return f"PhoneSegment(onset_frame={self.onset_frame}, offset_frame={self.offset_frame}, label={self.label})"

    class Label(Enum):
        sil = 1
        aa = 2
        ae = 3
        ah = 4
        ao = 5
        aw = 6
        ay = 7
        b = 8
        ch = 9
        d = 10
        ea = 11
        eh = 12
        er = 13
        ey = 14
        f = 15
        g = 16
        hh = 17
        ia = 18
        ih = 19
        iy = 20
        jh = 21
        k = 22
        l = 23
        m = 24
        n = 25
        ng = 26
        oh = 27
        ow = 28
        oy = 29
        p = 30
        r = 31
        s = 32
        sh = 33
        t = 34
        th = 35
        ua = 36
        uh = 37
        uw = 38
        v = 39
        w = 40
        y = 41
        z = 42

        @classmethod
        def from_name(cls, name: str):
            for pl in cls:
                if pl.name == name:
                    return pl
            raise ValueError(name)


PhoneSegmentation = List[PhoneSegment]


class DNNLayer(Enum):
    L1_filterbank = 1
    L2            = 2
    L3            = 3
    L4            = 4
    L5            = 5
    L6            = 6
    L7_bottleneck = 7

    @property
    def name(self):
        if self == DNNLayer.L1_filterbank:
            return "FBK"
        elif self == DNNLayer.L7_bottleneck:
            return "7BN"
        else:
            return str(self.value)


if __name__ == '__main__':
    main()
