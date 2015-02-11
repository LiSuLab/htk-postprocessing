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

    if not silent:
        prints("Getting triphone lists from {0}...".format(input_filename))

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

                if not silent:
                    print("")

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
                    prints("Getting triphone lists for '{0}'".format(word_name), end="")

            elif active_triphone_frame_match:
                # We've matched the list of active triphones for a given frame.
                frame_id = active_triphone_frame_match.group('frameid')

                # If the frame_id we've extracted is larger than our
                # user-specified cap, we can skip this one.
                # We add 1 because frames from HVite are 1-indexed.
                if int(frame_id) >= int(frame_cap) + 1:
                    continue

                # Otherwise continue to break down the list of triphones which
                # my regular expression wasn't smart enough to get individually
                triphone_list = active_triphone_frame_match.group('triphonelist').split(' ')

                # We add what we've got to the current word's data
                current_word_data[frame_id] = triphone_list

                if not silent:
                    print(".", end="")

    # When the file is over, we just have to store the last word's data and
    # we're done
    word_data[current_word] = current_word_data
    if not silent:
        print("")

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
    output_dir = get_parameter(parameters, "output", True, usage_text)
    wordlist_filename = get_parameter(parameters, "words", True, usage_text)

    frame_cap = get_parameter(parameters, "frames", usage_text=usage_text)

    extant_triphones = "extant-triphones" in commands

    # set defaults
    frame_cap = frame_cap if frame_cap != "" else 20 # default of 20

    return silent, log, input_filename, output_dir, wordlist_filename, frame_cap, extant_triphones


def apply_active_triphone_model(words_data, word_list, frame_cap, silent):
    """
    The active triphone model will be calculated as follows.

    - There will be one model for each phone.
    - The models will give, for each frame and each words, a count of the
      active triphones with the current phone as the centre phone.

    So to be returned is a phone-keyed dictionary of word-keyed dictionary of
    frame-indexed count vertors.

    :param silent:
    :param frame_cap:
    :param word_list:
    :param words_data:
    """
    phone_list = ["sil", "sp", "ax", "k", "ao", "d", "ia", "n", "ae", "r", "b", "t", "ea", "p", "l", "ey", "ih", "g", "m", "y", "uh", "s", "ng", "aa", "ow", "sh", "eh", "zh", "iy", "v", "ch", "jh", "ay", "uw", "th", "z", "hh", "er", "oh", "ah", "aw", "oy", "dh", "f", "ua", "w"]

    if not silent:
        prints("Applying active triphone model...")

    local_word_list_copy = list(word_list)

    # Prepare the dictionary
    phones_data = dict()
    for phone in phone_list:
        phones_data[phone] = dict()
        for word in local_word_list_copy:
            # The first frame is ignored, because there are only active
            # triphones from the second frame (the first is apparently
            # constrained to be silence).  So we subtract 1.
            phones_data[phone][word] = zeros(int(frame_cap) - 1)

    # Now we go through each word in turn
    for word in local_word_list_copy:

        # In the transcript from HVite, the first frame is numbered "frame 1"
        # and it is apparently constrained to be silence.  There are only
        # active triphones from frame 2 onwards.
        # So, we start at 2 (because that's where the data is) and we add 1
        # (because the frames are 1-indexed).
        for frame in range(2, int(frame_cap) + 1):
            frame_id = str(frame)

            triphone_list = words_data[word][frame_id]

            for triphone in triphone_list:
                # Ignore empty triphones and triphones presented in isolation
                if triphone == '' or triphone == 'sil' or triphone == 'sp':
                    continue

                phone_triplet = triphone.replace('-', ' ').replace('+', ' ').split(' ')

                if len(phone_triplet) != 3:
                    raise ApplicationError("word:{0} triphone:{1}, frame_id:{2}".format(word, triphone, frame_id))

                # increment the count for the center phone
                phones_data[phone_triplet[1]][word][frame-2] += 1

    return phones_data


def get_word_list(wordlist_filename, silent):
    """
    Returns a list of all the (newline-separated) words in the wordlist file.
    :param silent:
    :param wordlist_filename:
    """

    if not silent:
        prints("\t[Lazily getting word list...]")

    with open(wordlist_filename, encoding="utf-8") as word_list_file:
        for word in word_list_file:
            yield word.strip()


def save_features(phones_data, output_dir, silent):
    """
    Saves the data in a Matlab-readable format.
    This will be a phone-keyed dictionary of
    :param silent:
    :param phones_data:
    :param output_dir:
    """

    if not silent:
        prints("Saving features to {0}".format(output_dir))

    for phone in phones_data.keys():
        this_phone_data = phones_data[phone]
        scipy.io.savemat("{1}active_triphone_model-{0}".format(phone, output_dir), this_phone_data, appendmat=True)


def main(argv):
    """
    Do dat analysis.
    :param argv:
    """

    (switches, parameters, commands) = parse_args(argv)
    (silent, log, input_filename, output_dir, wordlist_filename, frame_cap, extant_triphones) = process_args(switches, parameters, commands)

    if not silent:
        prints("==================")

    word_list = get_word_list(wordlist_filename, silent)
    word_data = get_triphone_lists(input_filename, frame_cap, silent)

    # Different commands for different analyses
    if extant_triphones:
        look_for_extant_triphones(word_data, word_list, frame_cap, silent)
    else:
        phones_data = apply_active_triphone_model(word_data, word_list, frame_cap, silent)
        save_features(phones_data, output_dir, silent)

    if not silent:
        prints("==== DONE! =======")

if __name__ == "__main__":
   with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main(sys.argv)
