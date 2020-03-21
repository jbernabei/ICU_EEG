function [all_TN, all_AdvRecall, all_num_sz_true, all_num_sz_detect, all_Recall, segs_per_hr, segs_num] = compute_metrics(pt_list, pt_type, results_struct)

    num_patients = length(pt_list);
    
    create_ROC = 1;
    
    for i = 1:num_patients
        pt_num = pt_list(i);

        % Extract Yhat and Ytest
        Yhat = results_struct(pt_num).Yhat;
        Ytest = results_struct(pt_num).Ytest;
        
        Y_score = results_struct(pt_num).score_vals;
        
        if create_ROC
           threshold_vec = [0.05:0.05:1];
        else 
            threshold_vec = 0.5;
        end
        
        for t = 1:length(threshold_vec)
            
            if size(Y_score,2)==0
                Yhat = 0;
            elseif size(Y_score,2)==1
                Yhat = Y_score-1;
            else
                Yhat = double(Y_score(:,2)>=threshold_vec(t));

            end

            if pt_type == 1
                all_TN(i,t) = sum((Yhat + Ytest)==0)./sum(Ytest == 0);
                
                diff_pred = diff(Yhat);
                segs_per_hr(i,t) = (sum(diff_pred>0)./length(Yhat))*720;
                segs_num(i,t) = (sum(diff_pred>0));
                total_segs_length(i,t) = sum(Yhat);
                
                
                % Calculate advanced recall, which is sensitivity to picking up
                % any part of the seizure
                [AdvancedRecall, num_sz_true, num_sz_detect] = AdvancedRecallMeasure(Yhat,Ytest);
                
                [IsolateInstances,TPrate,TNrate,Precision,Recall,F1,Adv_r] = JustMetrics(Yhat,Ytest);
                
                all_AdvRecall(i,t) = AdvancedRecall;
                all_num_sz_true(i,t) = num_sz_true;
                all_num_sz_detect(i,t) = num_sz_detect;
                
                all_Recall(i,t) = Recall;
                
            else
                all_TN(i,t) = sum((Yhat + Ytest)==0)./sum(Ytest == 0);
                diff_pred = diff(Yhat);
                segs_per_hr(i,t) = (sum(diff_pred>0)./length(Yhat))*720;
                segs_num(i,t) = (sum(diff_pred>0));
                total_segs_length(i,t) = sum(Yhat);
                all_AdvRecall = [];
                all_num_sz_true = [];
                all_num_sz_detect = [];
                all_Recall = [];
               
            end

        end


    end
    
end