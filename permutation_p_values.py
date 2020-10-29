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
from collections import namedtuple
from dataclasses import dataclass
from enum import Enum, auto
from pathlib import Path
from typing import Callable, Optional
from logging import getLogger, basicConfig, INFO, FileHandler

from numpy import array, nan, full, where
from pandas import DataFrame
from sklearn.decomposition import PCA
from sklearn.metrics import davies_bouldin_score, silhouette_score

from jqm_cvi.jqmcvi.base import dunn_fast

from common.layers import load_and_stack_data_for_layer, DNNLayer
from common.logging import print_progress
from common.maths import quantile_of_score, shuffle
from common.segmentation import PhoneSegmentationSet, Phone
from fisher.fisher import GetFisher

logger = getLogger(__name__)


class Measure(Enum):
    Fisher        = auto()
    DaviesBouldin = auto()
    Silhouette    = auto()
    Dunn          = auto()


@dataclass
class ClusteringResult:
    pca: bool
    pca_dims: Optional[int]
    pca_explained_variance_total: Optional[float]
    cluster_statistic_type: Measure
    cluster_statistic_value: float
    cluster_statistic_p: Optional[float]
    cluster_statistic_p_perms: Optional[int]
    cluster_statistic_p_default: Optional[bool]


def statistics_for_class(segmentation_path: Path, activations_path: Path, file_pattern: str,
                         layer: DNNLayer, class_labelling: Callable[[Phone], Optional[int]], measure: Measure,
                         pca_dims: Optional[int], p_value_perms: Optional[int]) -> ClusteringResult:


    with_pca = pca_dims is not None
    compute_p_value = p_value_perms is not None

    phone_segmentations = PhoneSegmentationSet.load(from_dir=segmentation_path)

    # Load data in a very redundant way (but we already have code for it)
    _, _, activations_per_word_phone, labels_per_word_phone, _ = load_and_stack_data_for_layer(layer, phone_segmentations,
                                                                                               from_dir=activations_path,
                                                                                               file_pattern=file_pattern)

    # using numpy for fast shuffling, so labels must be in array of ints (underlying value of Phone)
    label_array: array = array([class_labelling(l) for l in labels_per_word_phone])

    # Filter out rows where labels are None
    activations_per_word_phone = activations_per_word_phone[where(label_array != None)[0], :]
    label_array = label_array[where(label_array != None)[0]]

    activations: array
    if with_pca:
        logger.info(f"\tApplying PCA ({activations_per_word_phone.shape[1]} -> {pca_dims} dims)")
        pca = PCA(n_components=pca_dims)
        activations = pca.fit_transform(activations_per_word_phone)
        logger.info(f"\t\tExplained variance: {sum(pca.explained_variance_ratio_)} ({', '.join(list(f'{v:0.2}' for v in pca.explained_variance_ratio_))})")
    else:
        pca = None
        activations = activations_per_word_phone

    observed_value = statistic_for_labelling(activations, label_array, measure)

    logger.info(f"\tcluster statistic ({measure.name}): {observed_value}")

    if compute_p_value:

        # preallocate permutation null distribution of cluster stats
        null_distribution: array = full(p_value_perms, nan)

        # create null distribution
        for permutation_i in range(p_value_perms):
            shuffled_labels = shuffle(label_array)
            null_distribution[permutation_i] = statistic_for_labelling(activations, shuffled_labels, measure=measure)
            print_progress(permutation_i + 1, p_value_perms)

        # Compute p-values from distribution
        extra_messages = []
        if measure in {Measure.Fisher, Measure.Silhouette, Measure.Dunn}:
            # higher is better
            p_value = 1 - quantile_of_score(null_distribution, observed_value, kind='strict')
            if observed_value > max(null_distribution):
                p_fell_off = True
                extra_messages.append(f"statistic ({observed_value}) was largest in null distribution (max={max(null_distribution)})")
                extra_messages.append(f"this should be noted, and p-value should instead be \"< {1 / p_value_perms}\"")
            else:
                p_fell_off = False
        elif measure == Measure.DaviesBouldin:
            # lower is better
            p_value = quantile_of_score(null_distribution, observed_value, kind='strict')
            if observed_value < min(null_distribution):
                p_fell_off = True
                extra_messages.append(f"statistic ({observed_value}) was smallest in null distribution (min={min(null_distribution)})")
                extra_messages.append(f"this should be noted, and p-value should instead be \"< {1 / p_value_perms}\"")
            else:
                p_fell_off = False
        else:
            raise NotImplementedError()

        logger.info(f"\tp-value for {p_value_perms} permutations: {p_value}")
        _ = [logger.info(f"\t\t{m}") for m in extra_messages]

    else:
        p_value = None
        p_fell_off = None

    return ClusteringResult(
        pca=with_pca,
        pca_dims=pca_dims,
        pca_explained_variance_total=sum(pca.explained_variance_ratio_) if pca is not None else None,
        cluster_statistic_type=measure,
        cluster_statistic_value=observed_value,
        cluster_statistic_p_perms=p_value_perms if compute_p_value else None,
        cluster_statistic_p=p_value if compute_p_value else None,
        cluster_statistic_p_default=p_fell_off if compute_p_value else None,
    )


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
    elif measure == Measure.Silhouette:
        return silhouette_score(activations_per_word_phone, labels=labels)
    elif measure == Measure.Dunn:
        return dunn_fast(activations_per_word_phone, labels=labels)
    else:
        raise NotImplementedError()


if __name__ == '__main__':
    basicConfig(format='%(asctime)s | %(levelname)s | %(module)s | %(message)s', datefmt="%Y-%m-%d %H:%M:%S", level=INFO)

    stat = Measure.DaviesBouldin
    perms = 5_000
    pca = None

    root_dir = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping")
    cluster_analysis_root_dir = Path(root_dir, "cluster analysis")
    alignments_root_dir = Path(root_dir, "phonetic alignments")
    activations_dir = Path(root_dir, "extracted activations mat files")
    csv_path = Path(root_dir, "cluster analysis", "results.csv")

    results = []

    for system in [3, 4, 5, 0]:

        # Set up new log file handler
        fh = FileHandler(Path(root_dir, "cluster analysis", f"clustering system{system} {stat.name}.log"), "w")
        for h in logger.handlers[:]:
            logger.removeHandler(h)
        logger.addHandler(fh)

        logger.info(f" <<< SYSTEM {system} >>> ")

        if system == 0:
            layers = [l for l in DNNLayer]
        else:
            # TODO: dear god, I wasn't expecting to have to adapt this for new network architectures
            #   this should pass the duck test for DNNLayer
            L = namedtuple("L", ["name", "old_name", "value"])
            # Systems 3, 4 and 5 only had outputs labelled 0--5, starting at the first hidden layer
            # So I've copied the activations for the FBK layer to the activation directories, and called if FBK
            # (The FBK activation will be the same for all layers, but we still need to reanalyse it as the
            # segmentations have changed).
            layers = [L("FBK", "FBK", -1)] + [L(str(i), str(i), i) for i in range(6)]

        for l in layers:
            logger.info(f"=== {l} ===")

            for name, labelling in [
                ("Phone",  lambda phone: phone.value),
                ("Place",  lambda phone: phone.hierarchy_feature_place.value  if phone.hierarchy_feature_place  is not None else None),
                ("Manner", lambda phone: phone.hierarchy_feature_manner.value if phone.hierarchy_feature_manner is not None else None),
                ("Front",  lambda phone: phone.hierarchy_feature_front.value  if phone.hierarchy_feature_front  is not None else None),
                ("Close",  lambda phone: phone.hierarchy_feature_close.value  if phone.hierarchy_feature_close  is not None else None),
            ]:

                logger.info(f"- {name} feature hierarchy classification")
                clustering_result = statistics_for_class(
                    segmentation_path=Path(alignments_root_dir, f"system{system}", "segmentation"),
                    activations_path=Path(activations_dir, f"system{system}"),
                    file_pattern="hidden_layer_{0}_activations.mat" if system == 0 else "hmm{0}_activations.mat",
                    layer=l, class_labelling=labelling, measure=stat, pca_dims=pca, p_value_perms=perms)

                results.append({
                    "System": system,
                    "Layer name": l.name,
                    "Layer oldname": l.old_name,
                    "Layer value": l.value,
                    "PCA": clustering_result.pca,
                    "PCA dims": clustering_result.pca_dims,
                    "PCA explained variance total": clustering_result.pca_explained_variance_total,
                    "Labelling": name,
                    "Cluster statistic type": clustering_result.cluster_statistic_type.name,
                    "Cluster statistic value": clustering_result.cluster_statistic_value,
                    "Cluster statistic p": clustering_result.cluster_statistic_p,
                    "Cluster statistic p perms": clustering_result.cluster_statistic_p_perms,
                    "Cluster statistic p default": clustering_result.cluster_statistic_p_default,
                })

        logger.info("")

    with open(csv_path.absolute(), mode="w", encoding="utf-8") as csv_file:
        DataFrame(results).to_csv(csv_file, index=False)
