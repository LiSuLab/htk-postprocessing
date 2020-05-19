"""
===========================
Fisher code
===========================

Dr. Chao Zhang
---------------------------
2020
---------------------------
"""

import os
import sys
import numpy
import scipy.io

# algorithm obtained from Section 4.1.6 Fisher's discriminant for multiple classes
# from page 191 -- 193, C. Bishop, Pattern Recognition and Machine Learning

labmat = sys.argv[1]
feamat = sys.argv[2]

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
def GetFisher(dataset):
	# get the number of classes
	ncls = len(dataset)
	# get the dimension of the feature vector
	ndim = dataset[0][0].shape[0]
	# place to store the mean vector (Mk) for each class
	Mlist = []
	# initialize global mean vector
	Mg = numpy.zeros(ndim)
	# initialise global within class variance matrix
	Sw = numpy.zeros((ndim, ndim))
	# initialize total number of samples
	Ng = 0
	# to compute the within class variance matrix w.r.t. each class
	for i in range(0, ncls):
		# get the number of samples of the current class
		Nk = len(dataset[i])
		# to get the total number of samples
		Ng += Nk
		# to get the mean vector of the current class
		Mk = GetMean(dataset[i], ndim)
		# to get the within calss variance matrix of the current class
		Sk = GetVar(dataset[i], ndim, Mk)
		# to update the stats for global within class variance matrix: Eqn. (4.40)
		Sw += Sk
		# store the mean vector of the current class
		Mlist.append(Mk)
		# to update the stats for global mean vector: Eqn. (4.44)
		Mg += Nk * Mk
	# to get the global mean vector: Eqn. (4.44)
	Mg /= Ng
	# initailize the between class variance matrix 
	Sb = numpy.zeros((ndim, ndim))
	for i in range(0, ncls):
		# get the number of samples of the current class
		Nk = len(dataset[i])
		# mk - m
		value = Mlist[i] - Mg
		left = value.reshape(ndim, 1)
		right = value.reshape(1, ndim)
		# Nk * (mk - m)(mk - m)^T: Eqn. (4.46)
		Sb += Nk * numpy.dot(left, right)
	# to compute the Fisher criterion: Eqn. (4.51)
	invSw = numpy.linalg.inv(Sw)
	J = numpy.dot(invSw, Sb)
	# the Fisher criterion := Tr(Sw-1 * Sb)
	return numpy.trace(J)
			

dataset = LoadData(labmat, feamat)
print(GetFisher(dataset))

