function [features, num_removed, labels, time_windows, incorrect_artifact, bad_reject_criteria, individual_features] = sliding_window(values, fs, winLen, label_vec, first_time, rejection_params)

%   sliding_window.m
%   
%   Inputs:
%    
%       values:     Values for which features will be calculated MxN where
%                   each of M rows is a sample of electrophysiologic data
%                   and N are the channels
%           fs:     Sampling rate
%       winLen:     Length of window
%      winDisp:     Displacement from one window to next
%       featFn:     Handle of function to calculate features
%    
%   Output:
%    
%     features:     Features calculated for use in classifier
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
%    Last Revised:  March 2020

%% Prepare data by chunking into segments and filter
% Define number of features we have
num_feats = 10;

% Find number of samples in raw values
num_samples = size(values, 1);

% Find number of windows based upon samples, sampling frequency, winLen
num_windows = floor(num_samples./(fs*winLen));

% Set up empty features, processed labels, time_windows, incorrect artifact
features = [];
individual_features = [];
labels = [];
time_windows = [];
incorrect_artifact = [];

bad_reject_criteria = [];

% Set up number of indices removed by artifact rejection
num_removed = 0;

% Loop through each window
for j = 1:num_windows
    
    % Extract data and labels
    start_ind = (j-1)*(fs*winLen) + 1;
    end_ind = (fs*winLen)*j;
    
    % Get the new start time
    start_time = first_time+winLen*(j-1);
    
    % Add new start time to start windows
    time_windows = [time_windows,start_time];
    
    % Pull out data for this chunk
    chunked_data = values(start_ind:end_ind,:);
    
    % Extract the labels
    processed_labels = label_vec(start_ind:end_ind);
    
    % Find whether or not this window contains any seizure
    label_wind = ceil(sum(processed_labels)./(winLen*fs));
    
    % Check for NaN artifact. If so, skip segment
    if sum(sum(isnan(chunked_data)))>0
        
        % Add to number of segments removed
        num_removed = num_removed+1;
        
        % Fill features with NaNs for this segment
        features = [features; NaN*zeros(1,2*num_feats)];
        
        individual_features = [individual_features; NaN*zeros(1,180)];
        
        % Assign label as class 4 = NaN
        labels = [labels; 4];
        
        % Continue to next window, skipping feature calculation
        continue
    end
    
    % Filter params 
    f_low = 1; % Low cutoff frequency
    f_high = 20; % High cutoff frequency
    
    % Bandpass filter channels
    filter_chunk_data = filter_channels(chunked_data, fs, f_low, f_high);
    
    % Calculate features
    raw_feats = single_ch_features(filter_chunk_data,fs);
    
    % Post process features, including indicate whether segment should be
    % removed because an artifact was detected
    [processed_features, remove_this_seg, personalized_feats, which_feature] = post_process_feats(raw_feats, rejection_params);
    
    % Add to feature matrix
    features = [features; processed_features];
    individual_features = [individual_features; personalized_feats];
    
    % Remove segment if artifact was rejected
    if remove_this_seg==1
        
        % Add to number of segments removed
        num_removed = num_removed + 1;
        
        % Assign label of 3 if it was artifact
        labels = [labels; 3];
        
        % Check if this was actually a seizure segment
        if label_wind==1
            
            % Add to incorrect artifact detection
            incorrect_artifact = [incorrect_artifact; start_time];
            
            % Find bad rejection criteria
            bad_reject_critera = [bad_reject_criteria, which_feature];
            
        end
    
    % Otherwise if this segment is OK...
    else
        
        % Assign new label for this window
        labels = [labels; label_wind];
    end
    
end

end