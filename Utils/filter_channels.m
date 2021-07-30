% A function that returns a list of channels without explicitly noisy data

% data - an IEEGDataset Object that has been accessed outside the function
% s_length - desired length of each data segment in seconds
% fs - sampling rate of the data
% out - a list of channels to be used

function [signal] = filter_channels(data, sampleRate, f_low, f_high)

% Create params for fifth order Chebyshev filter
[b, a] = cheby1(4, 5, [2*f_low/sampleRate 2*f_high/sampleRate]);

% Filter data
signal = filter(b, a, data', [], 2)';
    
end