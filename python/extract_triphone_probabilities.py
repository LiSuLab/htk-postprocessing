# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import re

import numpy
import scipy
import scipy.io

from cw_common import *


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
    Want to return a word-keyed dictionary of frame_id-keyed dictionaries of lists of triphone-probability pairs.
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
    frame_data_re = re.compile((r"Activated phone models for frame "
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
        prints("Getting triphone lists from {0}...".format(input_filename))

    # Start reading from the input file
    with open(input_filename, encoding="utf-8") as input_file:
        # Go through the file line by line
        for line in input_file:
            word_path_match = word_path_re.match(line)
            frame_data_match = frame_data_re.match(line)

            # So what's up with this line we've just read?

            if word_path_match:
                # We've matched a new word path.
                # My regular expression wasn't smart enough to get the actual
                # word out, so we can do that here.
                word_path = word_path_match.group('word_path')
                word_file = word_path.split('/')[-1]
                word_name = word_file.split('.')[0]

                if not silent:
                    prints("")

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

            elif frame_data_match:
                # We've matched the list of active triphones for a given frame.
                frame_id = frame_data_match.group('frame_id')

                # If the frame_id we've extracted is larger than our
                # user-specified cap, we can skip this one.
                # Frames from HVite are 1-indexed.
                if int(frame_id) > int(frame_cap):
                    continue

                # Otherwise continue to break down the list of triphones which
                # my regular expression wasn't smart enough to get individually
                triphones = frame_data_match.group('triphone_probability_pair_list').split(' ')

                triphone_probability_pairs = list(map(
                    split_probability_triphone_pair,
                    triphones
                ))

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

    extant_triphones = "extant-triphones" in commands

    # set defaults
    frame_cap = frame_cap if frame_cap != "" else 20 # default of 20

    return silent, log, input_filename, output_dir, wordlist_filename, frame_cap, extant_triphones


def triphone_to_phone_triplet(triphone):
    """
    Given a triphone like x1-x2+x3, returns a phone triplet like [x1, x2, x3].
    :param triphone:
    :return:
    """
    return triphone.replace('-', ' ').replace('+', ' ').split(' ')


def apply_triphone_count_model(words_data, word_list, phone_list, frame_cap, silent):
    """
    The active triphone count model will be calculated as follows.

    - There will be one model for each phone.
    - The models will give, for each frame and each words, a count of the
      active triphones with the current phone as the centre phone.

    So to be returned is a phone-keyed dictionary of word-keyed dictionary of
    frame-indexed count vertors.

    :param phone_list:
    :param silent:
    :param frame_cap:
    :param word_list:
    :param words_data:
    """

    if not silent:
        prints("Applying active triphone model...")

    # Prepare the dictionary
    phones_data = dict()
    for phone in phone_list:
        phones_data[phone] = dict()
        for word in word_list:
            # The first frame is ignored, because there are only active
            # triphones from the second frame (the first is apparently
            # constrained to be silence).  So we subtract 1.
            phones_data[phone][word] = zeros(int(frame_cap) - 1)

    # Now we go through each word in turn
    for word in word_list:

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

                phone_triplet = triphone_to_phone_triplet(triphone)

                if len(phone_triplet) != 3:
                    raise ApplicationError("word:{0} triphone:{1}, frame_id:{2}".format(word, triphone, frame_id))

                # increment the count for the center phone
                phones_data[phone_triplet[1]][word][frame-2] += 1

    return phones_data


def deal_triphones_by_phone(list_of_extant_triphones):
    """
    Given list of triphones, returns a phone-keyed dictionary of triphones with the key as the central phone.
    :param list_of_extant_triphones:
    """
    phone_dictionary = dict()
    for triphone in list_of_extant_triphones:
        # Skip these erroneous entries
        if triphone == '' or triphone == 'sil' or triphone == 'sp':
            continue

        central_phone = triphone_to_phone_triplet(triphone)[1]
        if central_phone in phone_dictionary.keys():
            phone_dictionary[central_phone] += [triphone]
        else:
            phone_dictionary[central_phone] = [triphone]

    return phone_dictionary


def apply_triphone_vector_model(words_data, word_list, list_of_extant_triphones, frame_cap, silent):
    """
    The active triphone vector model will be calculated as follows.

    - There will be one model for each phone.
    - The models will give, for each frame and each words, a vector of the
      active triphones with the current phone as the centre phone.  Only
      triphones which are ever present will be considered.

    So to be returned is a phone-keyed dictionary of word-keyed dictionaries of
    frame-by-triphone binary arrays.

    :param list_of_extant_triphones:
    :param silent:
    :param frame_cap:
    :param word_list:
    :param words_data:
    """

    if not silent:
        prints("Applying active triphone model...")

    triphones_per_phone = deal_triphones_by_phone(list_of_extant_triphones)

    # Prepare the dictionary
    phones_data = dict()
    # Use keys here because some phones (eg 'ax' for Lexpro) may not be present
    for phone in triphones_per_phone.keys():

        # Add the key to the dictionary
        phones_data[phone] = dict()

        for word in word_list:
            # Initialise the data for this phone with a frames-by-triphones matrix.
            # These matrices will be different sizes for each word.
            # We subtract 1 from the frames because there are only active triphones
            # in the second frame (the first is apparently constrained to be silence.

            # First make a 2-d list as appropriate
            phones_data[phone][word] = numpy.zeros((int(frame_cap) - 1, len(triphones_per_phone[phone])))

    # Now that we've preallocated, we go through each word in turn
    for word in word_list:

        # In the transcript from HVite, the first frame is numbered "frame 1"
        # and it is apparently constrained to be silence.  There are only
        # active triphones from frame 2 onwards.
        # So, we start at 2 (because that's where the data is) and we add 1
        # (because the frames are 1-indexed).
        for frame in range(2, int(frame_cap) + 1):
            frame_id = str(frame)

            # The list of triphones for this word this frame
            triphone_list = words_data[word][frame_id]

            for phone in triphones_per_phone.keys():

                # For each possible triphone containing this phone...
                for triphone_i in range(0, len(triphones_per_phone[phone])):
                    triphone = triphones_per_phone[phone][triphone_i]

                    # ...if it's active for this frame for this word...
                    if triphone in triphone_list:
                        # ...we give it a 1...
                        phones_data[phone][word][frame-2][triphone_i] = 1
                        # ...otherwise it stays a 0

    return phones_data


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

    # We'll use a set so we can just add new items without checking if they're already there each time
    list_of_extant_triphones = set()

    # Now we go through each word in turn
    for word in local_word_list_copy:

        if not silent:
            prints("Processing {0}".format(word))

        # In the transcript from HVite, the first frame is numbered "frame 1"
        # and it is apparently constrained to be silence.  There are only
        # active triphones from frame 2 onwards.
        # So, we start at 2 (because that's where the data is) and we add 1
        # (because the frames are 1-indexed).
        for frame in range(2, int(frame_cap) + 1):
            frame_id = str(frame)

            triphone_list = words_data[word][frame_id]

            for triphone in triphone_list:
                # We don't care about some of them.
                # todo: this particular couple of lines is repeated rather a lot
                if triphone == '' or triphone == 'sil' or triphone == 'sp':
                    continue
                list_of_extant_triphones.add(triphone)

    return list(list_of_extant_triphones)


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

    word_list = list(get_word_list(wordlist_filename, silent))
    word_data = get_triphone_probability_lists(input_filename, frame_cap, silent)

    PHONE_LIST = ["sil", "sp", "ax", "k", "ao", "d", "ia", "n", "ae", "r", "b", "t", "ea", "p", "l", "ey", "ih", "g", "m", "y", "uh", "s", "ng", "aa", "ow", "sh", "eh", "zh", "iy", "v", "ch", "jh", "ay", "uw", "th", "z", "hh", "er", "oh", "ah", "aw", "oy", "dh", "f", "ua", "w"]

    list_of_extant_triphones = look_for_extant_triphones(word_data, word_list, frame_cap, silent)

    phones_data = apply_triphone_vector_model(word_data, word_list, list_of_extant_triphones, frame_cap, silent)
    save_features(phones_data, output_dir, silent)

    if not silent:
        prints("==== DONE! =======")

# Boilerplate
if __name__ == "__main__":
    # Log to file
    with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main(sys.argv)
