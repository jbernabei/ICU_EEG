function [results_struct] = machine_learning_test(model_struct,sz_list, partition_sz, nsz_list, partition_nsz)

    % Set up folds
    for k = 1:length(model_struct)
        pt_test_list = [sz_list(partition_sz==k); nsz_list(partition_nsz==k)];
         
        for i = 1:length(pt_test_list)
            
            % Extract patient number
            pt_no = pt_test_list(i);
            load(sprintf('feats_5_sec_%d.mat',pt_no));
            
            % Extract artifact indices
            art_inds = [find(labels==3); find(labels==4)];  
            
            % Ytest is the actual labels
            Ytest = labels;
            
            % Assign artifact indices to non-zero
            Ytest(art_inds) = 0;

            % Run model for that fold
            [Yguess_cell, score_vals] = predict(model_struct(k).rf,features);

            % Convert from cell to double
            Yhat = str2num(cell2mat(Yguess_cell));
            
            % Reassign artifact indices as non-seizure
            Yhat(art_inds) = 0;
            
            Yhat = VoteFiltering(Yhat,4,1);
            
            % Put results into structure
            results_struct(pt_no).Ytest = Ytest;
            results_struct(pt_no).Yhat = Yhat;
            results_struct(pt_no).score_vals = score_vals;
        end
    end
end