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


def get_segmentation(input_dir_path, word_list, frame_cap):

	# Regular expression for frame and list of node activations
	segment_re = re.compile((
		# The onset of the segment
		r"^(?P<onset>[0-9]+)\s+"
		# The offset of the segment
		r"(?P<offset>[0-9]+)\s+"
		# The tri/phone
		r"(?P<triphone>[a-z\+\-]+)\s+"
		# The rest
		r".*$"))

	# a word-keyed dictionary of sequence-indexed lists of (onset, offset, triphone)-tuples.
	boundaries = {}

	# Work on each word separately and in turn
	for word in word_list:

		prints("Segmenting word \"{0}\"...", word)

		word_boundaries = []

		word_file_path = os.path.join(input_dir_path, "{0}.rec".format(word))
		with open(word_file_path, 'r', encoding='utf-8') as word_file:
			for line in word_file:
				line_match = segment_re.match(line)
				if line_match:
					onset    = int(line_match.group("onset"))
					offset   = int(line_match.group("offset"))
					triphone = line_match.group("triphone")

					if triphone != 'sp':
						word_boundaries.append((onset, offset, triphone))

		# Now save this word's activations list into a dictionary keyed on that word
		boundaries[word] = word_boundaries.copy()

	return boundaries


def save_boundaries(boundaries, output_dir_path):
	"""
	Saves mat files for the activations
	:param boundaries:
	:param output_dir_path:
	"""

	for word in boundaries.keys():
		# Convert data into numpy array
		n_segments = len(boundaries[word])
		numpyified = numpy.zeros((n_segments,), dtype=[
			('onset', int),
			('offset', int),
			('triphone', '|S10')
		])
		for i in range(n_segments):
			numpyified[i] = (boundaries[word][i])

		boundaries[word] = numpyified

	# Save
	scipy.io.savemat(
		os.path.join(output_dir_path, "triphone_boundaries"),
		boundaries,
		appendmat = True,
		long_field_names = True)


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

	activations = get_segmentation(input_dir_path, word_list, frame_cap)

	save_boundaries(activations, output_dir_path)



# Boilerplate
if __name__ == "__main__":

	# Log to file
	#with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
		main()
