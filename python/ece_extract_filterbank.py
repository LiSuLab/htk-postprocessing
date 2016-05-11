# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import re
import scipy
import scipy.io

from htk_extraction_tools import *


def extract_fbanks_from_line(fbank_line):
	fbanks = fbank_line.strip().split()
	return [float(fbank) for fbank in fbanks]


def single_word_fbk(file_path):

	frame_ident_line_re = re.compile(
		r"^"
		r"(?P<frame_id>[0-9]+)"
		r":"
		r"(?P<fbank_line>[0-9\s\.\-]+)"
		r"$")
	fbank_tail_line_re = re.compile(
		r"^"
		r"(?P<fbank_line>[0-9\s\.\-]+)"
		r"$")

	# 0 expect to read first line
	# 1 expect to read second line
	# 2 expect to read third line
	# 3 expect to read fourth/final line
	STATE = 0

	current_frame = -1
	fbank_collection = []

	all_fbanks = dict()

	with open(file_path, mode='r', encoding='utf-8') as fbank_file:

		for line in fbank_file:

			if STATE is 0:
				frame_ident_line_match = re.match(frame_ident_line_re, line)
				if frame_ident_line_match:
					# read an ident line
					current_frame = frame_ident_line_match.group("frame_id")
					these_fbanks = extract_fbanks_from_line(frame_ident_line_match.group("fbank_line"))
					fbank_collection.extend(these_fbanks)

					# adjust state
					STATE += 1
				else:
					continue

			elif STATE in [1, 2, 3]:
				fbank_tail_line_match = re.match(fbank_tail_line_re, line)
				if fbank_tail_line_match:
					# read data
					these_fbanks = extract_fbanks_from_line(fbank_tail_line_match.group("fbank_line"))
					fbank_collection.extend(these_fbanks)

					# deal with collection if necessary
					if STATE is 3:
						all_fbanks[current_frame] = fbank_collection
						fbank_collection = []

					# adjust state
					if STATE in [1, 2]:
						STATE += 1
					elif STATE is 3:
						STATE = 0
					else:
						raise()
				else:
					raise()

	return all_fbanks, int(current_frame)


def pull_fbk_values(in_path, word_list):

	mfb_dict = dict()
	min_max = 99999 # a really big number which approximates infinity

	for word in word_list:

		prints(word)

		file_path = os.path.join(in_path, '{0}.fbk.txt'.format(word))

		fbk_values, last_frame = single_word_fbk(file_path)

		min_max = min(min_max, last_frame)

		mfb_dict[word] = fbk_values

	return mfb_dict, min_max


def transform_and_save(word_list, mfb_dict, earliest_final_frame, out_path):

	for frame_i in range(0, earliest_final_frame):

		frame_dict = dict()

		for word in word_list:
			frame_dict[word] = mfb_dict[word]['{0}'.format(frame_i)]

		scipy.io.savemat(
			os.path.join(out_path, "fbanks_frame{0:02d}".format(frame_i)),
			frame_dict,
			appendmat=True)

def main():

	# for ece
	in_path = '/Users/cai/Desktop/ece_scratch/htk_out/ece_single_words_hlisted'
	out_path = '/Users/cai/Desktop/ece_scratch/py_out/ece_mfb/'

	# for lexpro
	# in_path = '/Users/cai/Desktop/scratch/htk_out/filterbank_hlisted'
	# out_path = '/Users/cai/Desktop/scratch/py_out/filterbank'

	word_list = get_word_list_from_file_list(in_path, 'fbk.txt')

	mfb_dict, earliest_final_frame = pull_fbk_values(in_path, word_list)

	transform_and_save(word_list, mfb_dict, earliest_final_frame, out_path)

#region if __name__ == "__main__": ...

if __name__ == "__main__":
	main()

#endregion
