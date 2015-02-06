# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import re

import scipy
import scipy.io

from cw_common import *


def get_triphone_lists(input_filename, frame_cap, silent):

    # Regular expression for the path of a word
    """
    Want to retun a word-keyed dictionary of frame_id-keyed dictionaries of triphone lists.
    :param input_filename:
    :param frame_cap:
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

                # Feedback
                if not silent:
                    prints(word_name)

            elif active_triphone_frame_match:
                # We've matched the list of active triphones for a given frame.
                frame_id = active_triphone_frame_match.group('frameid')

                # If the frame_id we've extracted is larger than our
                # user-specified cap, we can skip this one.
                if int(frame_id) >= frame_cap:
                    continue

                # Otherwise continue to break down the list of triphones which
                # my regular expression wasn't smart enough to get individually
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

    input_filename = get_parameter(parameters, "input", True, usage_text)
    output_filename = get_parameter(parameters, "output", True, usage_text)
    wordlist_filename = get_parameter(parameters, "words", True, usage_text)

    frame_cap = get_parameter(parameters, "frames", usage_text=usage_text)

    # set defaults
    frame_cap = frame_cap if frame_cap != "" else 20 # default of 20

    return silent, log, input_filename, output_filename, wordlist_filename, frame_cap


def apply_active_triphone_model(words_data, word_list, frame_cap):
    """
    The active triphone model will be calculated as follows.

    - There will be one model for each phone.
    - The models will give, for each frame and each words, a count of the
      active triphones with the current phone as the centre phone.

    So to be returned is a phone-keyed dictionary of frame_id-keyed
    dictionaries of word-keyed dictionaries of counts

    :param frame_cap:
    :param word_list:
    :param words_data:
    """
    phone_list = ["sil", "sp", "ax", "k", "ao", "d", "ia", "n", "ae", "r", "b", "t", "ea", "p", "l", "ey", "ih", "g", "m", "y", "uh", "s", "ng", "aa", "ow", "sh", "eh", "zh", "iy", "v", "ch", "jh", "ay", "uw", "th", "z", "hh", "er", "oh", "ah", "aw", "oy", "dh", "f", "ua", "w"]

    phones_data = dict()

    for phone in phone_list:

        frames_data = dict()

        for frame in range(frame_cap):
            frame_id = str(frame)

            for word in word_list:

                triphone_list = words_data[word][frame_id]

                count = 0
                for triphone in triphone_list:

                    phone_triplet = triphone.replace('-', ' ').replace('+', ' ').split(' ')

                    if phone_triplet == phone:
                        count += 1

                words_data[word] = count

            frames_data[frame_id] = words_data

        phones_data[phone] = frames_data

    return phones_data


def get_word_list(wordlist_filename):
    """
    Returns a list of all the (newline-separated) words in the wordlist file.
    :param wordlist_filename:
    """
    with open(wordlist_filename, encoding="utf-8") as word_list_file:
        for word in word_list_file:
            yield word


def save_features(phones_data, output_filename):
    """
    Saves the data in a Matlab-readable format.
    This will be a phone-keyed dictionary of
    :param phones_data:
    :param output_filename:
    """
    scipy.io.savemat(output_filename, phones_data, appendmat=False)
    # for phone, frames_data in phones_data:
    #     for frame_id, words_data in frames_data:
    #         for word, count in words_data:


def main(argv):
    """
    Do dat analysis.
    :param argv:
    """
    (switches, parameters, commands) = parse_args(argv)
    (silent, log, input_filename, output_filename, wordlist_filename, frame_cap) = process_args(switches, parameters, commands)
    word_list = get_word_list(wordlist_filename)
    word_data = get_triphone_lists(input_filename, frame_cap, silent)
    phones_data = apply_active_triphone_model(word_data, word_list, frame_cap)
    save_features(phones_data, output_filename)

if __name__ == "__main__":
   with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main(sys.argv)
