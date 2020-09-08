function first_row = freq_domain_features(inputFeature, variableNamePrefix)
%FREQ_DOMAIN_FEATURES Calculates all frequency domain features from a single
%feature column
% Takes in a feature column and calculates all frequency domain features.
% Returns a table with the columns names in the following format:
% <parameter name>/<feature name>
% if variableNamePrefix is not provided, the function will automatically
% use the only column name available in inputFeature.

if nargin == 1
    variableNamePrefix = inputFeature.Properties.VariableNames{1};
end

inputFeatureCellArr = inputFeature.(inputFeature.Properties.VariableNames{1});
featureRowArray = cellfun(@(inputSignal) computeSpectralFeatures(inputSignal,variableNamePrefix),...
    inputFeatureCellArr,'UniformOutput',0);

first_row = featureRowArray{1};
for row = 2:numel(featureRowArray)
    first_row = [first_row; featureRowArray{row}];
end

end