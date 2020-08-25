"""
Extract some phone boundaries from HTK's output file.
"""

import re
import os
from pathlib import Path

import numpy
import scipy
import scipy.io

from old_python.htk_extraction_tools import get_word_list, triphone_to_phone_triplet


def get_segmentation(input_dir_path, word_list, convert_to_phones=True):

	# Regular expression for frame and list of node activations
	segment_re = re.compile((
		# The onset of the segment
		r"^(?P<onset>[0-9]+)\s+"
		# The offset of the segment
		r"(?P<offset>[0-9]+)\s+"
		# The tri/phone
		r"(?P<segment_label>[a-z+\-]+)\s+"
		# The rest
		r".*$"))

	# a word-keyed dictionary of sequence-indexed lists of (onset, offset, segment_label)-tuples.
	boundaries = {}

	# Work on each word separately and in turn
	for word in word_list:

		word_boundaries = []

		word_file_path = os.path.join(input_dir_path, "{0}.rec".format(word))
		with open(word_file_path, 'r', encoding='utf-8') as word_file:
			for line in word_file:
				line_match = segment_re.match(line)
				if line_match:
					onset    = int(line_match.group("onset"))
					offset   = int(line_match.group("offset"))
					segment_label = line_match.group("segment_label")

					if segment_label == 'sp':
						continue
					if convert_to_phones and segment_label != 'sil':
						segment_label = triphone_to_phone_triplet(segment_label)[1]
					word_boundaries.append((onset, offset, segment_label))

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
			('label', '|S10')])

		for i in range(n_segments):
			numpyified[i] = (boundaries[word][i])

		boundaries[word] = numpyified

	# Save
	scipy.io.savemat(
		os.path.join(output_dir_path, "triphone_boundaries.mat"),
		boundaries,
		long_field_names=True)


if __name__ == "__main__":

	input_root = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping/phonetic alignments")
	word_list_path = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping/stimulus wordlist.txt")

	# Get the words from the words file
	word_list = list(get_word_list(word_list_path))

	for s in [0, 3, 4, 5]:
		system_root_dir = Path(input_root, f"system{s}")
		rec_dir = Path(system_root_dir, "separated")
		output_dir_path = Path(system_root_dir, "segmentation")

		if not output_dir_path.is_dir():
			output_dir_path.mkdir()

		segmentation = get_segmentation(rec_dir, word_list)

		save_boundaries(segmentation, output_dir_path)
