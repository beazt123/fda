function nonlinFeatureTable = computeNonlinTimeDomainFeatures(inputSignal,variableNamePrefix)
%computeNonlinTimeDomainFeatures Computes Non linear features from a
%timetable
%   Takes in a timetable and computes the 3 non linear features: Lyapunov
%   exponent, correlation dim and Approximate entropy in a table form.
%   Variable name of the table is "data" by default, unless pecified by the
%   variable "variableNamePrefix"

if class(inputSignal) == "timetable" || class(inputSignal) == "table"
    if nargin == 1
        prefix = inputSignal.Properties.VariableNames{1};
    else
        prefix = variableNamePrefix;
    end
    
    if class(inputSignal) == "table"
        timeColumn = seconds(0:size(inputSignal,1)); % If a table is given, assume the values are evenly spaced secondly
    else
        timeColumn = inputSignal.Properties.RowTimes;
    end
    inputSignal = inputSignal.(inputSignal.Properties.VariableNames{1});

else
    prefix = variableNamePrefix;
end

if nargin == 1
    prefix = "data";
end


try
    % Compute nonlinear features.
    % Extract lag and embedding dimension.
    [~,lag,dim] = phaseSpaceReconstruction(inputSignal);

    % Extract individual feature values.
    data_ApproxEntropy = approximateEntropy(inputSignal,lag,dim);

    data_CorrelationDim = correlationDimension(inputSignal,lag,dim,'NumPoints',10);

    tNumeric = time2num(timeColumn,"seconds");
    Fs = effectivefs(tNumeric);
    data_LyapunovExp = lyapunovExponent(inputSignal,Fs,lag,dim, ...
        'ExpansionRange',[1 5]);

    % Concatenate signal features.
    featureValues = [data_ApproxEntropy,data_CorrelationDim,data_LyapunovExp];

    % Package computed features into a table.
    featureNames_suffix = ["ApproxEntropy","CorrelationDim","LyapunovExp"];
    featureNames = prefix + "_" + featureNames_suffix;
    nonlinFeatureTable = array2table(featureValues,'VariableNames',featureNames);
catch ME
    disp(ME.message)
    % Package computed features into a table.
    featureValues = NaN(1,3);
    featureNames_suffix = ["ApproxEntropy","CorrelationDim","LyapunovExp"];
    featureNames = prefix + "_" + featureNames_suffix;
    nonlinFeatureTable = array2table(featureValues,'VariableNames',featureNames);
end

end

