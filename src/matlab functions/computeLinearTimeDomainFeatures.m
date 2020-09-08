function outputTable = computeLinearTimeDomainFeatures(inputSignal,variableNamePrefix)
%computeLinearTimeDomainFeatures Calculates linear features from a signal
%   Takes in an array or a table(or timetable) with 1 column. If
%   table/timetable has multiple column, this function takes the 1st column
% Returns a table with names columns for each feature

if class(inputSignal) == "table" || class(inputSignal) == "timetable"
    if ~exist("variableNamePrefix",'var') || isempty(variableNamePrefix)
        prefix = inputSignal.Properties.VariableNames{1};
    else
        prefix = variableNamePrefix;
    end
    inputSignal = inputSignal.(inputSignal.Properties.VariableNames{1});
elseif exist("variableNamePrefix",'var') ~= 1 || isempty(variableNamePrefix)
    prefix = "data";
end


try
    % Compute signal features.
    data_ClearanceFactor = max(abs(inputSignal))/(mean(sqrt(abs(inputSignal)))^2);
    data_CrestFactor = peak2rms(inputSignal);
    data_ImpulseFactor = max(abs(inputSignal))/mean(abs(inputSignal));
    data_Kurtosis = kurtosis(inputSignal);
    data_Mean = mean(inputSignal,'omitnan');
    data_PeakValue = max(abs(inputSignal));
    data_RMS = rms(inputSignal,'omitnan');
    data_SINAD = sinad(inputSignal);
    data_SNR = snr(inputSignal);
    data_ShapeFactor = rms(inputSignal,'omitnan')/mean(abs(inputSignal),'omitnan');
    data_Skewness = skewness(inputSignal);
    data_Std = std(inputSignal,'omitnan');
    data_THD = thd(inputSignal);

    % Concatenate signal features.
    featureValues = [data_ClearanceFactor,data_CrestFactor,data_ImpulseFactor,data_Kurtosis,data_Mean,data_PeakValue,data_RMS,data_SINAD,data_SNR,data_ShapeFactor,data_Skewness,data_Std,data_THD];

    % Package computed features into a table.    
    featureNames_suffixes = ["ClearanceFactor","CrestFactor","ImpulseFactor","Kurtosis","Mean","PeakValue","RMS","SINAD","SNR","ShapeFactor","Skewness","Std","THD"];
    featureNames = prefix + "/" + featureNames_suffixes;
    outputTable = array2table(featureValues,'VariableNames',featureNames);
    
catch ME
    % Package computed features into a table.
%     disp("Failed to calculate features. Returning NaN value table")
%     disp(ME.message)
    featureValues = NaN(1,13);
    featureNames_suffixes = ["ClearanceFactor","CrestFactor","ImpulseFactor","Kurtosis","Mean","PeakValue","RMS","SINAD","SNR","ShapeFactor","Skewness","Std","THD"];
    featureNames = prefix + "/" + featureNames_suffixes;
    outputTable = array2table(featureValues,'VariableNames',featureNames);
end




end
