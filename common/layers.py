from __future__ import annotations

from collections import defaultdict
from enum import Enum
from pathlib import Path
from typing import Tuple, List, Dict, DefaultDict

from numpy import mean, array

from .matlab_interop import load_matlab_file
from common.segmentation import Phone, PhoneSegmentation


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
    def old_name(self) -> str:
        """Maintains compatibility with files saved a long time ago"""
        if self == DNNLayer.L1_filterbank:
            return "FBK"
        elif self == DNNLayer.L7_bottleneck:
            return "7BN"
        else:
            return str(self.value)

    @property
    def name(self) -> str:
        """More sensible naming, to preserve alphabetic sorting"""
        if self == DNNLayer.L1_filterbank:
            return "Layer1_FBK"
        elif self == DNNLayer.L7_bottleneck:
            return "Layer7_BN"
        else:
            return f"Layer{self.value}"


def load_and_stack_data_for_layer(
    layer: DNNLayer,
    phone_segmentations,
    from_dir,
    file_pattern,
) -> Tuple[
    array, List[Phone],
    array, List[Phone],
    Dict[Phone, array]
]:
    """
    Load data for the specified layer, and distribute it in various ways.

    (I returning values like this isn't the best idea, but it'll work for now.)

    returns:

    activations_per_frame:
        frame x node array of activation values
    labels_per_frame:
        list of phone labels for each frame; order matched to above
    activations_per_word_phone:
        phone_occurrences x node array of activation values
    labels_per_word_phone:
        list of phone labels for individual occurrences; order matched to above
    activations_per_phone:
        dictionary of phone -> list of activations per node
    """

    # word -> (time x node) array
    # TODO: this naming is a real mess
    try:
        layer_activations = load_matlab_file(Path(from_dir, file_pattern.format(layer.name)))
    except FileNotFoundError:
        try:
            layer_activations = load_matlab_file(Path(from_dir, file_pattern.format(layer.old_name)))
        except FileNotFoundError:
            layer_activations = load_matlab_file(Path(from_dir, file_pattern.format(layer.value)))


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
            if segment.label == Phone.sil:
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
    activations_per_phone: Dict[Phone, array] = {
        phone: mean(activations, 0)
        for phone, activations in activations_per_phone.items()
    }

    return (
        activations_per_frame, labels_per_frame,
        activations_per_word_phone, labels_per_word_phone,
        activations_per_phone
    )
