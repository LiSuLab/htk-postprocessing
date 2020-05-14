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

from sys import argv
from logging import getLogger, basicConfig, INFO
from pathlib import Path
from typing import List, Tuple

from numpy import array, load as np_load, save as np_save
from sklearn.manifold import TSNE
from matplotlib import pyplot

from common.layers import DNNLayer, load_and_stack_data_for_layer
from common.paths import TSNE_SAVE_DIR
from common.segmentation import PhoneSegmentationSet, Feature

logger = getLogger(__name__)


def run_tsne_script():
    """The script."""

    phone_segmentations = PhoneSegmentationSet.load()

    for layer in reversed(DNNLayer):  # run top-to-bottom

        logger.info(f"DNN layer {layer.name}")

        (
            activations_per_frame, labels_per_frame,
            activations_per_word_phone, labels_per_word_phone,
            activations_per_phone
        ) = load_and_stack_data_for_layer(layer, phone_segmentations)

        t_sne_frame = compute_tsne_positions(activations_per_frame, name=f"{layer.old_name} frame", perplexity=40)
        t_sne_word_phone = compute_tsne_positions(activations_per_word_phone, name=f"{layer.old_name} word–phone", perplexity=30)

        # labelled by phones
        plot_tsne(t_sne_word_phone,
                  [(phone.value, phone.name) for phone in labels_per_word_phone],
                  f"t-SNE layer {layer.old_name} word–phone phone-label")
        plot_tsne(t_sne_frame,
                  [(l.value, l.name) for l in labels_per_frame],
                  f"t-SNE layer {layer.old_name} frame phone-label")

        # labelled by features
        for feature in Feature:
            plot_tsne(t_sne_word_phone,
                      [(1 if phone in feature.phones else 0, "")
                       for phone in labels_per_word_phone],
                      f"t-SNE layer {layer.old_name} feature-{feature.name}")


def plot_tsne(t_sne_positions: array,
              phone_labels_per_point: List[Tuple[int, str]],
              figure_name: str):
    """
    Generate and plot t-SNE.

   `phone_labels_per_point`: An ordred list, for each point: a tuple of a label id and label tag.
                             Used for colouring points
    """
    pyplot.figure(figsize=(16, 16))
    pyplot.scatter(
        x=t_sne_positions[:, 0],
        y=t_sne_positions[:, 1],
        c=array([i for i, label in phone_labels_per_point]),
        cmap='rainbow',
        alpha=0.5,
    )
    pyplot.title(f"{figure_name}")
    pyplot.savefig(Path(TSNE_SAVE_DIR, "figures", f"{figure_name}.png"))
    pyplot.close()


def compute_tsne_positions(activations_per_point: array, perplexity: int, name: str) -> array:
    """
    Computes t-SNE positions from a dataset.

    `activations_per_point`: n_obvs x n_dims
    """
    logger.info(f"TSNE from data of size {activations_per_point.shape}")

    t_sne_positions_path = Path(TSNE_SAVE_DIR, f"t-sne positions {name} perp={perplexity}.npy")
    if t_sne_positions_path.exists():
        logger.info("Loading...")
        t_sne_positions = np_load(t_sne_positions_path)
    else:
        logger.info("Computing...")
        t_sne_positions = TSNE(
            n_components=2,  # 2D
            perplexity=perplexity,
            # Recommended args
            n_iter=1_000,
            learning_rate=200,
            method="barnes_hut",
        ).fit_transform(activations_per_point)
        np_save(t_sne_positions_path, t_sne_positions)
    return t_sne_positions


def scratch():
    logger.info(Feature.sonorant.phones)


if __name__ == '__main__':
    basicConfig(format='%(asctime)s | %(levelname)s | %(module)s | %(message)s', datefmt="%Y-%m-%d %H:%M:%S",
                level=INFO)
    logger.info("Running %s" % " ".join(argv))
    run_tsne_script()
    logger.info("Done!")
