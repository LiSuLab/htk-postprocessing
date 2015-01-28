# coding=utf-8

import sys
import re
import scipy.io
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
        "python cepstral_model_rdms "
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


def get_condition_vectors(input_filename, output_filename):
    condition_label_re = re.compile(r"^(?P<conditionlabel>[a-z]+)$")
    feature_vector_re = re.compile(r"^(?P<frameid>[0-9]+):(?P<featurevector>.*)$")

    condition_vectors = dict()

    with open(input_filename, encoding="utf-8") as input_file:
        with open(output_filename, mode="w", encoding="utf-8") as output_file:

            this_condition_label = None
            this_frame_number = None
            this_condition_vector = None

            for line in input_file:

                condition_label_match = condition_label_re.match(line)
                feature_vector_match = feature_vector_re.match(line)

                if condition_label_match:
                    # We've matched a new condition label

                    # If there's a condition that's already been processed, remember what we've got so far
                    if this_condition_label is not None:
                        condition_vectors[this_condition_label] = {
                            this_frame_number: this_condition_vector
                        }

                    this_condition_label = condition_label_match.group("conditionlabel")
                    this_condition_vector = None
                    this_frame_number = None

                elif feature_vector_match:
                    this_frame_number = feature_vector_match.group("frameid")
                    this_condition_vector = feature_vector_match.group("featurevector").split(",")

    return condition_vectors


if __name__ == "__main__":
    args = sys.argv
    (switches, parameters, commands) = parse_args(args)
    (input_file, output_file, distance) = process_args(switches, parameters, commands)

    condition_vectors = get_condition_vectors(input_file, output_file)

    # todo: need to have a frame-indexed collection of word-by-word rdms
    rdms =
