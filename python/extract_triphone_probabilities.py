# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import re

import numpy
import scipy
import scipy.io

from htk_extraction_tools import *


def split_probability_triphone_pair(ptp):
    """
    Splits a string like "-1.398829e+02|sil-b+ia" into a pair
    [-139.8829, "sil-b-ia"].
    :param ptp:
    :return:
    """
    pair = ptp.split("|")
    triphone = pair[1]
    probability = float(pair[0])
    return [triphone, probability]


def get_triphone_probability_lists(input_filename, frame_cap, silent):
    """
    Want to return a word-keyed dictionary of frame_id-keyed dictionaries
    of lists of triphone-probability pairs.
    A triphone looks like xx-xx+xx.

    Expect this to be working on the output of the new version of `HVite`.
    On a file called something like `hv.trace`.

    :param input_filename:
    :param frame_cap:
    :param silent:
    """

    # Regular expression for the path of a word
    word_path_re = re.compile(r"^File: (?P<word_path>.+)\.mfc$")

    # Regular expression for frame and list of active triphones
    frame_data_re = re.compile((
        r"Activated phone models for frame "
        # The frame number
        r"(?P<frame_id>[0-9]+) "
        # The count in parentheses (we don't care about this)
        r"\([0-9]+\) : "
        # The list of triphone-probability pairs
        r"(?P<triphone_probability_pair_list>.+)$"))

    word_data = dict()

    # None value will be replaced by each word as it is read from the input stream
    current_word = None

    current_word_data = dict()

    if not silent:
        prints("Getting triphone probability vectors from {0}...".format(input_filename))

    # Start reading from the input file
    with open(input_filename, encoding="utf-8") as input_file:
        # Go through the file line by line
        for line in input_file:
            word_path_match = word_path_re.match(line)
            frame_data_match = frame_data_re.match(line)

            # So what's up with this line we've just read?

            if word_path_match:
                # We've matched a new word path.
                # My regular expression wasn't smart enough to get the
                # actual word out, so we can do that here.
                word_path = word_path_match.group('word_path')
                word_file = word_path.split('/')[-1]
                word_name = word_file.split('.')[0]

                if not silent:
                    print("")

                # If there is already a previous word being remembered, we
                # want to store all the appropriate data before we start
                # on a new word
                if current_word is not None:
                    word_data[current_word] = current_word_data

                # Now that everything we were trying to remember is written
                # down, we can start a new page
                current_word = word_name
                current_word_data = dict()

                # Feedback
                if not silent:
                    prints("Getting triphone lists for '{0}'".format(word_name), end="")

            elif frame_data_match:
                # We've matched the list of active triphones for a given
                # frame.
                frame_id = frame_data_match.group('frame_id')

                # If the frame_id we've extracted is larger than our
                # user-specified cap, we can skip this one.
                # Frames from HVite are 1-indexed.
                if int(frame_id) > int(frame_cap):
                    continue

                # Otherwise continue to break down the list of triphones
                # which my regular expression wasn't smart enough to get
                # individually
                triphones = frame_data_match.group('triphone_probability_pair_list').split(' ')

                # Filter out any empty ones which may have crept in from
                # splitting on the space.
                triphones = filter(
                    lambda t: t != "",
                    triphones)

                triphone_probability_pairs = list(map(
                    split_probability_triphone_pair,
                    triphones))

                # We add what we've got to the current word's data
                current_word_data[frame_id] = triphone_probability_pairs

                if not silent:
                    print(".", end="")

    # When the file is over, we just have to store the last word's data and
    # we're done
    word_data[current_word] = current_word_data
    if not silent:
        print("") # For the newline

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

    # set defaults
    frame_cap = frame_cap if frame_cap != "" else 20 # default of 20

    return silent, log, input_filename, output_dir, wordlist_filename, frame_cap


def apply_triphone_probability_model(words_data, word_list, list_of_extant_triphones, frame_cap, silent):
    """
    The active triphone vector model will be calculated as follows.

    - There will be one model for each phone.
    - The models will give, for each frame and each words, a vector of the
      active triphone probabilities, for triphones with the current phone
      as the centre phone.  Only triphones which are ever present will be
      considered.

    So to be returned is a phone-keyed dictionary of word-keyed
    dictionaries of frame-by-triphone vectors.

    :param list_of_extant_triphones:
    :param silent:
    :param frame_cap:
    :param word_list:
    :param words_data:
    """

    # We will specifically ignore some of the phones, as we know there is not
    # enough data
    PHONE_LIST = [
    #    "sil",
    #    "sp",
        "aa",
        "ae",
        "ah",
        "ao",
        "aw",
    #    "ax",
        "ay",
        "b",
        "ch",
        "d",
    #    "dh",
        "ea",
        "eh",
        "er",
        "ey",
        "f",
        "g",
        "hh",
        "ia",
        "ih",
        "iy",
        "jh",
        "k",
        "l",
        "m",
        "n",
        "ng",
        "oh",
        "ow",
        "oy",
        "p",
        "r",
        "s",
        "sh",
        "t",
        "th",
    #    "ua",
        "uh",
        "uw",
        "v",
        "w",
        "y",
        "z",
    #    "zh",
    ]

    triphones_per_phone = deal_triphones_by_phone(list_of_extant_triphones)

    # Prepare the dictionary
    phones_data = dict()

    for phone in PHONE_LIST:

        # Add the key to the dictionary
        phones_data[phone] = dict()

        for word in word_list:
            # Initialise the data for this phone with a frames-by-triphones
            # matrix. These matrices will be different sizes for each word.
            # We subtract 1 from the frames because there are only active
            # triphones in the second frame (the first is apparently
            # constrained to be silence.

            # First make a 2-d list as appropriate.
            # NaNs will stand for missing data.  So if there's a triphone
            # which exists somewhere, but not for this word or timeframe,
            # then we give it a nan rather than a specific number.
            phones_data[phone][word] = numpy.empty((
                int(frame_cap) - 1,
                len(triphones_per_phone[phone])))
            phones_data[phone][word][:] = numpy.NAN

    # Now that we've preallocated, we go through each word in turn
    for word in word_list:

        if not silent:
            prints("Applying triphone probability model for {0}...".format(word))

        # In the transcript from HVite, the first frame is numbered "frame 1"
        # and it is apparently constrained to be silence.  There are only
        # active triphones from frame 2 onwards.
        # So, we start at 2 (because that's where the data is) and we add 1
        # (because the frames are 1-indexed).
        for frame in range(2, int(frame_cap) + 1):
            frame_id = str(frame)

            # The list of triphones for this word this frame
            triphone_probability_pairs = words_data[word][frame_id]

            for phone in PHONE_LIST:

                # For each possible triphone containing this phone...
                for triphone_i in range(0, len(triphones_per_phone[phone])):
                    triphone = triphones_per_phone[phone][triphone_i]

                    # We find the triphone-probability pair for this
                    # triphone.
                    triphone_probability_pair = get_first(
                        filter(
                            lambda tpp: tpp[0].casefold() == triphone.casefold(),
                            triphone_probability_pairs),
                        default=None)

                    # It's possible that the triphone wasn't present, in
                    # which case the value in the array should stay as
                    # NaN.
                    if triphone_probability_pair:
                        phones_data[phone][word][frame-2][triphone_i] = triphone_probability_pair[1]

    return phones_data


# TODO: documentation for this function
def look_for_extant_triphones(words_data, word_list, frame_cap, silent):
    """

    :param words_data:
    :param word_list:
    :param frame_cap:
    :param silent:
    :return: :raise ApplicationError:
    """

    if not silent:
        prints("Counting extant triphones...")

    # I guess lazy instantiation wasn't so smart :[
    local_word_list_copy = list(word_list)

    # We'll use a set so we can just add new items without checking if
    # they're already there each time
    list_of_extant_triphones = set()

    # Now we go through each word in turn
    for word in local_word_list_copy:

        if not silent:
            prints("Processing {0}".format(word))

        # In the transcript from HVite, the first frame is numbered
        # "frame 1" and it is apparently constrained to be silence.
        # There are only active triphones from frame 2 onwards.
        # So, we start at 2 (because that's where the data is) and we add 1
        # (because the frames are 1-indexed).
        for frame in range(2, int(frame_cap) + 1):
            frame_id = str(frame)

            triphone_probability_pair_list = words_data[word][frame_id]

            for triphone_probability_pair in triphone_probability_pair_list:
                triphone = triphone_probability_pair[0]
                # We don't care about some of them.
                # todo: this particular couple of lines is repeated rather
                # todo: a lot
                if triphone == '' or triphone == 'sil' or triphone == 'sp':
                    continue
                list_of_extant_triphones.add(triphone)

    return list(list_of_extant_triphones)


def save_features(phones_data, output_dir, silent=False):
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
        scipy.io.savemat("{1}triphone_likelihood_model-{0}".format(phone, output_dir), this_phone_data, appendmat=True)


def main(argv):
    """
    Do dat analysis.
    :param argv:
    """

    (switches, parameters, commands) = parse_args(argv)
    (silent, log, input_filename, output_dir, wordlist_filename, frame_cap) = process_args(switches, parameters, commands)

    if not silent:
        prints("==================")

    word_list = list(get_word_list(wordlist_filename, silent))
    word_data = get_triphone_probability_lists(input_filename, frame_cap, silent)

    list_of_extant_triphones = look_for_extant_triphones(word_data, word_list, frame_cap, silent)

    phones_data = apply_triphone_probability_model(word_data, word_list, list_of_extant_triphones, frame_cap, silent)
    save_features(phones_data, output_dir, silent)

    if not silent:
        prints("==== DONE! =======")

# Boilerplate
if __name__ == "__main__":
    # Log to file
    # with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
    #     main(sys.argv)
    # Don't log to file
    main(sys.argv)
