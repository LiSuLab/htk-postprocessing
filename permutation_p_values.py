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
from typing import Callable
from logging import getLogger, basicConfig, INFO

from numpy import array, nan, full
from sklearn.decomposition import PCA

from common.layers import load_and_stack_data_for_layer, DNNLayer
from common.logging import print_progress
from common.maths import quantile_of_score, shuffle
from common.segmentation import PhoneSegmentationSet, Phone
from fisher.fisher import GetFisher

logger = getLogger(__name__)

N_PERMUTATIONS = 5_000
PCA_DIMS = 26


def statistics_for_class(layer: DNNLayer, class_labelling: Callable[[Phone], int], with_pca: bool):

    logger.info(layer.name)

    phone_segmentations = PhoneSegmentationSet.load()

    # Load data in a very redundant way (but we already have code for it)
    _, _, activations_per_word_phone, labels_per_word_phone, _ = load_and_stack_data_for_layer(layer,
                                                                                               phone_segmentations)
    # using numpy for fast shuffling, so labels must be in array of ints (underlying value of Phone)
    label_array: array = array([class_labelling(l) for l in labels_per_word_phone])

    activations: array
    if with_pca:
        logger.info(f"Applying PCA ({activations_per_word_phone.shape[1]} -> {PCA_DIMS} dims)")
        pca = PCA(n_components=PCA_DIMS)
        activations = pca.fit_transform(activations_per_word_phone)
        logger.info(f"\tExplained variance: {sum(pca.explained_variance_ratio_)} ({', '.join(list(f'{v:0.2}' for v in pca.explained_variance_ratio_))})")
    else:
        activations = activations_per_word_phone

    observed_value = statistic_for_labelling(activations, label_array)

    # preallocate permutation distribution of cluster stats
    distribution: array = full(N_PERMUTATIONS, nan)

    for permutation_i in range(N_PERMUTATIONS):
        shuffled_labels = shuffle(label_array)
        distribution[permutation_i] = (statistic_for_labelling(activations, shuffled_labels))
        print_progress(permutation_i + 1, N_PERMUTATIONS)

    p_value = 1 - quantile_of_score(distribution, observed_value, kind='strict')

    logger.info(f"\tcluster statistic: {observed_value}")
    logger.info(f"\tp-value for {N_PERMUTATIONS} permutations: {p_value}")
    if observed_value > max(distribution):
        logger.info(f"\t\tstatistic ({observed_value}) was largest in distribution (max={max(distribution)})")
        logger.info(f"\t\tthis should be noted, and p-value should instead be \"< {1/N_PERMUTATIONS}\"")


def statistic_for_labelling(activations_per_word_phone: array, labels: array) -> float:
    """
    Computes a clustering statistic for the set of activations per phone-instance, given a specified set of labels.

    activations_per_word_phone: phone-occurrence x node array of activations
    labels: phone-occurrence x 1 array of phone labels (as ints, underlying values for Phone enum)

    returns: cluster stat for labelling
    """
    return GetFisher(data=activations_per_word_phone, labels=labels)


if __name__ == '__main__':
    basicConfig(format='%(asctime)s | %(levelname)s | %(module)s | %(message)s', datefmt="%Y-%m-%d %H:%M:%S",
                level=INFO)
    for l in DNNLayer:
        logger.info("Phone classification")
        statistics_for_class(l, class_labelling=lambda phone: phone.value, with_pca=True)

        logger.info("Place/front feature hierarchy classification")
        statistics_for_class(l, class_labelling=lambda phone: phone.hierarchy_feature_place_front.value, with_pca=True)

        logger.info("Manner/close feature hierarchy classification")
        statistics_for_class(l, class_labelling=lambda phone: phone.hierarchy_feature_manner_close.value, with_pca=True)
