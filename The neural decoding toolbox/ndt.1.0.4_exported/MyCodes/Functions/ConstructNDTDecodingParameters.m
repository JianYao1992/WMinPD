function [ds,the_cross_validator]=ConstructNDTDecodingParameters(binned_data, stimulus_ID, num_cv_splits,bin_width...
    ,num_times_to_repeat_each_label_per_cv_split,IsShffleDecoding,num_neuron_ForDecoding,StartTime,step_size...
    ,MeanTrialLength,NotComputeLastSecondNum,Decodingclassifier,IsCalculateTCTDecodingResults,num_resample_runs)


%% Step 2: Create a datasource object
%disp('-----Step 2 Create a datasource object-----')
% create the basic datasource object
if Decodingclassifier==2
    binned_site_info.binning_parameters.bin_width=bin_width;
    save('PNBBinnedData','binned_data','binned_site_info')
    % if using the Poison Naive Bayes classifier, load the data as spike counts by setting the load_data_as_spike_counts flag to 1
    ds = basic_DS('PNBBinnedData', stimulus_ID, num_cv_splits, 1);
else
    ds = basic_DS(binned_data, stimulus_ID, num_cv_splits);
end
% can have multiple repetitions of each label in each cross-validation split (which is a faster way to run the code that uses most of the data)
ds.num_times_to_repeat_each_label_per_cv_split= num_times_to_repeat_each_label_per_cv_split;
%defien wether perform decoding analysis with shuffle data
ds.randomly_shuffle_labels_before_running=IsShffleDecoding;
% optionally can specify particular sites/neurons to use
ds.sites_to_use = find_sites_with_k_label_repetitions(stimulus_ID, num_cv_splits);
if num_neuron_ForDecoding>length(ds.sites_to_use)
    num_neuron_ForDecoding=length(ds.sites_to_use)-1;
end
%define the neuron number used to perform decoding analysis
ds.num_resample_sites =num_neuron_ForDecoding;
%define the event period used to perform decoding
BinStart=StartTime*1000/step_size+1;
BinEnd=floor(MeanTrialLength-NotComputeLastSecondNum)*1000/step_size;
ds.time_periods_to_get_data_from = num2cell(BinStart:BinEnd);
%% Step 3.  Create a feature preprocessor object
%disp('-----Step 3 Create a feature preprocessor object-----')
% create a feature preprocess that z-score normalizes each feature
the_feature_preprocessors{1} = zscore_normalize_FP;
%% Step 4.  Create a classifier object
%disp('-----Step 4 Create a classifier object-----')
% select a classifier
if Decodingclassifier==1
    the_classifier = max_correlation_coefficient_CL;
elseif Decodingclassifier==2
    % use a poisson naive bayes classifier (note: the data needs to be loaded as spike counts to use this classifier)
    the_classifier = poisson_naive_bayes_CL;
elseif Decodingclassifier==3
    % use a support vector machine (see the documentation for all the optional parameters for this classifier)
    the_classifier = libsvm_CL;
end
%% Step 5.  create the cross-validator
%disp('-----Step 5 create the cross-validator-----')
if Decodingclassifier~=2%MCC, SVM
    the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);
else%integers were needed for PNB classifier
    the_cross_validator = standard_resample_CV(ds, the_classifier);
end
the_cross_validator.num_resample_runs = num_resample_runs;
%more accurate results, but to save time we are using a small number here
if IsCalculateTCTDecodingResults==0
    the_cross_validator.test_only_at_training_times = 1;
end
the_cross_validator.display_progress.zero_one_loss=0;
the_cross_validator.display_progress.resample_run_time=0;
