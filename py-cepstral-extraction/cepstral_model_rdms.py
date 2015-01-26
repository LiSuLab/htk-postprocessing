# coding=utf-8

import sys
import re
import scipy.io
from cw_common import parse_args

def get_parameter(parameters, param_name, required=False):
    """
    Gets parameters from a parameter list
    :param parameters:
    :param param_name:
    :param required:
    :return: :raise ValueError:
    """
    raise NotImplementedError()

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
        "input=C:\\Users\\cai\\Desktop\\cepstral-model\\HLIST39cepstral.pre.out "
        "output=C:\\Users\\cai\\Desktop\\cepstral-model\\ProcessedResult.log "
        "C=0,1,2,3,4,5,6,7,8,9,10,11,12 "
        "D=0,1,2,3,4,5,6,7,8,9,10,11,12 "
        "A=0,1,2,3,4,5,6,7,8,9,10,11,12"
    )
    if param_name in parameters:
        param = parameters[param_name]
    elif required:
        print(usage_text)
        raise ValueError("Require {0} parameter.".format(param_name))
    else:
        return ""
    return param


# noinspection PyUnusedLocal
def process_args(switches, parameters, commands):
    """
    Gets relevant info from switches, parameters and commands
    :param switches:
    :param parameters:
    :param commands:
    :return:
    """
    silent = "S" in switches

    raise NotImplementedError()

    input_file = get_parameter(parameters, "input", True)
    output_file = get_parameter(parameters, "output", True)
    c_list = get_parameter(parameters, "C").split(",")
    d_list = get_parameter(parameters, "D").split(",")
    a_list = get_parameter(parameters, "A").split(",")

    return input_file, output_file, c_list, d_list, a_list, silent


if __name__ == "__main__":
    args = sys.argv
    (switches, parameters, commands) = parse_args(args)
    #(input_file, output_file, c_list, d_list, a_list, silent) = process_args(switches, parameters, commands)

    #filter_coefficients(input_file, output_file, c_list, d_list, a_list, silent)
