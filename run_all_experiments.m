%% Run all experiments

% ICU EEG project
% John Bernabei

%% Set up workspace
clear all; % Clear all data structures

% Whether to run each portion
run_features = 1; % Set to 1 to calculate & save features
train_ML = 1; % Set to 1 to train classifiers
test_ML = 1; % Set to 1 to test classifiers
analyze_results = 1; % Set to 1 to analyze results
make_figures = 1; % Set to 1 to make figures
save_results = 1; % Set to 1 to save results


iEEGid = 'jbernabei'; % Change this for different user
iEEGpw = 'jbe_ieeglogin.bin'; % Change this for different user

% Set up patients
all_pt_info = readtable('patient_table.csv');

% Extract patient list
pt_list = all_pt_info{:,2}; % The number of the annotation file

% Extract patient types
pt_type_list = all_pt_info{:,3}; % 1 = discrete sz, 2 = sz free

%% Set up important variables 

% Set window length
win_len = 5; % seconds

% Set up artifact rejection thresholds
% mean, variance, delta, theta, alpha, beta, LL, enveope, kurtosis, entropy
reject_params.thresholds = [0.25 2000 400 200 200 1000 2e4 40 10 50*10^6];
reject_params.reject_thresh = 0.5;
reject_params.num_reject_ch = 3;

% Machine learning classifier
classifier_type = 'random_forest';

% Number of folds
num_folds = 5;

% set up channels
channels = [3 4 5 9 10 11 12 13 14 16 20 21 23 24 31 32 33 34];

% Set machine learning penalty
penalty_val = 500;

%% Calculate features
if run_features
    for i = 1
        % Get patient number
        pt_num = pt_list(i)
        
        if pt_num < 33 || pt_num == 92 || pt_num == 93 || pt_num == 94
            channels = [3 4 5 9 10 11 12 13 14 16 20 21 23 24 31 32 33 34];
        else
            channels = [3 4 5 8 9 10 11 12 13 14 16 17 18 19 24 25 26 27];
        end

        % Get patient type
        pt_type = pt_type_list(i); 

        % Use pull_data function to get data (size), times (size), and labels (size)
        [raw_data, raw_times, raw_labels, sample_rate] = pull_data(pt_num, pt_type, channels, iEEGid, iEEGpw);
        
        incorrect_artifact = [];
        
        a = 0;
        
        while isempty(incorrect_artifact)
            fprintf('starting feature calculation loop \n')
            % Use moving_Window function to calculate all features
            [features, num_removed, labels, time_windows, incorrect_artifact, bad_rejection_criteria, individual_features] = sliding_window(raw_data, sample_rate, win_len, raw_labels, raw_times(1), reject_params);

            sprintf('rejected %d windows of artifact\n',num_removed)
                            
            if ~isempty(incorrect_artifact) && (a<10)
                
                reject_params.thresholds = reject_params.thresholds.*1.5
                
                fprintf('Increasing rejection threshold criteria\n')
                
                size(bad_rejection_criteria)
                
                incorrect_artifact = [];
                
                a = a+1;
                
            else

                incorrect_artifact = 1;
                
            end
            
        end
        
        fprintf('Finish calculating features\n')
        
        % Save all features
        save(sprintf('Features/feats_5_sec_%d.mat',pt_num),'features', 'num_removed', 'labels', 'time_windows')

    end
end

%% Train machine learning
if train_ML
    
    % Create train / test split
    sz_list = pt_list(pt_type_list==1); % extract all patients with seizures
    nsz_list = pt_list(pt_type_list==2); % extract all patients without seizures

    % Partition patients into each different type
    partition_sz = make_xval_partition(length(sz_list), num_folds);
    partition_nsz = make_xval_partition(length(nsz_list), num_folds);

    % Train machine learning classifier
    model_struct = machine_learning_train(sz_list, partition_sz, nsz_list, partition_nsz, penalty_val);
    
    % Save results
    save('Models/model_struct_5_sec.mat','model_struct','partition_sz','partition_nsz','partition_iic','-v7.3')
    
end

%% Test machine learning
if test_ML
    
    % Run machine learning testing pipeline
    [results_struct] = machine_learning_test(model_struct,sz_list, partition_sz, nsz_list, partition_nsz, iic_list, partition_iic);

    % Save machine learning test results
    save('Results/results_struct_5_1.mat','results_struct')
    
end

%% Analyze machine learning
if analyze_results
    
    % Load desired results
%     load('Results/results_struct_5_1.mat')
    
    % Analyze all raw results for patients with seizures
    [TN, AdvRecall, num_sz_true, num_sz_detect, all_Recall, segs_per_hour, segs_num] = compute_metrics(sz_list, 1, results_struct);

    % Analyze all raw results for patients without seizures
    [TN_free, x, y, z, w, segs_per_hour_f, segs_num_f] = compute_metrics(nsz_list, 2, results_struct);
    
    
end

%% Create plots
if make_figures
    
    figure(1);clf;
    histogram(AdvRecall(:,10),10)
    
    % Set up color pallette
    color_pallette = [78 172 91;
                246 193 67;
                78 171 214;
                103 55 155]/255;
            
%     % FIGURE 1:
%     figure(1);clf;hold on
%     
%     TPR1 = null_TN(1:27,:);
%     FPR1 = null_Recall(1:27,:);
%     
%     TPR2 = TN(1:27,:);
%     FPR2 = all_Recall(1:27,:);
% 
%     mean_TPR1 = mean(TPR1); mean_FPR1 = mean(FPR1);
% 
%     sem_TPR1 = std(TPR1,1)./sqrt(size(TPR1,1)); sem_FPR1 = std(FPR1,1)./sqrt(size(FPR1,1));
%     
%     mean_TPR2 = mean(TPR2); mean_FPR2 = mean(FPR2);
% 
%     sem_TPR2 = std(TPR2,1)./sqrt(size(TPR2,1)); sem_FPR2 = std(FPR2,1)./sqrt(size(FPR2,1));
%     
%     shadedErrorBar(mean_FPR1,mean_TPR1,sem_TPR1,'lineprops',{'markerfacecolor','red'})
%     shadedErrorBar(mean_FPR2,mean_TPR2,sem_TPR2,'lineprops',{'markerfacecolor','blue'})
% 
%     % Label x and y axes
%     xlabel('Mean data reduction')
%     ylabel('Mean seizure sensitivity')
%     hold off
            
    % FIGURE 2: 
    % Plot of mean/median patient level seizure sensitivity versus data reduction
    figure(2);clf; hold on

    TPR = [TN;TN_free];
    FPR = AdvRecall(1:27,:);

    mean_TPR = mean(TPR);
    mean_FPR = mean(FPR);

    sem_TPR = std(TPR,1)./sqrt(size(TPR,1));
    sem_FPR = std(FPR,1)./sqrt(size(FPR,1));

    % Make a shaded error bar plot
    shadedErrorBar(mean_FPR,mean_TPR,sem_TPR,'lineprops',{'markerfacecolor','red'})

    % Label x and y axes
    xlabel('Mean data reduction')
    ylabel('Mean seizure sensitivity')
    hold off

    % Scatter plot of data reduction in patients with seizures vs without seizures
    figure(3);clf; hold on
    scatter_plot_axis = [ones(1,length(sz_list)),2*ones(1,length(nsz_list))];
    scatter(ones(1,length(sz_list)),TN(:,10),'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
    scatter(2*ones(1,length(nsz_list)),TN_free(:,10),'jitter','on','MarkerEdgeColor',color_pallette(4,:),'MarkerFaceColor',color_pallette(4,:))
    
    plot([(1-0.15); (1 + 0.15)], [mean(TN(:,10)),mean(TN(:,10))], 'k-','Linewidth',2)
    plot([(2-0.15); (2 + 0.15)], [mean(TN_free(:,10)),mean(TN_free(:,10))], 'k-','Linewidth',2)
    
    axis([0.5 2.5 0 1.1])
    hold off
    
    % Scatter plot of different advanced recalls
    figure(4);clf
    hold on
    scatter(ones(1,length(sz_list)),AdvRecall(:,10),'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
    scatter(2*ones(1,length(sz_list)),semi_final_AdvRecall,'jitter','on','MarkerEdgeColor',color_pallette(2,:),'MarkerFaceColor',color_pallette(2,:))
    scatter(3*ones(1,length(sz_list)),final_AdvRecall,'jitter','on','MarkerEdgeColor',color_pallette(4,:),'MarkerFaceColor',color_pallette(4,:))
    axis([0.5 3.5 0 1.1])
    
    plot([(1-0.15); (1 + 0.15)], [mean(AdvRecall(:,10)),mean(AdvRecall(:,10))], 'k-','Linewidth',2)
    plot([(2-0.15); (2 + 0.15)], [mean(semi_final_AdvRecall),mean(semi_final_AdvRecall)], 'k-','Linewidth',2)
    plot([(3-0.15); (3 + 0.15)], [mean(final_AdvRecall),mean(final_AdvRecall)], 'k-','Linewidth',2)
    
    title('Base vs semi adaptive seizure sensitivity')
    hold off
    
    figure(5);clf
    hold on
    scatter(ones(1,length(sz_list)),TN(:,10),'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
    scatter(2*ones(1,length(sz_list)),semi_final_TN,'jitter','on','MarkerEdgeColor',color_pallette(2,:),'MarkerFaceColor',color_pallette(2,:))
    axis([0.5 2.5 0 1.1])
    
    [p3,h3] = signrank(TN(:,10),semi_final_TN)
    
    plot([(1-0.15); (1 + 0.15)], [mean(TN(:,10)),mean(TN(:,10))], 'k-','Linewidth',2)
    plot([(2-0.15); (2 + 0.15)], [mean(semi_final_TN),mean(semi_final_TN)], 'k-','Linewidth',2)
    
    title('Base vs semi adaptive data reduction')
    hold off
    
    figure(6);clf
    hold on
    scatter(ones(1,length(nsz_list)),TN_free(:,10),'jitter','on','MarkerEdgeColor',color_pallette(1,:),'MarkerFaceColor',color_pallette(1,:))
    scatter(2*ones(1,length(nsz_list)),semi_free_TN,'jitter','on','MarkerEdgeColor',color_pallette(2,:),'MarkerFaceColor',color_pallette(2,:))
    axis([0.5 2.5 0 1.1])
    
    [p4,h4] = signrank(TN_free(:,10),semi_free_TN)
    
    plot([(1-0.15); (1 + 0.15)], [mean(TN_free(:,10)),mean(TN_free(:,10))], 'k-','Linewidth',2)
    plot([(2-0.15); (2 + 0.15)], [mean(semi_free_TN),mean(semi_free_TN)], 'k-','Linewidth',2)
    
    title('Base vs semi adaptive data reduction sz free')
    hold off
end
%% Create data visualization figure

% Determine which patients to show.
% Load feature matrix
load('Features/feats_5.mat'); %RID0064 ->
Ytest = results_struct(5).Ytest;
Yhat = results_struct(5).Yhat;
figure(1);clf;
hold on
plot(time_windows,Ytest,'rs','MarkerSize',20,'markeredgecolor',color_pallette(3,:),'markerfacecolor',color_pallette(3,:))
plot(time_windows,Yhat,'rs','MarkerSize',8,'markeredgecolor',color_pallette(4,:),'markerfacecolor',color_pallette(4,:))
hold off

%%
load('Features/feats_23.mat'); %RID00249 -> >99% data reduction, 72% sensitivity for 18 seizures
Ytest = results_struct(23).Ytest;
Yhat = results_struct(23).Yhat;
figure(2);clf;
hold on
plot(time_windows,Ytest,'rs','MarkerSize',20,'markeredgecolor',color_pallette(3,:),'markerfacecolor',color_pallette(3,:))
plot(time_windows,Yhat,'rs','MarkerSize',8,'markeredgecolor',color_pallette(4,:),'markerfacecolor',color_pallette(4,:))
hold off
%%
load('Features/feats_2.mat'); % RID0061 -> 92% data reduction, 100% sensitivity for 39 seizures
Ytest = results_struct(2).Ytest;
Yhat = results_struct(2).Yhat;
figure(2);clf;
hold on
plot(time_windows,Ytest,'rs','MarkerSize',20,'markeredgecolor',color_pallette(3,:),'markerfacecolor',color_pallette(3,:))
plot(time_windows,Yhat,'rs','MarkerSize',8,'markeredgecolor',color_pallette(4,:),'markerfacecolor',color_pallette(4,:))
hold off
