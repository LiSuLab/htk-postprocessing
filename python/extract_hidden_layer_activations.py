# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
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


def get_activation_lists(input_dir_path, word_list, frame_cap, lines_per_block):
	"""

	:param input_dir_path:
	:param word_list:
	:param frame_cap:
	:param lines_per_block: The number of lines in a single block of nodes
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

		prints("Getting activations for \"{0}\"".format(word))

		# The state based on the most recently read line.
		# To begin with we haven't read any lines.
		#
		# -1 will refer to a non-activatiion line
		# Otherwise they will be 1-indexed (since lines are).
		block_line_i = -1

		# The list of activations for this frame. This starts as empty but will grow as successive lines of each frame are read.
		frame_activations = []

		# The list of activation lists for this word. There should be one entry per frame, each entry should be a list of activations for each node.
		word_activations = []

		word_file_path = os.path.join(input_dir_path, "{0}.log".format(word))
		with open(word_file_path, 'r', encoding='utf-8') as word_file:

			# Read through each line of the file in turn
			for line in word_file:

				if block_line_i == -1 or block_line_i == lines_per_block:
					# If we most recently read something which wasn't relevant, we're ready to look for a new frame-index match
					# Alternatively, we just read the last line of a frame activation list, and are ready to look for another first line.

					frame_data_1_match = frame_data_1_re.match(line)
					if frame_data_1_match:
						# We read the frame-index line we were expecting

						# The frame index we're currently working on.
						# These are 0-indexed.
						# Remember which frame we're looking at right now
						current_frame_index = int(frame_data_1_match.group("frame_id"))

						# We don't want to bother looking past the frame cap, so if we get to a frame which is past it, we can break out of this line loop.
						if 0 < frame_cap < current_frame_index:
							break

						# Extract the list of activations
						activations_this_line = [ float (i)
						                          for i
						                          in frame_data_1_match.group("activation_list_1").split() ]

						frame_activations = activations_this_line.copy()

						# Change the state to match what we've just read
						# In this case, line 1 (which is special)
						block_line_i = 1

					# Otherwise we go on to read the next line

				else:
					# We're expect to read 10 more activations

					# Read them in
					activations_this_line = [ float (i)
					                          for i
					                          in line.split() ]

					# Add them to the current activations for this line
					frame_activations.extend(activations_this_line.copy())

					# Change the state to match what we've just read
					# In this case, we've read an extra line
					block_line_i += 1

					if block_line_i == lines_per_block:
						# If we've just read the last line in a block, we need to save out the data
						word_activations.append(frame_activations)


		# Now save this word's activations list into a dictionary keyed on that word
		activations[word] = word_activations.copy()

	return activations


def save_activations(activations, output_dir_path, layer_name):
	"""
	Saves mat files for the activations
	:param activations:
	:param output_dir_path:
	:param layer_name:
	"""
	for word in activations.keys():
		# Convert data into numpy array
		activations[word] = numpy.array(activations[word])

	# Save
	scipy.io.savemat(
		os.path.join(output_dir_path, "{0}_activations".format(layer_name)),
		activations,
		appendmat = True)


def main():
	"""
	Do dat analysis.
	"""

	layer_name = 'hidden_layer_2'

	# The number of lines per block of node activations (100 for a non-bn hidden layer)
	lines_per_block = 100

	# Define some paths
	input_dir_path      = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'scratch_htk', '{0}_log'.format(layer_name))
	output_dir_path     = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'py_out')
	word_list_file_path = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'Stimuli-Lexpro-MEG-Single-col.txt')

	# Get the words from the words file
	word_list = list(get_word_list(word_list_file_path))

	# The number of frames to use in the analysis
	frame_cap = 0

	activations = get_activation_lists(input_dir_path, word_list, frame_cap, lines_per_block)

	save_activations(activations, output_dir_path, layer_name)



# Boilerplate
if __name__ == "__main__":

	# Log to file
	#with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
		main()
