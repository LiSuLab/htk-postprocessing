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
from logging import getLogger, basicConfig, INFO

from numpy import array, nan, full

from common.layers import load_and_stack_data_for_layer, DNNLayer
from common.maths import quantile_of_score, shuffle
from common.segmentation import PhoneSegmentationSet

logger = getLogger(__name__)

N_PERMUTATIONS = 10_000


def main(layer: DNNLayer):
    phone_segmentations = PhoneSegmentationSet.load()

    # Load data in a very redundant way (but we already have code for it)
    _, _, activations_per_word_phone, labels_per_word_phone, _ = load_and_stack_data_for_layer(layer,
                                                                                               phone_segmentations)
    observed_value = statistic_for_labelling(activations_per_word_phone, labels_per_word_phone)

    # using numpy for fast shuffling, so labels must be in array of ints (underlying value of Phone)
    label_array: array = array([l.value for l in labels_per_word_phone])

    # preallocate permutation distribution of cluster stats
    distribution: array = full(N_PERMUTATIONS, nan)

    for permutation_i in range(N_PERMUTATIONS):
        shuffled_labels = shuffle(label_array)
        distribution[permutation_i] = (statistic_for_labelling(activations_per_word_phone, shuffled_labels))

    p_value = 1 - quantile_of_score(distribution, observed_value, kind='strict')

    logger.info(layer.name)
    logger.info(f"\tcluster statistic: {observed_value}")
    logger.info(f"\tp-value for {N_PERMUTATIONS} permutations: {p_value}")


def statistic_for_labelling(activations_per_word_phone: array, labels: array) -> float:
    """
    Computes a clustering statistic for the set of activations per phone-instance, given a specified set of labels.

    activations_per_word_phone: phone-occurrence x node array of activations
    labels: phone-occurrence x 1 array of phone labels (as ints, underlying values for Phone enum)

    returns: cluster stat for labelling
    """
    # TODO: Use cluster statistic code from Chao.
    return -1


if __name__ == '__main__':
    basicConfig(format='%(asctime)s | %(levelname)s | %(module)s | %(message)s', datefmt="%Y-%m-%d %H:%M:%S", level=INFO)
    for l in DNNLayer:
        main(l)
