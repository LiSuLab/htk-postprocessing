# README #

Cai Wingfield

Code for simple filtering of cepstral feature files.

## Instructions ##

1. Run `extract_cepstral_coefficients.py` with the appropriate arguments. E.g.:
  `python extract_cepstral_coefficients.py input=C:\Users\cai\code\cepstral-model\HLIST39cepstral.pre.out
output=C:\Users\cai\code\cepstral-model\ProcessedResult.log
C=1,2,3,4,5,6,7,8,9,10,11,12
D=1,2,3,4,5,6,7,8,9,10,11,12
A=1,2,3,4,5,6,7,8,9,10,11,12`
  This will extract the requested features from HTK's output and put them in a separate file.

2. Run `save_features.py` with the appropriate arguments. E.g:
  `python save_features.py input=C:\Users\cai\code\cepstral-model\ProcessedResult.log
words=C:\Users\cai\code\cepstral-model\Stimuli-Lexpro-MEG-Single-col.txt
output=C:\Users\cai\code\cepstral-model\Features.mat`
  This will convert the extracted features into feature matrices and save them in a Matlab-readable format.

3. Run `CalculateAndShowRDMs.m` from Matlab. This will calculate frame-by-frame RDMs from the feature matrices and display and save them into a `Figures` directory.
