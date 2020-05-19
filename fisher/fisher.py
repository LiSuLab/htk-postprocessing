"""
===========================
Fisher code
===========================
Dr. Chao Zhang
---------------------------
2020
---------------------------
"""

import sys
from typing import List, Dict
import numpy
import scipy.io

numpy.seterr(all='raise')

# algorithm obtained from Section 4.1.6 Fisher's discriminant for multiple classes
# from page 191 -- 193, C. Bishop, Pattern Recognition and Machine Learning

# load two mat files, one for labels one for features
def LoadData(labpath, feapath):
	labdata = scipy.io.loadmat(labpath)
	feadata = scipy.io.loadmat(feapath)
	dataset = []
	for eachkey in (labdata.keys()):
		if eachkey in {'__header__', '__globals__', '__version__'}:
			continue
		clsidx = int(labdata[eachkey])
		while clsidx >= len(dataset):
			dataset.append([])
		feaval = feadata[eachkey]
		dataset[clsidx].append(feaval.reshape(3))
	return dataset


# to compute the mean vector for each class
def GetMean(samples, ndim):
	mean = numpy.zeros(ndim)
	# Eqn. (4.42)
	for eachsamp in samples:
		mean += eachsamp
	mean /= len(samples)
	return mean


# to compute the variance matrix for each class
def GetVar(samples, ndim, mean):
	var = numpy.zeros((ndim, ndim))
	for eachsamp in samples:
		# xn - mk
		value = eachsamp - mean
		left = value.reshape(ndim, 1)
		right = value.reshape(1, ndim)
		# Eqn. (4.41)
		var += numpy.dot(left, right)
	return var


# to compute the Fisher criterion
def GetFisher(data: numpy.array, labels: List):
	"""
	data:
		(samples x dims) array of observations
	labels:
		samples-long list of int-valued class labels
	"""
	# get the number of classes
	ncls = max(labels)
	# total number of samples and dimension of the feature vector
	Ng, ndim = data.shape
	# indices of items per class
	class_indices: Dict[int, List[int]] = {
		class_i: [
			index
			for index, label in enumerate(labels)
			if label == class_i
		]
		for class_i in range(0, ncls)
	}
	# place to store the mean vector (Mk) for each class
	Mdict = dict()
	# initialize global mean vector
	Mg = numpy.zeros(ndim)
	# initialise global within class variance matrix
	Sw = numpy.zeros((ndim, ndim))
	# to compute the within class variance matrix w.r.t. each class
	for i in range(0, ncls):
		# skip if class is empty
		if not class_indices[i]: continue
		# get the number of samples of the current class
		Nk = len(class_indices[i])
		# to get the mean vector of the current class
		Mk = numpy.mean(data[class_indices[i], :], axis=0)
		# to get the within class variance matrix of the current class
		try:
			Sk = numpy.cov(data[class_indices[i], :].T) * (Nk - 1)
		except FloatingPointError:
			Sk = GetVar(data[class_indices[i], :], ndim, Mk)
		# to update the stats for global within class variance matrix: Eqn. (4.40)
		Sw += Sk
		# store the mean vector of the current class
		Mdict[i] = Mk
		# to update the stats for global mean vector: Eqn. (4.44)
		Mg += Nk * Mk
	# to get the global mean vector: Eqn. (4.44)
	Mg /= Ng
	# initailize the between class variance matrix
	Sb = numpy.zeros((ndim, ndim))
	for i in range(0, ncls):
		# skip if class is empty
		if not class_indices[i]: continue
		# get the number of samples of the current class
		Nk = len(class_indices[i])
		# mk - m
		value = Mdict[i] - Mg
		left = value.reshape(ndim, 1)
		right = value.reshape(1, ndim)
		# Nk * (mk - m)(mk - m)^T: Eqn. (4.46)
		Sb += Nk * numpy.dot(left, right)
	# to compute the Fisher criterion: Eqn. (4.51)
	invSw = numpy.linalg.inv(Sw)
	J = numpy.dot(invSw, Sb)
	# the Fisher criterion := Tr(Sw-1 * Sb)
	return numpy.trace(J)


# if __name__ == '__main__':
#
# 	ndim = 3
# 	class_means = [-4, -2, 0, 2, 4]
# 	class_sdevs = [0.6, 0.6, 0.6, 0.6, 0.6]
# 	class_nsamples = [1000, 1000, 1000, 1000, 1000]
#
# 	print(GetFisher(*gen_dataset(3, class_means, class_sdevs, class_nsamples)))
