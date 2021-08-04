function [raw_data, raw_times, raw_labels, sample_rate] = pull_data(pt_num, pt_type, channels, iEEGid, iEEGpw)
%% pull_data.m
% Written by John Bernabei
% MD/PhD Candidate
% Center for Neuroengineering & Therapeutics
% University of Pennsylvania
% March 2020

% Inputs:
%           pt_num: patient number of annotation file 
%                   (NOT ieeg.org portal ID which is pt_name in this function)
%
%           pt_type: 1 for seizure, 2 for non-seizure, 3 for IIC
%
%           channels: What ieeg.org channel indices should be used
%
%           path_to_annots: What is the path to annotation files
%
%           iEEGid: string of ieeg.org ID for starting session
%
%           iEEGpw: string of password file for starting session ('jbe_ieeglogin.bin')

% Outputs:
%           raw_data: a data matrix of size samples x channels (microvolts)
%           
%           raw_times: a vector of all times of size samples x 1 (seconds)
%       
%           raw_labels: a vector of all labels of size samples x 1
%                       Class 0 = interictal, non-seizure
%                       Class 1 = seizure
%                       Class 3 = artifact (NOT ASSIGNED HERE)
%                       Class 4 = NaN
%
%           sample_rate: in Hz

%% 
    % Load annotations
    annot_file = load(sprintf('annot_%d.mat', pt_num));
    pt_name = annot_file.annot.patient;
    
    % Check if patient type = 1, meaning patient has seizures
    if pt_type == 1
        
        % Get interictal start and stop times
        ii_start = annot_file.annot.ii_start;
        ii_stop = annot_file.annot.ii_stop;
        
        % Get seizure start and stop times
        sz_start = annot_file.annot.sz_start;
        sz_stop = annot_file.annot.sz_stop;
        
        % Get number of seizures
        sz_num = length(sz_start); % Get number of seizures
        
        % Find when to start and stop dataset acquisition
        dataset_start = min([ii_start, ii_stop, sz_start, sz_stop]);
        dataset_stop = max([ii_start, ii_stop, sz_start, sz_stop]);
        
    % Check if patient type = 2, meaning patient is seizure free
    elseif pt_type == 2
        
        % Get interictal start and stop times
        ii_start = annot_file.annot.ii_start;
        ii_stop = annot_file.annot.ii_stop; 
        
        % Find when to start and stop dataset acquisition
        dataset_start = ii_start;
        dataset_stop = ii_stop;
        
    end
    
    % Create intervals, checking if patient has discrete seizures
    if pt_type==1
        
        % Set up a placeholder
        placehold = 0;
        
        % Loop through all seizures
        for j = 1:sz_num
            
            % Step placeholder forward
            placehold = placehold+1;
            
            % Define length of seizure interval
            int_length = length([sz_start(j):sz_stop(j)]);
            
            % Enter seizure intervals
            sz_intervals(placehold:(placehold+int_length-1)) = [sz_start(j):sz_stop(j)];
            
            % Step placehold forward
            placehold = placehold+int_length-1;
        end
        
        % All long intervals
        all_intervals = [dataset_start:dataset_stop];
             
    % If patient doesn't have discrete seizures...
    else
        
        % All second long intervals are simply dataset start and stop times
        all_intervals = [dataset_start:dataset_stop];
    end

    % Start session
    session = IEEGSession(pt_name, iEEGid, iEEGpw);
    
    % Acquire sampling rate
    sampleRate = session.data.sampleRate;
    
    % Find duration of EEG in units of samples
    durationInSamples = length(all_intervals)*sampleRate;

    % Initialize raw data matrix and raw time vector
    raw_data = [];
    raw_times = [];
    
    % Get number of hours in dataset rounded up (defines number of pulls)
    num_hours = ceil(durationInSamples./(sampleRate*60*60));
    
    % Initialize sample index
    sample_ind = 1;
    
    % Loop through number of hours
    for qq = 1:num_hours
        
        % Define chunk's start and stop time in seconds
        block_start = all_intervals(sample_ind);
        block_stop = all_intervals(sample_ind)+60*60;
        
        % Step sample index forward
        sample_ind = sample_ind+60*60;
        
        % Check if we have hit the stop of the block
        if block_stop > max(all_intervals)
            block_stop = all_intervals(end);
        end
        
        % Get the starting and stopping index
        ind_start = block_start*sampleRate;
        ind_stop = block_stop*sampleRate-1;
        
        % Print out acquisiton
        fprintf('Acquiring block %d of length %d hours\n',qq,(block_stop-block_start)/3600)
        
        % Acquire data and stack into data we already have
        raw_data = [raw_data; session.data.getvalues(ind_start:ind_stop,channels)];
        raw_times = [raw_times, block_start:1/sampleRate:(block_stop-1/sampleRate)];
        
    end
    
    % Print out how much data we have and size of matrices
    howMuchData = size(raw_data,1);
    fprintf('Pulled a total of %d hours of data\n',(howMuchData./(60*60*sampleRate)))
    fprintf('The raw data matrix has a size of %d by %d\n',size(raw_data,1),size(raw_data,2))
    fprintf('The raw time matrix has a size of %d by %d\n',size(raw_times,1),size(raw_times,2))
    

    % Establish feature vector. The size of this is
    % (sampleRate*dataset_time) x 1
    raw_labels = zeros(max(size(raw_data)),1);
    
    % Assign seizure intervals for patients with seizures
    if  pt_type == 1
        
        % Find overlap of data with seizure intervals to assign labels
        % correctly - each data point will have a label associated
        [IB] = find(ismember(floor(raw_times),(sz_intervals))==1);
        raw_labels(IB) = 1;
        
    end
    
    % rename sample rate
    sample_rate = sampleRate;

end