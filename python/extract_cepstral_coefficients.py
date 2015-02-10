# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import re
import scipy
import scipy.io

from cw_common import *


def filter_coefficients_from_htk(input_filename, word_list, c_list, d_list, a_list, frame_cap, silent):
    """
    Main function.

    Returns a coefficient_id-keyed dictionary of word-keyed dictionaries of
    frame-indexed lists of coefficient values.

    :param input_filename:
    :param word_list:
    :param c_list:
    :param d_list:
    :param a_list:
    :param frame_cap:
    :param silent:
    """

    #region Regular expressions...

    # Regular expression for name of a word
    word_name_re = re.compile(r"^-+ Source: (?P<wordname>[a-z]+)\.wav -+$")

    # Regular expression for all coefficients for a given frame
    frame_vector_re = re.compile((r"^(?P<frameid>[0-9]+): +"
                                  r"(?P<C01>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C02>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C03>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C04>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C05>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C06>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C07>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C08>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C09>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C10>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C11>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C12>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<C00>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D01>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D02>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D03>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D04>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D05>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D06>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D07>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D08>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D09>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D10>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D11>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D12>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<D00>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A01>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A02>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A03>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A04>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A05>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A06>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A07>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A08>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A09>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A10>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A11>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A12>-?[0-9]+\.[0-9]+) +"
                                  r"(?P<A00>-?[0-9]+\.[0-9]+) *$"))

    #endregion

    c_match_names = list(map(lambda c: "C{0}".format(str(c).zfill(2)), c_list))
    d_match_names= list(map(lambda d: "D{0}".format(str(d).zfill(2)), d_list))
    a_match_names = list(map(lambda a: "A{0}".format(str(a).zfill(2)), a_list))

    # All coefficient names
    all_coeff_names = c_match_names + d_match_names + a_match_names

    # Prepare dictionaries of outputs.
    coeffs = dict()
    for coeff_name in all_coeff_names:
        coeffs[coeff_name] = dict()
        for word in word_list:
            coeffs[coeff_name][word] = Nones(frame_cap)

    this_word = None

    # Start reading from the input file
    with open(input_filename, encoding="utf-8") as input_file:
        for line in input_file:
            word_name_match = word_name_re.match(line)
            frame_vector_match = frame_vector_re.match(line)

            if word_name_match:
                # Matched a word name.
                # Remember which word we're currently looking at
                this_word = word_name_match.group('wordname')
                if not silent:
                    prints(this_word)

            # If we've read a word name, but it's not one we're interested in,
            # we can skip lines until we find one we are interested in.
            elif this_word is not None and this_word not in word_list:
                continue

            elif frame_vector_match:
                # Matched a frame fector
                frame_id = frame_vector_match.group('frameid')
                frame = int(frame_id)

                # If we've gone over the cap, we're not interested so can skip
                # this line.
                if frame >= frame_cap:
                    continue

                # Get the requested coefficients
                for coeff_name in all_coeff_names:
                    this_coeff = frame_vector_match.group(coeff_name)
                    coeffs[coeff_name][this_word][frame] = float(this_coeff)
    return coeffs

def transform_and_save(output_dirname, coeffs):
    """
    Saves in the specified output directory a words-keyed struct of frame-indexed lists of coefficients for each
    coefficient name.

    :param output_dirname:
    :param coeffs: a coefficient_id-keyed dictionary of word-keyed dictionaries
                   of frame-indexed lists of coefficient values
    """

    for coeff_name in coeffs.keys():
        file_name = "cepstral-coefficients-{0}.mat".format(coeff_name)
        save_path = os.path.join(output_dirname, file_name)
        scipy.io.savemat(save_path, coeffs[coeff_name], appendmat=False)


def get_words(words_filename):
    """
    Reads a list of words from a text file.
    :param words_filename:
    :return:
    """
    with open(words_filename, encoding="utf-8") as words_file:
        lines = words_file.readlines()
        # Don't want the newlines at the end
        return [line.rstrip("\n") for line in lines]

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
        "python extract_cepstral_coefficients "
        "input=<input-path> "
        "output=<output-path> "
        "words=<word-list-path>"
        "C=<CC-list> "
        "D=<DC-list> "
        "A=<AC-list> "
        "frames=<frames|20>"
    )

    silent = "S" in switches

    input_filename = get_parameter(parameters, "input", True, usage_text)
    output_dirname = get_parameter(parameters, "output", True, usage_text)
    words_filename = get_parameter(parameters, "words", True, usage_text)

    c_list = get_parameter(parameters, "C", usage_text=usage_text).split(",")
    d_list = get_parameter(parameters, "D", usage_text=usage_text).split(",")
    a_list = get_parameter(parameters, "A", usage_text=usage_text).split(",")

    # Correct for empty args
    if c_list[0] == "":
        c_list = []
    if d_list[0] == "":
        d_list = []
    if a_list[0] == "":
        a_list = []

    # But if they're all empty, we have defaults
    if (len(c_list) == 0) and (len(d_list) == 0) and (len(a_list) == 0):
        c_list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        d_list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        a_list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

    frame_cap = get_parameter(parameters, "frames", usage_text=usage_text)

    # set defaults
    frame_cap = frame_cap if frame_cap != "" else 20 # default of 20

    return silent, input_filename, output_dirname, words_filename, c_list, d_list, a_list, frame_cap


def main(argv):
    """
    Run the analysis
    :param argv:
    """
    (switches, parameters, commands) = parse_args(argv)
    (silent, input_filename, output_dirname, words_filename, c_list, d_list, a_list, frames) = process_args(switches, parameters, commands)
    word_list = get_words(words_filename)
    coeffs = filter_coefficients_from_htk(input_filename, word_list, c_list, d_list, a_list, frames, silent)
    transform_and_save(output_dirname, coeffs)

#region if __name__ == "__main__": ...

if __name__ == "__main__":
   with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main(sys.argv)

#endregion
