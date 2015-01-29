# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import re

from cw_common import *


def filter_coefficients(input_filename, output_filename, c_list, d_list, a_list, frames, silent, log):
    """
    Main function.
    :param input_filename:
    :param output_filename:
    :param c_list:
    :param d_list:
    :param a_list:
    :param frames:
    :param silent:
    :param log: [currently unused]
    """

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

    c_list_match_names = list(map(lambda c: "C{0}".format(c.zfill(2)), c_list))
    d_list_match_names = list(map(lambda d: "D{0}".format(d.zfill(2)), d_list))
    a_list_match_names = list(map(lambda a: "A{0}".format(a.zfill(2)), a_list))

    # Start reading from the input file
    with open(input_filename, encoding="utf-8") as input_file:
        with open(output_filename, mode="w", encoding="utf-8") as output_file:
            for line in input_file:
                word_name_match = word_name_re.match(line)
                frame_vector_match = frame_vector_re.match(line)
                if word_name_match:
                    # Matched a new word name
                    # Write that word name in the output file
                    word_name = word_name_match.group('wordname')
                    output_file.write("{0}\n".format(word_name))
                    if not silent:
                        prints(word_name)

                elif frame_vector_match:
                    # Matched a frame vector line

                    frame_id = frame_vector_match.group("frameid")

                    # Only want to import if the frameid is less than the number of frames requested
                    if int(frame_id) < frames:
                        # Get the requested coefficients
                        c_coeffs = list(map(lambda c_match_name: frame_vector_match.group(c_match_name), c_list_match_names))
                        d_coeffs = list(map(lambda d_match_name: frame_vector_match.group(d_match_name), d_list_match_names))
                        a_coeffs = list(map(lambda a_match_name: frame_vector_match.group(a_match_name), a_list_match_names))

                        line_to_write = ""
                        line_to_write += frame_id
                        line_to_write += ":"
                        for coeff in c_coeffs + d_coeffs + a_coeffs:
                            line_to_write += coeff
                            line_to_write += ","
                        # remove trailing comma
                        line_to_write = line_to_write[:-1]
                        line_to_write += "\n"

                        output_file.write(line_to_write)

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
        ""
        "For example:"
        "python extract_cepstral_coefficients "
        "input=C:\\Users\\cai\\code\\cepstral-model\\HLIST39cepstral.pre.out "
        "output=C:\\Users\\cai\\code\\cepstral-model\\ProcessedResult.log "
        "C=0,1,2,3,4,5,6,7,8,9,10,11,12 "
        "D=0,1,2,3,4,5,6,7,8,9,10,11,12 "
        "A=0,1,2,3,4,5,6,7,8,9,10,11,12 "
        "frames=20"
    )

    silent = "S" in switches
    log = "l" in switches

    input_file = get_parameter(parameters, "input", True, usage_text)
    output_file = get_parameter(parameters, "output", True, usage_text)
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

    frames = get_parameter(parameters, "frames", usage_text=usage_text)

    # set defaults
    frames = frames if frames != "" else 20 # default of 20

    return silent, log, input_file, output_file, c_list, d_list, a_list, frames


def main(argv):
    (switches, parameters, commands) = parse_args(argv)
    (silent, log, input_file, output_file, c_list, d_list, a_list, frames) = process_args(switches, parameters, commands)
    filter_coefficients(input_file, output_file, c_list, d_list, a_list, frames, silent, log)

if __name__ == "__main__":
   with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main(sys.argv)
