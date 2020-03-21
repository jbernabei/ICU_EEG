function [feats] = calculate_feats(vals,sampleRate)

%   get_EEG_Features.m
%   
%   Inputs:
%    
%       values:     Values for which features will be calculated.MxN where
%                   each of M rows is a channel of N samples of 
%                   electrophysiologic data.
%
%       sampleRate: Sampling rate of the EEG in Hz.
%    
%   Output:
%    
%       features:      Returns vector of features for chunk of data
%    
%    License:       MIT License
%
%    Author:        John Bernabei
%    Affiliation:   Center for Neuroengineering & Therapeutics
%                   University of Pennsylvania
%                    
%    Website:       www.littlab.seas.upenn.edu
%    Repository:    http://github.com/jbernabei
%    Email:         johnbe@seas.upenn.edu
%
%    Version:       1.0
%    Last Revised:  August 2019
% 
%% Do initial data processing

% mean value
mean_val = mean(vals);

% variance value
var_val = var(vals);

% Delta band power
fcutlow0=1;   %low cut frequency in Hz
fcuthigh0=4;   %high cut frequency in Hz
p_delta = bandpower(vals,sampleRate,[fcutlow0 fcuthigh0]);

% Theta band power
fcutlow1=4;   %low cut frequency in Hz
fcuthigh1=8;   %high cut frequency in Hz
p_theta = bandpower(vals,sampleRate,[fcutlow1 fcuthigh1]);
%v_theta = var(bandpower(vals',sampleRate,[fcutlow1 fcuthigh1]));

% Alpha band power
fcutlow2=8;   %low cut frequency in Hz    
fcuthigh2=12; %high cut frequcency in Hz
p_alpha = bandpower(vals,sampleRate,[fcutlow2 fcuthigh2]);
%v_alpha = var(bandpower(vals',sampleRate,[fcutlow2 fcuthigh2]));

% Filter for beta band
fcutlow3=12;   %low cut frequency in Hz
fcuthigh3=20;   %high cut frequency in Hz
p_beta = bandpower(vals,sampleRate,[fcutlow3 fcuthigh3]);
%v_beta = var(bandpower(vals',sampleRate,[fcutlow3 fcuthigh3]));

% Calculate features based on linelength
Line_length = sum(abs(diff(vals)));
%v_LL = var(sum(abs(diff(vals))));

% Calculate envelope
[yupper,ylower] = envelope(vals);
upper_env = median(yupper);

% Kurtosis
Kurt = kurtosis(vals);

% Get number of channels
num_channels = size(vals,2);

% wavelet entropy
for c = 1:num_channels
    
   % Calculate shannon wavelet entropy
   w_entropy(c) = wentropy(vals(:,c),'shannon');
end

% Return vector of features
feats = [mean_val; var_val; p_delta; p_theta; p_alpha; p_beta; Line_length; upper_env; Kurt; w_entropy]';
end