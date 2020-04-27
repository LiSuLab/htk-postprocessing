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

from numpy import array, mean, load as np_load, savez as np_save
import scipy.io
import mat73
from sklearn.manifold import TSNE
from matplotlib import pyplot


LOAD_DIR = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping/scratch/py_out")
SAVE_DIR = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping/t-sne/new t-sne")

PERPLEXITY = 40


def main():
    """The script."""

    phone_segmentations = PhoneSegmentationSet.load()

    for layer in DNNLayer:

        print(f"DNN layer {layer.name}")

        (
            activations_per_frame, labels_per_frame,
            activations_per_word_phone, labels_per_word_phone,
            activations_per_phone
        ) = stack_data_for_layer(layer, phone_segmentations)

        plot_tsne(activations_per_word_phone, labels_per_word_phone, f"{layer.name} word phone tsne")
        plot_tsne(activations_per_frame, labels_per_frame, f"{layer.name} frame tsne")


def plot_tsne(activations_per_point: array,
              phone_labels_per_point: List[PhoneSegment.Label],
              figure_name: str):
    """Generate and plot t-SNE"""
    t_sne_positions_path = Path(SAVE_DIR, f"t-sne positions {figure_name}.npz")
    if t_sne_positions_path.exists():
        t_sne_positions = np_load(t_sne_positions_path)
    else:
        t_sne_positions = compute_tsne_positions(activations_per_point)
        np_save(t_sne_positions_path, t_sne_positions_path)

    pyplot.figure(figsize=(16, 10))
    pyplot.scatter(
        x=t_sne_positions[:, 0],
        y=t_sne_positions[:, 1],
        c=array([label.value for label in phone_labels_per_point]),
        cmap='gist_rainbow',
        alpha=0.5,
    )
    pyplot.title(f"{figure_name}")
    pyplot.savefig(Path(SAVE_DIR, f"{figure_name}.png"))


def compute_tsne_positions(activations_per_point: array) -> array:
    """
    Computes t-SNE positions from a dataset.

    `activations_per_point`: n_obvs x n_dims
    """
    print(f"TSNE from data of size {activations_per_point.shape}")
    t_sne_positions = TSNE(
        n_components=2,  # 2D
        perplexity=PERPLEXITY,
        # Recommended args
        n_iter=1_000,
        learning_rate=200,
        method="barnes_hut",
    ).fit_transform(activations_per_point)
    return t_sne_positions


def stack_data_for_layer(layer, phone_segmentations) -> Tuple[
    array, List[PhoneSegment.Label],
    array, List[PhoneSegment.Label],
    Dict[PhoneSegment.Label, array]
]:
    """
    Load data for the specified layer, and distribute it in various ways.

    (I returning values like this isn't the best idea, but it'll work for now.)
    """

    # word -> (time x node) arrray
    layer_activations = load_matlab_file(Path(LOAD_DIR, f"hidden_layer_{layer.name}_activations.mat"))

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


class PhoneSegmentationSet:
    """Represents a full collection of phonetic segmentations for a list of words."""
    def __init__(self, from_dict: Dict):
        # Extract relevant data from Matlab dict
        self._segmentation: Dict[str, PhoneSegmentation] = {
            word: [
                PhoneSegment(onset_sample=seg[0][0][0],
                             offset_sample=seg[1][0][0],
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
        return cls(load_matlab_file(Path(LOAD_DIR, "triphone_boundaries.mat")))


class PhoneSegment:
    """Represents a segment of input, with a phone label."""

    _samples_per_frame = 100_000

    def __init__(self, onset_sample: int, offset_sample: int, label: PhoneSegment.Label):
        self.label: PhoneSegment.Label = label

        # samples
        self.onset_sample: int = onset_sample
        self.offset_sample: int = offset_sample

        # frames
        self.onset_frame: int = int(self.onset_sample / self._samples_per_frame)
        self.offset_frame: int = int(self.offset_sample / self._samples_per_frame)

    def __repr__(self):
        return f"PhoneSegment(onset_frame={self.onset_frame}, offset_frame={self.offset_frame}, label={self.label})"

    class Label(Enum):
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


PhoneSegmentation = List[PhoneSegment]


class DNNLayer(Enum):
    """Represents the different layers of the DNN"""
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
