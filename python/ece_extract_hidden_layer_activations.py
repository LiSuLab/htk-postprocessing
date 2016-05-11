# coding=utf-8
"""
Extract hidden layer activations from HTK's output file.
"""

import re

import scipy
import scipy.io

from htk_extraction_tools import *


def get_activation_lists(input_dir_path, word_list, lines_per_block, suffix):
	"""

	:param input_dir_path:
	:param word_list:
	:param lines_per_block: The number of lines in a single block of nodes
	:return activations: a word-keyed dictionary of frame-indexed lists of node-indexed lists of activations
	"""

	min_max = 999999 # a really big number to approximate infinity

	# a word-keyed dictionary of frame-indexed lists of node-indexed lists of activations.
	activations = {}

	# Work on each word separately and in turn
	for word in word_list:

		prints("Getting activations for \"{0}\"".format(word))

		word_file_path = os.path.join(input_dir_path, "{0}.{1}".format(word, suffix))

		word_activations, last_frame = single_word_activations(word_file_path, lines_per_block)

		# htk 0-indexed
		min_max = min(min_max, last_frame)

		# Now save this word's activations list into a dictionary keyed on that word
		activations[word] = word_activations

	return activations, min_max


def extract_activations_from_line(activation_line):
	activations = activation_line.strip().split()
	return [float(activation) for activation in activations]


def single_word_activations(word_file_path, lines_per_block):

	# Regular expression for frame and list of node activations
	frame_ident_line_re = re.compile(
			r"^"
			# The frame number
			r"(?P<frame_id>[0-9]+)"
			r":"
			# The list of activation values
			r"(?P<activation_list>(?:\s+[0-9\-\.]+)+)"
			r"$")
	tail_line_re = re.compile(
		r"^"
		r"(?P<activation_list>[0-9\s\.\-]+)"
		r"$")

	# 0 expect to read first (frame ident) line
	# 1 expect to read second line
	# ...
	STATE = 0

	# htk 0-indexed
	current_frame = -1
	activation_collection = []
	all_activations = dict()

	with open(word_file_path, 'r', encoding='utf-8') as word_file:

		# Read through each line of the file in turn
		for line in word_file:

			if STATE is 0:
				frame_ident_line_match = frame_ident_line_re.match(line)
				if frame_ident_line_match:
					# read ident line
					current_frame = frame_ident_line_match.group('frame_id')
					activation_collection.extend(
						extract_activations_from_line(frame_ident_line_match.group('activation_list')))

					# adjust state
					STATE += 1
				else:
					continue

			elif STATE in range(1, lines_per_block):
				tail_line_match = tail_line_re.match(line)
				if tail_line_match:
					# read data
					these_activations = extract_activations_from_line(tail_line_match.group('activation_list'))
					activation_collection.extend(these_activations)

					# deal with and reset collection if on final line of block
					if STATE is lines_per_block-1:
						all_activations[current_frame] = activation_collection
						activation_collection = []

					# adjust state
					if STATE in range(1, lines_per_block-1):
						STATE += 1
					elif STATE is lines_per_block-1:
						STATE = 0
					else:
						# bad state
						raise()
				else:
					# we really expected to see a readable line yere
					raise()
			else:
				# state exceeds block size
				raise()

	return all_activations, int(current_frame)


def save_activations(activations, word_list, earliest_final_frame, output_dir_path, layer_name):

	for frame_i in range(0, earliest_final_frame):

		frame_dict = dict()

		for word in word_list:
			frame_dict[word] = activations[word]['{0}'.format(frame_i)]

		scipy.io.savemat(
			os.path.join(output_dir_path, "{0}_activations_frame{1:02d}".format(layer_name, frame_i)),
			frame_dict,
			appendmat = True)


def comma_separate_list(activation_list):
	return ','.join([str(activation) for activation in activation_list])


def transform_to_flat_files(activations, word_list, earliest_final_frame, output_path, layer_name):
	for word in word_list:
		file_name = os.path.join(output_path, '{0}_activations_{1}.csv'.format(layer_name, word))
		with open(file_name, mode='w', encoding='utf-8') as word_file:
			for frame_i in range(0, earliest_final_frame):
				activations_this_frame = activations[word]['{0}'.format(frame_i)]
				word_file.write('{0}\n'.format(comma_separate_list(activations_this_frame)))


def main():
	"""
	Do dat analysis.
	"""

	#             l2
	#              ...
	#             l7bn
	layer_name = 'l7bn'

	# The number of lines per block of node activations
	#  100 for a non-bn hidden layer
	#  3 for a bn layer
	lines_per_block = 3

	# Define some paths
	input_path      = os.path.join('/Users', 'cai', 'Desktop', 'ece_scratch', 'htk_out', 'ece_{0}_log'.format(layer_name))
	output_path     = os.path.join('/Users', 'cai', 'Desktop', 'ece_scratch', 'py_out', 'ece_dnn_activations')

	# Get the words from the words file
	suffix = 'mlp.txt'
	word_list = get_word_list_from_file_list(input_path, suffix)

	activations, earliest_final_frame = get_activation_lists(input_path, word_list, lines_per_block, suffix)

	save_activations(activations, word_list, earliest_final_frame, output_path, layer_name)

	transform_to_flat_files(activations, word_list, earliest_final_frame, output_path, layer_name)


# Boilerplate
if __name__ == "__main__":

	# Log to file
	#with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
		main()
