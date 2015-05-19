# coding=utf-8
"""
Some common tools for extracting data from HTK's output.
"""
from cw_common import *


def triphone_to_phone_triplet(triphone):
    """
    Given a triphone like x1-x2+x3, returns a phone triplet like [x1, x2, x3].
    :param triphone:
    :return:
    """
    return triphone.replace('-', ' ').replace('+', ' ').split(' ')


def deal_triphones_by_phone(list_of_extant_triphones):
    """
    Given list of triphones, returns a phone-keyed dictionary of triphones with the key as the central phone.
    :param list_of_extant_triphones:
    """
    phone_dictionary = dict()
    for triphone in list_of_extant_triphones:
        # Skip these erroneous entries
        if triphone == '' or triphone == 'sil' or triphone == 'sp':
            continue

        central_phone = triphone_to_phone_triplet(triphone)[1]
        if central_phone in phone_dictionary.keys():
            phone_dictionary[central_phone] += [triphone]
        else:
            phone_dictionary[central_phone] = [triphone]

    return phone_dictionary


def get_word_list(wordlist_filename, silent):
    """
    Returns a list of all the (newline-separated) words in the wordlist file.
    :param silent:
    :param wordlist_filename:
    """

    if not silent:
        prints("\t[Lazily getting word list...]")

    with open(wordlist_filename, encoding="utf-8") as word_list_file:
        for word in word_list_file:
            yield word.strip()


# Boilerplate for library code.
if __name__ == "__main__":
    raise InvalidOperationError("Library code shouldn't be run directly.")
