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


def get_activation_lists(input_dir_path, word_list, frame_cap):
	"""

	:param input_dir_path:
	:param word_list:
	:param frame_cap:
	:return activations: a word-keyed dictionary of frame-indexed lists of node-indexed lists of activations
	"""

	# Regular expression for frame and list of node activations
	frame_data_1_re = re.compile((
			# The frame number
			r"(?P<frame_id>[0-9]+):\s+"
			# The list of activation values
			r"(?P<activation_list_1>(?:-?[0-9]+\.?[0-9]+\s*)+)$"))

	# a word-keyed dictionary of frame-indexed lists of node-indexed lists of activations.
	activations = {}

	# Work on each word separately and in turn
	for word in word_list:

		

		# Now save this word's activations list into a dictionary keyed on that word
		activations[word] = word_activations.copy()

	return activations


def save_activations(activations, output_dir_path):
	"""
	Saves mat files for the activations
	:param activations:
	:param output_dir_path:
	"""
	for word in activations.keys():
		# Convert data into numpy array
		activations[word] = numpy.array(activations[word])

	# Save
	scipy.io.savemat(
		os.path.join(output_dir_path, "bn26_activations"),
		activations,
		appendmat = True)


def main():
	"""
	Do dat analysis.
	"""

	# Define some paths
	input_dir_path      = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'triphone_boundaries')
	output_dir_path     = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'py_out')
	word_list_file_path = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'Stimuli-Lexpro-MEG-Single-col.txt')

	# Get the words from the words file
	word_list = list(get_word_list(word_list_file_path))

	# The number of frames to use in the analysis
	frame_cap = 0#get_min_frame_index(input_dir_path, word_list)

	activations = get_activation_lists(input_dir_path, word_list, frame_cap)

	save_activations(activations, output_dir_path)



# Boilerplate
if __name__ == "__main__":

	# Log to file
	#with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
		main()
