function Neuron_binned_data=ConstructBinnedDataForNDT(SequentialAllSP,TrialIndex,bin_width,step_size,MeanTrialLength,Decodingclassifier)

raster_data=zeros(length(TrialIndex),MeanTrialLength*1000);%1ms per bin
for iTrial=1:length(TrialIndex)%go through each trial
    SpikeTime=SequentialAllSP{2,TrialIndex(iTrial)};
    raster_data(iTrial,ceil(SpikeTime*1000))=1;
end
% [~,c]=find(raster_data>0);
%%
the_bin_start_times=0:step_size:MeanTrialLength*1000-bin_width;
the_bin_start_times=the_bin_start_times+1;
Neuron_binned_data=zeros(length(TrialIndex),length(the_bin_start_times));
for iStep = 1:length(the_bin_start_times) %go through each step
    if Decodingclassifier==1||Decodingclassifier==3%max_correlation_coefficient_CL
        Neuron_binned_data(:, iStep) = sum(raster_data(:, the_bin_start_times(iStep):(the_bin_start_times(iStep) + bin_width -1)), 2)/(bin_width/1000);        
    elseif Decodingclassifier==2%poisson_naive_bayes_CL
        Neuron_binned_data(:, iStep) = sum(raster_data(:, the_bin_start_times(iStep):(the_bin_start_times(iStep) + bin_width -1)), 2);
    end
end