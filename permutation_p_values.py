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
from enum import Enum, auto
from typing import Callable
from logging import getLogger, basicConfig, INFO

from numpy import array, nan, full
from sklearn.decomposition import PCA
from sklearn.metrics import davies_bouldin_score

from common.layers import load_and_stack_data_for_layer, DNNLayer
from common.logging import print_progress
from common.maths import quantile_of_score, shuffle
from common.segmentation import PhoneSegmentationSet, Phone
from fisher.fisher import GetFisher

logger = getLogger(__name__)

N_PERMUTATIONS = 5_000
PCA_DIMS = 26


class Measure(Enum):
    Fisher        = auto()
    DaviesBouldin = auto()


def statistics_for_class(layer: DNNLayer, class_labelling: Callable[[Phone], int], measure: Measure, with_pca: bool):

    phone_segmentations = PhoneSegmentationSet.load()

    # Load data in a very redundant way (but we already have code for it)
    _, _, activations_per_word_phone, labels_per_word_phone, _ = load_and_stack_data_for_layer(layer,
                                                                                               phone_segmentations)
    # using numpy for fast shuffling, so labels must be in array of ints (underlying value of Phone)
    label_array: array = array([class_labelling(l) for l in labels_per_word_phone])

    activations: array
    if with_pca:
        logger.info(f"\tApplying PCA ({activations_per_word_phone.shape[1]} -> {PCA_DIMS} dims)")
        pca = PCA(n_components=PCA_DIMS)
        activations = pca.fit_transform(activations_per_word_phone)
        logger.info(f"\t\tExplained variance: {sum(pca.explained_variance_ratio_)} ({', '.join(list(f'{v:0.2}' for v in pca.explained_variance_ratio_))})")
    else:
        activations = activations_per_word_phone

    observed_value = statistic_for_labelling(activations, label_array, measure)

    logger.info(f"\tcluster statistic ({measure.name}): {observed_value}")

    # preallocate permutation null distribution of cluster stats
    null_distribution: array = full(N_PERMUTATIONS, nan)

    # create null distribution
    for permutation_i in range(N_PERMUTATIONS):
        shuffled_labels = shuffle(label_array)
        null_distribution[permutation_i] = statistic_for_labelling(activations, shuffled_labels, measure=measure)
        print_progress(permutation_i + 1, N_PERMUTATIONS)

    # Compute p-values from distribution
    extra_messages = []
    if measure == Measure.Fisher:
        # higher is better
        p_value = 1 - quantile_of_score(null_distribution, observed_value, kind='strict')
        if observed_value > max(null_distribution):
            extra_messages.append(f"statistic ({observed_value}) was largest in null distribution (max={max(null_distribution)})")
            extra_messages.append(f"this should be noted, and p-value should instead be \"< {1/N_PERMUTATIONS}\"")
    elif measure == Measure.DaviesBouldin:
        # lower is better
        p_value = quantile_of_score(null_distribution, observed_value, kind='strict')
        if observed_value < min(null_distribution):
            extra_messages.append(f"statistic ({observed_value}) was smallest in null distribution (min={min(null_distribution)})")
            extra_messages.append(f"this should be noted, and p-value should instead be \"< {1/N_PERMUTATIONS}\"")
    else:
        raise NotImplementedError()

    logger.info(f"\tp-value for {N_PERMUTATIONS} permutations: {p_value}")
    _ = [logger.info(f"\t\t{m}") for m in extra_messages]


def statistic_for_labelling(activations_per_word_phone: array, labels: array, measure: Measure) -> float:
    """
    Computes a clustering statistic for the set of activations per phone-instance, given a specified set of labels.

    activations_per_word_phone: phone-occurrence x node array of activations
    labels: phone-occurrence x 1 array of phone labels (as ints, underlying values for Phone enum)

    returns: cluster stat for labelling
    """
    if measure == Measure.Fisher:
        return GetFisher(data=activations_per_word_phone, labels=labels)
    elif measure == Measure.DaviesBouldin:
        return davies_bouldin_score(X=activations_per_word_phone, labels=labels)
    else:
        raise NotImplementedError()


if __name__ == '__main__':
    basicConfig(format='%(asctime)s | %(levelname)s | %(module)s | %(message)s', datefmt="%Y-%m-%d %H:%M:%S",
                level=INFO)
    for l in DNNLayer:
        logger.info(f"=== {l.name} ===")

        logger.info("- Phone classification")
        statistics_for_class(l, class_labelling=lambda phone: phone.value,
                             measure=Measure.DaviesBouldin, with_pca=True)

        logger.info("- Place/front feature hierarchy classification")
        statistics_for_class(l, class_labelling=lambda phone: phone.hierarchy_feature_place_front.value,
                             measure=Measure.DaviesBouldin, with_pca=True)

        logger.info("- Manner/close feature hierarchy classification")
        statistics_for_class(l, class_labelling=lambda phone: phone.hierarchy_feature_manner_close.value,
                             measure=Measure.DaviesBouldin, with_pca=True)
