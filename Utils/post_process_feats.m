function [processed_features, remove_ind, personalized_feats, which_feature] = post_process_feats(raw_feats, reject_params)

% raw_feats -> dimensions of rows: num_feats*channel_num
%                            cols: num_windows
% The rows are grouped by feature so all channels corresponding to feature
% one are grouped together first

% num_feats -> simply the number of different features that were calculated

% channel_num -> simply the number of channels

% inds_removed -> the indices of which columns of the original feature
% vector that were removed 

% num_windows -> the number of segments we are calculating

%%

% Check each channel for violating each rejection param
for k = 1:size(raw_feats,1)
 
    % Check whether each channel meets criteria across parameters
    ch_rejection(:,k) = [reject_params.thresholds<raw_feats(k,:)]';
    
    amount_reject(k) = mean(ch_rejection(:,k));
end

% Find which channels were used for rejection
which_feature = sum(ch_rejection,2);

% Find which channels should be rejected
use_channels = find(amount_reject < reject_params.reject_thresh);

% Check if at least 3 channels should be rejected
if (18-length(use_channels)) > reject_params.num_reject_ch
    
    % Indicate that this segment should be removed
    remove_ind = 1;
    
    % calculate mean across channels
    mean_feats = mean(raw_feats);

    % calculate variance across channels
    var_feats = var(raw_feats);
    
    % Calculate personalized feats
    personalized_feats = reshape(raw_feats,[1,180]);

    % return everything
    processed_features = [mean_feats, var_feats];
    
else
    
    remove_ind = 0;
    
    %size(raw_feats)
    
    %raw_feats(use_channels,:)
    
    % calculate mean across channels
    mean_feats = mean(raw_feats(use_channels,:));

    % calculate variance across channels
    var_feats = var(raw_feats(use_channels,:));
    
    % Calculate personalized feats
    personalized_feats = reshape(raw_feats,[1,180]);

    % return everything
    processed_features = [mean_feats, var_feats];

end


    
end