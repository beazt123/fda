function variableTypes = dtypes(tbl)
%dtypes Display data types of each variable in a table
%   Checks the data type of every column in a table. Returns a table where
%   the first column is the name of each variable in the table and the
%   second column is the 
var = tbl.Properties.VariableNames;

types = string;
for variable = 1:numel(var)
    types(variable) = string(class(tbl.(string(var(variable)))));
end

variableTypes = table([var'], [types'], 'VariableNames',{'Variable Names' 'Variable Types'});
end

