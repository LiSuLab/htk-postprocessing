# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import sys
import re
import os

import glob

import numpy
import scipy
import scipy.io

from htk_extraction_tools import *


def get_min_frame_index(input_dir_path, word_list):
    """
	Gets the smallest final frame index amongst all word in the list.
    :param input_dir_path:
    :param word_list:
    :return total_fram_min: the smallest final-frame inde in any word
    """

    # Regular expression for frame and list of node activations
    frame_data_1_re = re.compile((
            # The frame number
            r"(?P<frame_id>[0-9]+):\s+"
            # The list of activation values
            r"(?P<activation_list_1>(?:-?[0-9]+\.?[0-9]+\s*)+)$"))

    total_frame_min = sys.maxsize
    for word in word_list:
        current_word_frame_max = 0
        word_file_path = os.path.join(input_dir_path, "{0}.log".format(word))
        with open(word_file_path, 'r', encoding='utf-8') as word_file:
            for line in word_file:
                frame_data_1_match = frame_data_1_re.match(line)
                if frame_data_1_match:
                    current_word_frame_max = int(frame_data_1_match.group("frame_id"))
        total_frame_min = min(total_frame_min, current_word_frame_max)

    return total_frame_min


def get_activation_lists(input_dir_path, word_list, frame_cap):
	"""

	:param input_dir_path:
	:param word_list:
	:param frame_cap:
	"""
	pass


def main():
    """
    Do dat analysis.
    """

    # Define some paths
    input_dir_path      = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'bottleneck_log')
    output_dir_path     = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'py_out')
    word_list_file_path = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'Stimuli-Lexpro-MEG-Single-col.txt')

    # The number of nodes in the bottleneck layer
    BN_NODES = 26;

    # Get the words from the words file
    word_list = list(get_word_list(word_list_file_path))

    # The number of frames to use in the analysis
    frame_cap = get_min_frame_index(input_dir_path, word_list)

	get_activation_lists(input_dir_path, word_list, frame_cap)




# Boilerplate
if __name__ == "__main__":

    # Log to file
    #with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main()
