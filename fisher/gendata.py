"""
===========================
Generate data for Fisher test
===========================
Dr. Chao Zhang
---------------------------
2020
---------------------------
"""

import random
import sys

import numpy
import scipy.io


def GenRandValues(ndim, mean, sdev, count):
	samples = []
	while len(samples) < count:
		values = []
		while len(values) < ndim:
			values.append(random.uniform(mean - 3 * sdev, mean + 3 * sdev))
		samples.append(values)
	return samples


def gen_dataset(ndim, class_means, class_sdevs, class_nsamples):
	data = []
	labels = []
	for class_i in range(0, len(class_means)):
		data.extend(GenRandValues(ndim, class_means[class_i], class_sdevs[class_i], class_nsamples[class_i]))
		labels.extend([class_i] * class_nsamples[class_i])
	return numpy.array(data), numpy.array(labels)


if __name__ == '__main__':

	labmat = sys.argv[1]
	feamat = sys.argv[2]

	ndim = 3
	means = [-4, -2, 0, 2, 4]
	sdevs = [0.6, 0.6, 0.6, 0.6, 0.6]
	nsamples = [1000, 1000, 1000, 1000, 1000]

	labdict = {}
	feadict = {}
	index = 0
	for i in range(0, len(means)):
		values = GenRandValues(ndim, means[i], sdevs[i], nsamples[i])
		for eachval in values:
			labdict[str(index)] = numpy.array([i])
			feadict[str(index)] = numpy.array(eachval)
			index += 1

	scipy.io.savemat(labmat, labdict)
	scipy.io.savemat(feamat, feadict)
