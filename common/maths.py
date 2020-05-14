from numpy import array
from numpy.random import permutation


def quantile_of_score(a, score, kind='rank'):
    from scipy.stats import percentileofscore
    return percentileofscore(a, score, kind)/100


def shuffle(series: array) -> array:
    shuffled_indices = permutation(series.shape[0])
    return series[shuffled_indices]
