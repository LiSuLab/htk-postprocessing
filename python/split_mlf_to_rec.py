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


def do_split(input_dir_path, output_dir_path):
	mlf_file_name = "ann_triphone.mlf"

	rec_label_line_re = re.compile((
		r"^\"test/(?P<rec_label>[a-z]+\.rec)\"$"
	))
	empty_line_re = re.compile((
		r"^\.$"
	))
	header_line_re = re.compile((
		r"^#!MLF!#$"
	))

	reader_state = JustReadLine.Empty

	rec_file = []

	with open(os.path.join(input_dir_path, mlf_file_name), 'r', encoding='utf-8') as mlf_file:
		for line in mlf_file:

			rec_label_line_match = rec_label_line_re.match(line)
			empty_line_match = empty_line_re.match(line)
			header_line_match = header_line_re.match(line)

			if rec_label_line_match:
				rec_file_name = rec_label_line_match.group("rec_label")
				rec_file_path = os.path.join(output_dir_path, rec_file_name)
				rec_file = open(rec_file_path, mode='w', encoding='utf-8')

			elif empty_line_match:
				rec_file.close()

			elif header_line_match:
				continue

			else:
				rec_file.write("{0}".format(line))


class JustReadLine(Enum):
	"""
	Represents state when reading a mlf file.
	"""
	Empty = 0
	RecLabel = 1


def main():
	"""
	Do dat analysis.
	"""

	# Define some paths
	input_dir_path      = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'triphone_boundaries_3_5')
	output_dir_path     = os.path.join('/Users', 'cai', 'Desktop', 'scratch', 'triphone_boundaries_3_5')

	do_split(input_dir_path, output_dir_path)


# Boilerplate
if __name__ == "__main__":

	# Log to file
	#with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
		main()
