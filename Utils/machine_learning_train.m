function [model] = machine_learning_train(sz_list, partition_sz, nsz_list, partition_nsz, penalty_val)

    % Determine number of folds that have been used
    num_folds = length(unique(partition_sz));
    
    % Loop through folds training that number of models
    for qq = 1:num_folds
    
        % Assemble train set
        pt_train_list = [sz_list(partition_sz~=qq); nsz_list(partition_nsz~=qq)];
    
        % Initialize blank feature and label matrices;
        all_feats = [];
        all_labels = [];
    
        % Loop through patients to create training matrix and labels
        for i = 1:length(pt_train_list)
            
            % Extract patient number
            pt_no = pt_train_list(i);
            
            % Load feature matrix
            load(sprintf('Features/feats_3_sec_%d.mat',pt_no));

            % Add to training matrix and labels
            all_feats = [all_feats;features];
            all_labels = [all_labels;labels];
            
        end
    
    % Find artifact and NaN indices
    art_inds = [find(all_labels==3); find(all_labels==4)];
    
    % Remove these from training data and labels
    all_feats(art_inds,:) = [];
    all_labels(art_inds) = [];
    
    % Define classes, 0 = non seizure, 1 = seizure
    ClassNames = [0,1];

    % Define costs -> penalty here is 500
    cost.ClassNames = ClassNames;
    cost.ClassificationCosts = [0 1; penalty_val 0];

    % Train random forest classifier
    model(qq).rf = TreeBagger(400,all_feats,all_labels,'cost',cost);
    
    end
    
end