from scipy.stats import percentileofscore

print(1 - (percentileofscore([1, 2, 3, 3, 4], 3))/100)
print(1 - (percentileofscore([3, 4, 2, 1, 3], 3))/100)
