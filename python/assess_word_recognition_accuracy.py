# coding=utf-8
"""
Extract some phone boundaries from HTK's output file.
"""

import sys
import re
import os

import glob
from enum import Enum

import numpy
import scipy
import scipy.io

from htk_extraction_tools import *


def count_correct_words(input_dir_path, word_list):
	"""
	Checks to see which words HTK got right.
	"""
	word_guess_re = re.compile((
		# The onset of the segment
		r"^(?P<onset>[0-9]+)\s+"
		# The offset of the segment
		r"(?P<offset>[0-9]+)\s+"
		# The tri/phone
		r"(?P<segment_label>[a-z\+\-]+)\s+"
		# The log likelihood?
		r"(?P<log_likelihood>\-?[0-9]+\.[0-9]+)\s"
		# The word guess
		r"(?P<word_guess>[A-Z]+).*$"))

	word_count   = 0
	correct_count = 0

	for word in sorted(word_list):
		word_count += 1
		word_file_path = os.path.join(input_dir_path, "{0}.rec".format(word))
		with open(word_file_path, 'r', encoding='utf-8') as word_file:
			for line in word_file:
				line_match = word_guess_re.match(line)
				if line_match:
					word_guess = line_match.group("word_guess")
					guess_correct = word.lower() == word_guess.lower()
					prints("Guess for \"{0}\":\t{1}\t{2}".format(word, word_guess, "(y)" if guess_correct else "(INCORRECT)"))
					if guess_correct:
						correct_count += 1

	prints("==========")
	prints("{0} correct guesses out of {1} total. {2}% accurate.".format(correct_count, word_count, (correct_count / word_count) * 100))


def main():
	"""
	Do dat analysis.
	"""

	# Define some paths
	input_dir_path      = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'triphone_boundaries_3_4')
	output_dir_path     = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'py_out')
	word_list_file_path = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'Stimuli-Lexpro-MEG-Single-col.txt')

	# Get the words from the words file
	word_list = list(get_word_list(word_list_file_path))

	# The number of frames to use in the analysis
	frame_cap = 0#get_min_frame_index(input_dir_path, word_list)

	segmentation = count_correct_words(input_dir_path, word_list)



# Boilerplate
if __name__ == "__main__":

	# Log to file
	#with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
		main()
