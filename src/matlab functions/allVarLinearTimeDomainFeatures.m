function featureRow = allVarLinearFreqDomainFeatures(tbl,vars)
%ALLVARLINEARTIMEDOMAINFEATURES Calculate all time domain features
%   For all variables in the table, or those specified in vars, calculate
%   the time domain features:

% - Mean
% - std
% - impulse factor
% - crest factor
% - shape factor
% - kurtosis
% - rms
% - peak value
% - clearance factor
% - SNR
% - SINAD
% - skewness
% - THD

if ~exist("vars",'var') || isempty(vars)
    varsToCalculateFeatures = string(tbl.Properties.VariableNames);
else
    varsToCalculateFeatures = vars;
end

featureRow = table;
for tblvar = 1:numel(varsToCalculateFeatures)
    featureRow = [featureRow, computeLinearTimeDomainFeatures(tbl(:,varsToCalculateFeatures(tblvar)))];
end




end

