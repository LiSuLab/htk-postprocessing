def quantile_of_score(a, score, kind='rank'):
    from scipy.stats import percentileofscore
    return percentileofscore(a, score, kind)/100