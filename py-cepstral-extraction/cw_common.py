# coding=utf-8
"""
Common code.
"""
import sys


def parse_args(args):
    """
    Parses command line arguments into switches, parameters and commands.
    Switches look like "-switch"
    Parameters look like "param=value"
    Commands look like "command" (no initial "-")

    :param args: List of strings straight from the console.
    :return switches: list of strings which are switches, leading "-" trimmed
    :return parameters: dictionary of parameters
    :return commands: list of strings which are commands
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


def get_parameter(parameters, param_name, required=False, usage_text=None):
    """
    Gets parameters from a parameter list
    :param parameters:
    :param param_name:
    :param required:
    :param usage_text:
    :return: :raise ValueError:
    """
    if param_name in parameters:
        param = parameters[param_name]
    elif required:
        if usage_text is not None:
            print(usage_text)
        raise ValueError("Require {0} parameter.".format(param_name))
    else:
        return ""
    return param


class ApplicationError(Exception):
    """
    Represents an error in which the executing code is in a logically invalid
    state. This means that a programmer error has occurred.
    :param value:
    """

    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class RedirectStdoutTo:

    """
    For redirecting stdout to a file.

    Use like:

    with open('log.txt', mode="w", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        # do stuff here

    :param out_new:
    """

    def __init__(self, out_new):
        self.out_new = out_new

    def __enter__(self):
        self.out_old = sys.stdout
        sys.stdout = self.out_new

    def __exit__(self, *args):
        sys.stdout = self.out_old
