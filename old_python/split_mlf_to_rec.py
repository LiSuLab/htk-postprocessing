"""
Extract some phone boundaries from HTK's output file.
"""

import re
import os

from pathlib import Path


def do_split(mlf_path, output_dir_path):

	rec_label_line_re = re.compile((
		r"^\"test/(?P<rec_label>[a-z]+\.rec)\"$"
	))
	empty_line_re = re.compile((
		r"^\.$"
	))
	header_line_re = re.compile((
		r"^#!MLF!#$"
	))

	rec_file = []

	with open(mlf_path, 'r', encoding='utf-8') as mlf_file:
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


# Boilerplate
if __name__ == "__main__":
	input_root = Path("/Users/cai/Dox/Academic/Analyses/Lexpro/DNN mapping/phonetic alignments")

	for s in [0, 3, 4, 5]:
		system_root_dir = Path(input_root, f"system{s}")
		output_dir = Path(system_root_dir, "separated")

		if not output_dir.is_dir():
			output_dir.mkdir()

		mlf_path = list(system_root_dir.glob("*.mlf"))[0]

		do_split(mlf_path, output_dir)
