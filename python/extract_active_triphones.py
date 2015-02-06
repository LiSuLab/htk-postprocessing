# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import re

from cw_common import *


def get_triphone_lists(input_filename, frames, silent):

    # Regular expression for the path of a word
    """
    Want to retun a word-keyed dictionary of frame_id-keyed dictionaries of triphone lists.
    :param input_filename:
    :param frames:
    :param silent:
    """
    word_path_re = re.compile(r"^File: (?P<wordpath>.+)\.mfc$")

    # Regular expression for frame and list of active triphones
    active_triphone_frame_list_re = re.compile((r"Activated phone models for frame "
                                                r"(?P<frameid>[0-9]+) "
                                                r"\([0-9]+\) : (?P<triphonelist>.+)$"))

    word_data = dict()

    # None value will be replaced by each word as it is read from the input stream
    current_word = None

    current_word_data = dict()

    # Start reading from the input file
    with open(input_filename, encoding="utf-8") as input_file:
        # Go through the file line by line
        for line in input_file:
            word_path_match = word_path_re.match(line)
            active_triphone_frame_match = active_triphone_frame_list_re.match(line)

            # So what's up with this line?

            if word_path_match:
                # We've matched a new word path.
                # My regular expression wasn't smart enough to get the actual
                # word out, so we can do that here.
                word_path = word_path_match.group('wordpath')
                word_file = word_path.split('/')[-1]
                word_name = word_file.split('.')[0]

                # If there is already a previous word being remembered, we want
                # to store all the appropriate data before we start on a new
                # word
                if current_word is not None:
                    word_data[current_word] = current_word_data

                # Now that everything we were trying to remember is written
                # down, we can start a new page
                current_word = word_name
                current_word_data = dict()

            elif active_triphone_frame_match:
                # TODO: only need to do this if we're under the frame cap!
                # We've matched the list of active triphones for a given frame.
                frame_id = active_triphone_frame_match.group('frameid')
                triphone_list = active_triphone_frame_match.group('triphonelist').split(' ')

                # We add what we've got to the current word's data
                current_word_data[current_word][frame_id] = triphone_list

    # When the file is over, we just have to store the last word's data and
    # we're done
    word_data[current_word] = current_word_data

    return word_data


# noinspection PyUnusedLocal
def process_args(switches, parameters, commands):
    """
    Gets relevant info from switches, parameters and commands
    :param switches:
    :param parameters:
    :param commands:
    :return:
    """
    # TODO
    usage_text = (
        ""
    )

    silent = "S" in switches
    log = "l" in switches

    input_file = get_parameter(parameters, "input", True, usage_text)
    output_file = get_parameter(parameters, "output", True, usage_text)

    frames = get_parameter(parameters, "frames", usage_text=usage_text)

    # set defaults
    frames = frames if frames != "" else 20 # default of 20

    return silent, log, input_file, output_file, frames


def main(argv):
    (switches, parameters, commands) = parse_args(argv)
    (silent, log, input_file, output_file, c_list, d_list, a_list, frames) = process_args(switches, parameters, commands)

if __name__ == "__main__":
   with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main(sys.argv)
