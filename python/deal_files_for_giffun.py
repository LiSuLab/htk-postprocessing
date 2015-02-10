import sys
import glob
import os
import shutil


def main():
    base_directory = r"/Volumes/Cai's MBP HDD/Dropbox/Neurolex/Research/Lexpro/cepstral coefficient model/Figures/"

    all_prefixes = [
        "C01",
        "C02",
        "C03",
        "C04",
        "C05",
        "C06",
        "C07",
        "C08",
        "C09",
        "C10",
        "C11",
        "C12",
        "D01",
        "D02",
        "D03",
        "D04",
        "D05",
        "D06",
        "D07",
        "D08",
        "D09",
        "D10",
        "D11",
        "D12",
        "A01",
        "A02",
        "A03",
        "A04",
        "A05",
        "A06",
        "A07",
        "A08",
        "A09",
        "A10",
        "A11",
        "A12",
    ]

    for prefix in all_prefixes:
        os.chdir(base_directory)
        all_files_this_prefix = glob.glob(prefix + "*.jpg")
        prefix_path = os.path.join(base_directory, prefix)
        os.mkdir(prefix_path)

        for file in all_files_this_prefix:
            shutil.copyfile(file, prefix + "/" + file)


if __name__ == "__main__":
    main()

