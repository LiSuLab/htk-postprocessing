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
    of triphone-keyed dicttionaries of likelihood values.

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
                    prints("Getting triphone lists for '{0}'...".format(word_name))

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
                triphones = list(filter(
                    lambda t: t != "",
                    triphones))

                triphone_probability_pairs = list(map(
                    split_probability_triphone_pair,
                    triphones))

                # We add what we've got to the current word's data
                current_word_data[frame_id] = dict()
                for tpp in triphone_probability_pairs:
                    current_word_data[frame_id][tpp[0]] = tpp[1]

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


def apply_triphone_probability_model(triphone_probability_lists, word_list, PHONE_LIST, used_triphones, frame_cap, silent):
    """
    The active triphone vector model will be calculated as follows.

    - There will be one model for each phone.
    - The models will give, for each frame and each words, a vector of the
      active triphone probabilities, for triphones with the current phone
      as the centre phone.  Only triphones which are present for every word in
    each frame will be considered.

    So to be returned is a frame_id-keyed dictionary of phone-keyed dictionaries
    of word-by-triphone probability matrices.

    :param PHONE_LIST:
    :param used_triphones:
    :param silent:
    :param frame_cap:
    :param word_list:
    :param triphone_probability_lists:
    """

    # In the transcript from HVite, the first frame is numbered "frame 1"
    # and it is apparently constrained to be silence.  There are only
    # active triphones from frame 2 onwards.
    # So, we start at 2 (because that's where the data is) and we add 1
    # (because the frames are 1-indexed).
    likelihood_data = dict()
    for frame in range(2, int(frame_cap) + 1):
        frame_id = str(frame)

        if not silent:
            prints('Applying triphone probability model in frame {0}...'.format(frame))

        likelihood_data[frame_id] = dict()

        triphones_used_this_frame = used_triphones[frame_id]
        triphones_per_phone = deal_triphones_by_phone(triphones_used_this_frame)

        for phone in PHONE_LIST:

            # Not all phones may be present at ever frame, in which
            # case we just return an empty list.
            triphones_this_phone = triphones_per_phone.get(phone, [])

            if len(triphones_this_phone) > 0:
                likelihood_data[frame_id][phone] = numpy.empty((
                    len(word_list),
                    len(triphones_this_phone)))
                likelihood_data[frame_id][phone][:] = numpy.nan

                for word_i in range(0, len(word_list)):
                    word = word_list[word_i]

                    for triphone_i in range(0, len(triphones_this_phone)):
                        triphone = triphones_this_phone[triphone_i]
                        # Get the likelihood out of the words data
                        likelihood_data[frame_id][phone][word_i][triphone_i] = triphone_probability_lists[word][frame_id][triphone]
            else:
                # If there are no triphones for this phone, we just list some
                # nans, so it can at least be detected later.
                likelihood_data[frame_id][phone] = numpy.empty((
                    len(word_list),
                    1))
                likelihood_data[frame_id][phone][:] = numpy.nan

    return likelihood_data


def which_triphones_are_used(triphone_probability_lists, word_list, frame_cap, silent):
    """
We want probability feature vectors.  Therefore, we need to ensure that we are
looking in a common set of triphones for each pair of words for each frame.

This function will return a frame_id-keyed dictionary lists of triphones.

    :param triphone_probability_lists:
    :param word_list:
    :param frame_cap:
    :param silent:
    :return: :raise ApplicationError:
    """

    # I guess lazy instantiation wasn't so smart :[
    local_word_list = list(word_list)

    used_triphones = dict()

    # In the transcript from HVite, the first frame is numbered
    # "frame 1" and it is apparently constrained to be silence.
    # There are only active triphones from frame 2 onwards.
    # So, we start at 2 (because that's where the data is) and we add 1
    # (because the frames are 1-indexed).
    for frame in range(2, int(frame_cap) + 1):
        frame_id = str(frame)

        if not silent:
            prints("Looking for triphones used in frame {0}...".format(frame_id))

        triphone_list = None

        # Now we go through each word in turn
        for word in local_word_list:
            triphones = list(triphone_probability_lists[word][frame_id].keys())
            triphones = filter(
                lambda triphone: triphone != '' and triphone != 'sil' and triphone != 'sp',
                triphones)

            # For the first word, we will just take the list of triphones as is
            if triphone_list is None:
                triphone_list = triphones
            # For the rest of the words we will intersect the list of triphones
            # so that by the end of it we only have triphones common to ALL
            # words.
            else:
                triphone_list = list(set(triphone_list).intersection(set(triphones)))

        used_triphones[frame_id] = triphone_list

    return used_triphones


def save_features(likelihood_data, PHONE_LIST, output_dir, frame_cap, silent=False):
    """
    Saves the data in a Matlab-readable format.
    This will be a phone-keyed dictionary of
    :param likelihood_data:
    :param PHONE_LIST:
    :param output_dir:
    :param frame_cap:
    :param silent:
    """

    if not silent:
        prints("Saving features to {0}".format(output_dir))

    for frame in range(2, int(frame_cap) + 1):
        frame_id = str(frame)
        scipy.io.savemat(
            os.path.join(
                output_dir,
                "{0:02d}".format(frame)),
            # savemat requires a dictionary here
            likelihood_data[frame_id],
            appendmat=True)


def main(argv):
    """
    Do dat analysis.
    :param argv:
    """
    # We will specifically ignore some of the phones, as we know there is not
    # enough data
    #region PHONE_LIST = [ ... ]
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
    #endregion

    (switches, parameters, commands) = parse_args(argv)
    (silent, log, input_filename, output_dir, wordlist_filename, frame_cap) = process_args(switches, parameters, commands)

    if not silent:
        prints("==================")

    word_list = list(get_word_list(wordlist_filename, silent))

    triphone_probability_lists = get_triphone_probability_lists(input_filename, frame_cap, silent)

    used_triphones = which_triphones_are_used(triphone_probability_lists, word_list, frame_cap, silent)

    likelihood_data = apply_triphone_probability_model(triphone_probability_lists, word_list, PHONE_LIST, used_triphones, frame_cap, silent)
    
    save_features(likelihood_data, PHONE_LIST, output_dir, frame_cap, silent)

    if not silent:
        prints("==== DONE! =======")

# Boilerplate
if __name__ == "__main__":
    # Log to file
    # with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
    #     main(sys.argv)
    # Don't log to file
    main(sys.argv)
