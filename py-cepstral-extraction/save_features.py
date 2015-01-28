# coding=utf-8
"""
Assumes a fixed number of frames for each condition.
"""

import re
from collections import defaultdict # for dict2

from cw_common import *


# noinspection PyUnusedLocal
def process_args(switches, parameters, commands):
    """
    Gets relevant info from switches, parameters and commands
    :param switches:
    :param parameters:
    :param commands:
    :return:
    """
    usage_text = (
        "python save_features "
        "input=<input-path> "
        "output=<output-path> "
        "distance=<distance>"
        ""
        "For example:"
        "python cepstral_model_rdms "
        "input=C:\\Users\\cai\\Desktop\\cepstral-model\\ProcessedResult.log "
        "output=C:\\Users\\cai\\Desktop\\cepstral-model\\RDMs.mat "
        "distance=Pearson"
    )
    silent = "S" in switches

    input_file = get_parameter(parameters, "input", True, usage_text)
    output_file = get_parameter(parameters, "output", True, usage_text)
    distance = get_parameter(parameters, "distance", usage_text=usage_text)

    return input_file, output_file, distance


def get_condition_vectors(input_filename):
    """

    :param input_filename:
    :return condition_vectors: a (frame,word)-keyed dictionary of condition vectors
    :return condition_ids: a dictionary of ints, indexed by condition labels.
    :return condition_labels: a dictionary of condition labels, indexed by ints.
    """
    condition_label_re = re.compile(r"^(?P<conditionlabel>[a-z]+)$")
    feature_vector_re = re.compile(r"^(?P<frameid>[0-9]+):(?P<featurevector>.*)$")

    condition_vectors = defaultdict(dict)
    condition_ids = dict()
    condition_labels = dict()
    this_condition_id = 0
    frames = 0

    with open(input_filename, encoding="utf-8") as input_file:

        this_condition_label = None
        this_frame_id = None
        this_condition_vector = None

        for line in input_file:

            condition_label_match = condition_label_re.match(line)
            feature_vector_match = feature_vector_re.match(line)

            if condition_label_match:
                # We've matched a new condition label

                # If there's a condition that's already been processed, remember what we've got so far
                if this_condition_label is not None:
                    condition_vectors[this_condition_label] = {
                        this_frame_id: this_condition_vector
                    }

                this_condition_label = condition_label_match.group("conditionlabel")

                # Add this condition to the dictionaries
                this_condition_id += 1
                condition_ids[this_condition_label] = this_condition_id
                condition_labels[this_condition_id] = this_condition_label

                # Reset defaults
                this_condition_vector = None
                this_frame_id = None

            elif feature_vector_match:
                this_frame_id = feature_vector_match.group("frameid")
                this_condition_vector = feature_vector_match.group("featurevector").split(",")

                # add to dictionary
                condition_vectors[this_frame_id, this_condition_label] = this_condition_vector

                # keep count of frames
                # todo ugh this is not too robust
                frames = max(frames, int(this_frame_id))

    return condition_vectors, condition_ids, condition_labels, frames


def transform_and_save(condition_vectors, condition_ids, condition_labels, output_filename, frames, distance):
    with open(output_filename, mode="w", encoding="utf-8") as output_file:
        # We'll create a separate RDM for each frame
        for frame in frames:
            # We fill a single cell for each




if __name__ == "__main__":
    args = sys.argv
    (switches, parameters, commands) = parse_args(args)
    (input_filename, output_filename, distance) = process_args(switches, parameters, commands)

    (condition_vectors, condition_ids, condition_labels, frames) = get_condition_vectors(input_filename)

    transform_and_save(condition_vectors, condition_ids, condition_labels, output_filename, frames, distance)
