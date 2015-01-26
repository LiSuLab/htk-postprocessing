# coding=utf-8
"""
Extract some cepstral coefficients from HTK's output file.
"""

import sys
import re
import functools

__author__ = 'cai'


def main(input_filename, output_filename, c_list, d_list, a_list):
	"""
	Main function.
	:param input_filename:
	:param output_filename:
	:param c_list:
	:param d_list:
	:param a_list:
	"""

	word_name_pattern = r"^-+ Source- (?P<wordname>[a-z]+)\.wav -+$"
	word_name_re = re.compile(word_name_pattern)
	frame_vector_pattern = r"^(?P<frameid>[0-9]+): " \
	                       r"(?P<C01>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C02>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C03>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C04>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C05>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C06>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C07>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C08>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C08>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C10>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C11>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C12>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<C00>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D01>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D02>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D03>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D04>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D05>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D06>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D07>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D08>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D08>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D10>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D11>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D12>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<D00>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A01>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A02>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A03>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A04>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A05>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A06>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A07>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A08>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A08>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A10>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A11>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A12>-?[0-9]+\.[0-9]+) " \
	                       r"(?P<A00>-?[0-9]+\.[0-9]+)$"

	frame_vector_re = re.compile(frame_vector_pattern)

	c_list_match_names = c_list.map(lambda c: "C{0}".format(c.zfill(2)))
	d_list_match_names = d_list.map(lambda d: "D{0}".format(d.zfill(2)))
	a_list_match_names = a_list.map(lambda a: "A{0}".format(a.zfill(2)))

	# Start reading from the input file
	with open(input_filename, encoding="utf-8") as input_file:
		with open(output_filename, mode="w", encoding="utf-8") as output_file:
			for line in input_file:
				word_name_match = word_name_re.match(line)
				frame_vector_match = frame_vector_re.match(line)
				if word_name_match:
					# Matched a new word name
					# Write that word name in the output file
					word_name = word_name_match.group('wordname')
					output_file.write("{0}\n".format(word_name))
				elif frame_vector_match:
					# Matched a frame vector line

					# Get the requested coefficients
					c_coeffs = c_list_match_names.map(lambda c_match_name: frame_vector_match.group(c_match_name))
					d_coeffs = d_list_match_names.map(lambda d_match_name: frame_vector_match.group(d_match_name))
					a_coeffs = a_list_match_names.map(lambda a_match_name: frame_vector_match.group(a_match_name))

					line_to_write = functools.reduce(
						lambda list, item: "{0},{1}".format(list, item),
						c_coeffs + d_coeffs + a_coeffs,
						""
					)
					line_to_write = "{0}:{1}".format(frame_vector_match.group("frameid"), line_to_write)
					output_file.write(line_to_write)


def parse_args(args):
	"""
	Parses command line arguments into switches, parameters and commands
	:param args:
	:return:
	"""
	# Switches look like "-switch"
	switches = [
		arg
		for arg in args
		if arg[0] == "-"
	]

	# Parameters look like "parameter=value"
	parameters = dict([
		(
			arg.split("=")[0],
			arg.split("=")[1]
		)
		for arg in args
		if arg[0] != "-" and "=" in arg
	])

	# commands look like "command"
	commands = [
		arg
		for arg in args
		if arg[0] != "-" and "=" not in arg
	]

	return switches, parameters, commands


def get_parameter(parameters, param_name):
	"""
	Gets parameters from a parameter list
	:param parameters:
	:param param_name:
	:return: :raise ValueError:
	"""
	usage_text = (
		"python extract_cepstral_coefficients "
		"input=<input-path> "
		"output=<output-path> "
		"C=<CC-list> "
		"D=<DC-list> "
		"A=<AC-list> "
		""
		"For example:"
		"python extract_cepstral_coefficients "
		"input=C:\\Users\\ca\i\Desktop\\cepstral-model\\HLIST39cepstral.pre.out "
		"output=C:\\Users\\cai\\Desktop\\cepstral-model\\ProcessedResult.log "
		"C=0,1,2,3,4,5,6,7,8,9,10,11,12 "
		"D=0,1,2,3,4,5,6,7,8,9,10,11,12 "
		"A=0,1,2,3,4,5,6,7,8,9,10,11,12"
	)
	if param_name in parameters:
		input_file = parameters[param_name]
	else:
		print(usage_text)
		raise ValueError("Require {0} parameter.".format(param_name))
	return input_file


def process_args(switches, parameters, commands):
	"""
	Gets relevant info from switches, parameters and commands
	:param switches:
	:param parameters:
	:param commands:
	:return:
	"""
	silent = "S" in switches

	input_file = get_parameter(parameters, "input")
	output_file = get_parameter(parameters, "output")
	c_list = get_parameter(parameters, "C").split(",")
	d_list = get_parameter(parameters, "D").split(",")
	a_list = get_parameter(parameters, "A").split(",")

	return input_file, output_file, c_list, d_list, a_list, silent


if __name__ == "__main__":
	args = sys.argv
	(switches, parameters, commands) = parse_args(args)
	(input_file, output_file, c_list, d_list, a_list, silent) = process_args(switches, parameters, commands)

	main(input_file, output_file, c_list, d_list, a_list)
