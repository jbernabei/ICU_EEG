function [part] = make_xval_partition(n, n_folds)
% MAKE_XVAL_PARTITION - Randomly generate cross validation partition.
%
% Usage:
%
%  PART = MAKE_XVAL_PARTITION(N, N_FOLDS)
%
% Randomly generates a partitioning for N datapoints into N_FOLDS equally
% sized folds (or as close to equal as possible). PART is a 1 X N vector,
% where PART(i) is a number in (1...N_FOLDS) indicating the fold assignment
% of the i'th data point.

% YOUR CODE GOES HERE
groups = ceil(linspace(0,n_folds,n));   % Initialize part vector to be 1 x N in size. 
groups(groups==0) = 1;                  % Replace initial zero with a 1
randomize = randperm(n);                % Generate random permutation
part = groups(randomize);               % Randomize groups

