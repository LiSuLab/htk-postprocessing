# coding=utf-8
import re

from cw_common import *
if __name__ == "__main__":
   with open(get_log_filename(__file__), mode="a", encoding="utf-8") as log_file, RedirectStdoutTo(log_file):
        main(sys.argv)
