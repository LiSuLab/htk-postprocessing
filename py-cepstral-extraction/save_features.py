# coding=utf-8
"""
Assumes a fixed number of frames for each condition.
"""

import sys
import re

import scipy
import scipy.io
import numpy

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
        "output=<output-directory> "
        ""
        "For example:"
        "python cepstral_model_rdms "
        "input=C:\\Users\\cai\\Desktop\\cepstral-model\\ProcessedResult.log "
        "output=C:\\Users\\cai\\Desktop\\cepstral-model\\Features.mat "
    )
    silent = "S" in switches

    input_file = get_parameter(parameters, "input", True, usage_text)
    output_filename = get_parameter(parameters, "output", True, usage_text)

    return input_file, output_filename, silent


def get_condition_vectors(input_filename, silent):
    """
    Expect frames to start at 0 for each condition and to be sequential
    in increments of 1

    :param input_filename:
    :return condition_vectors: a word-keyed dictionary of
            (frame, condition)-arrays
    :return condition_labels: a dictionary of ints, indexed by condition
            labels.
    """
    condition_label_re = re.compile(r"^(?P<conditionlabel>[a-z]+)$")
    feature_vector_re = re.compile(r"^(?P<frameid>[0-9]+):(?P<featurevector>.*)$")

    condition_vectors = dict()

    this_condition_label = None

    # Defaults
    this_condition_array = None

    with open(input_filename, encoding="utf-8") as input_file:

        for line in input_file:

            # Possible matches
            condition_label_match = condition_label_re.match(line)
            feature_vector_match = feature_vector_re.match(line)

            # The line we've read can match either condition labels
            # or feature vectors for a particular frame
            if condition_label_match:

                # We've matched a new condition label

                # If there's a condition that's already been processed,
                # we should remember what we've got so far
                if this_condition_label is not None:
                    condition_vectors[this_condition_label] = this_condition_array

                # Reset defaults
                this_condition_array = None

                # Now we can start on the newly processed label
                this_condition_label = condition_label_match.group("conditionlabel")

                if not silent:
                    print("Condition: {0}".format(this_condition_label))

            elif feature_vector_match:

                # We've matched a feature vector for a particular frame

                this_frame_id = feature_vector_match.group("frameid")
                this_condition_vector = [float(x) for x in feature_vector_match.group("featurevector").split(",")]

                if not silent:
                    print("\tf-{0}:".format(this_frame_id))
                    i = 1
                    for feature in this_condition_vector:
                        print("\t\t[{0}]{1}".format(i, feature))
                        i += 1

                # If this is the first frame for this condition, we need to
                # create an array for the condition vector
                if this_condition_array is None:
                    this_condition_array = numpy.array(this_condition_vector)

                # Otherwise we need to append the current list to the array
                else:
                    # Just quick sanity check
                    if this_frame_id == "0" or this_frame_id is None:
                        raise ApplicationError("Wasn't expecting the first frame to be here")

                    this_condition_array = numpy.vstack((
                        this_condition_array,
                        numpy.array(this_condition_vector)
                    ))

        # Remember to save what we've got on the last one too.
        condition_vectors[this_condition_label] = this_condition_array

    return condition_vectors


def transform_and_save(output_filename, condition_vectors):
    """
    Will save the following in a Matlab-readable format:
    - A struct with a field named after each condition label, containing frame
      x condition arrays

    :param output_filename:
    :param condition_vectors: a word-keyed dictionary of
                              (frame, condition)-arrays
    """

    scipy.io.savemat(output_filename, condition_vectors, appendmat=False)


def main(argv):
    with open("{0}.log".format(__file__), mode="w", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):

        (switches, parameters, commands) = parse_args(argv)
        (input_filename, output_filename, silent) = process_args(switches, parameters, commands)

        condition_vectors = get_condition_vectors(input_filename, silent)

        transform_and_save(output_filename, condition_vectors)


if __name__ == "__main__":
    main(sys.argv)
