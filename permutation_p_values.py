"""
===========================
Compute p-values by permuting phone labels.
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
from logging import getLogger
from random import shuffle
from typing import List

from numpy import array

from common.layers import load_and_stack_data_for_layer, DNNLayer
from common.maths import quantile_of_score
from common.segmentation import PhoneSegmentationSet, Phone

logger = getLogger(__name__)

N_PERMUTATIONS = 10# _000


def main(layer: DNNLayer):
    phone_segmentations = PhoneSegmentationSet.load()

    _, _, activations_per_word_phone, labels_per_word_phone, _ = load_and_stack_data_for_layer(layer,
                                                                                               phone_segmentations)
    true_value = statistic_for_labelling(activations_per_word_phone, labels_per_word_phone)

    distribution = []
    shuffled_labels = labels_per_word_phone.copy()
    for permutation_i in range(N_PERMUTATIONS):
        shuffle(shuffled_labels)
        distribution.append(statistic_for_labelling(activations_per_word_phone, shuffled_labels))

    p_value = 1 - quantile_of_score(distribution, true_value, kind='strict')

    logger.info(layer.name)
    logger.info(f"\tcluster statistic: {true_value}")
    logger.info(f"\tp-value for {N_PERMUTATIONS} permutations: {p_value}")
    print(f"{layer.name}"
          f"cluster statistic:")


def statistic_for_labelling(activations_per_word_phone: array, labels: List[Phone]) -> float:
    # TODO
    return 0


if __name__ == '__main__':
    for layer in DNNLayer:
        main(layer)
