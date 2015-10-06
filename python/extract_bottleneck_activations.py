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

		prints("Getting activations for \"{0}\"".format(word))

		# The state based on the most recently read line.
		# To begin with we haven't read any lines.
		line_state = ActivationLines.Other

		# The list of activations for this frame. This starts as empty but will grow as successive lines of each frame are read.
		frame_activations = []

		# The list of activation lists for this word. There should be one entry per frame, each entry should be a list of activations for each node.
		word_activations = []

		word_file_path = os.path.join(input_dir_path, "{0}.log".format(word))
		with open(word_file_path, 'r', encoding='utf-8') as word_file:

			# Read through each line of the file in turn
			for line in word_file:

				# This enum-based state machine may look like I know what I'm doing, but this code (while it does work) is actually rather fragile. I'm not doing any error checking and there are no failure states
				if line_state is ActivationLines.Other or line_state is ActivationLines.Nodes2026:
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
						if current_frame_index > frame_cap:
							break

						# Extract the list of activations
						activations_this_line = [ float (i)
						                          for i
						                          in frame_data_1_match.group("activation_list_1").split() ]

						frame_activations = activations_this_line.copy()

						# Change the state to match what we've just read
						line_state = ActivationLines.FrameNodes09

					# Otherwise we go on to read the next line

				elif line_state is ActivationLines.FrameNodes09:
					# We're expect to read 10 more activations

					# Read them in
					activations_this_line = [ float (i)
					                          for i
					                          in line.split() ]

					# Add them to the current activations for this line
					frame_activations.extend(activations_this_line.copy())

					# Change the state to match what we've just read
					line_state = ActivationLines.Nodes1019

				elif line_state is ActivationLines.Nodes1019:
					# We're expect to read 6 more activations

					# Read them in
					activations_this_line = [ float (i)
					                          for i
					                          in line.split() ]

					# Add them to the current activations for this line
					frame_activations.extend(activations_this_line.copy())

					# We've now got all the activations for this frame, so we'll record that list somewhere
					word_activations.append(frame_activations)

					# Change the state to match what we've just read
					line_state = ActivationLines.Nodes2026

		# Now save this word's activations list into a dictionary keyed on that word
		activations[word] = word_activations.copy()

	return activations


class ActivationLines(Enum):
	"""
	Represents the dirrerent line types of node activations in a file.
	"""
	# A non-frame, non-nodes line
	Other        = 0
	# The line with the frame index and nodes 0–9
	FrameNodes09 = 1
	# The line with nodes 10–19
	Nodes1019    = 2
	# The line with nodes 20–26
	Nodes2026    = 3


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
	input_dir_path      = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'bottleneck_log')
	output_dir_path     = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'py_out')
	word_list_file_path = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'Stimuli-Lexpro-MEG-Single-col.txt')

	# The number of nodes in the bottleneck layer
	BN_NODES = 26;

	# Get the words from the words file
	word_list = list(get_word_list(word_list_file_path))

	# The number of frames to use in the analysis
	frame_cap = get_min_frame_index(input_dir_path, word_list)

	activations = get_activation_lists(input_dir_path, word_list, frame_cap)

	save_activations(activations, output_dir_path)




# Boilerplate
if __name__ == "__main__":

	# Log to file
	#with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
		main()
