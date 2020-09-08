function outputFeature = featureArithmetic(dualColumnTable, ops, outVarName, reverse, innerTableVarName)
% Performs basic math on 2 numerical feature columns
% A feature column is a single column of a data ensemble
% Below are the acceptable strings for "ops":

% To add:       'add', 'total', 'sum', '+' 
% To subtract:  '-', 'minus', 'difference', 'subtract'
% To multiply:  'product', 'multiply', 'times', 'x', '.*', '*'
% To divide:    'divide', 'quotient', 'over', 'fraction', './', '/'

if nargin == 4
    innerTableVarName = "data";
elseif nargin == 3
    reverse = 0;
    innerTableVarName = "data";
elseif nargin == 2
    outVarName = "NewVar";
    reverse = 0;
    innerTableVarName = "data";
elseif nargin == 1
    outVarName = "NewVar";
    ops = 'minus';
    reverse = 0;
    innerTableVarName = "data";
end

if reverse
    dualColumnTable = movevars(dualColumnTable, dualColumnTable.Properties.VariableNames{1},'After',size(dualColumnTable.Properties.VariableNames,2));
end

% each row will be passed in as comma separated variables
outputFeature = rowfun(@(column1, column2) ModTable(column1, column2, ops, innerTableVarName), dualColumnTable, 'SeparateInputs', 1, 'OutputVariableNames', outVarName,'ExtractCellContents',1);

end

%helper functions
function outTable = ModTable(col1, col2, operation, columnName)
    % Make sure extract is a table with 2 columns
    % before passing into tableArithmetic()
    
    extract = [renamevars(col1,col1.Properties.VariableNames{1},"var1") renamevars(col2,col2.Properties.VariableNames{1},"var2")];
    outTable = {tableArithmetic(extract, operation, columnName)};
end

function outputTable = tableArithmetic(extract, operation, columnName)

if nargin == 1
    operation = "minus";
end

expectedArithmeticOps = {'add' 'total' 'sum' '+' '-' 'minus' 'difference' 'subtract' 'product' 'multiply' 'times'...
     'x' '.*' '*' 'divide' 'quotient' 'over' 'fraction' './' '/'};
try
    operation = validatestring(operation, expectedArithmeticOps);
catch ME
    disp("Unknown operation. Use only 1 of the operations below:")
    disp(expectedArithmeticOps')
end

switch operation
    case {'add' 'total' 'sum' '+'}
        func = @(a,b) a+b;
    case {'minus' 'difference' 'subtract' '-'}
        func = @(a,b) a-b;
    case {'product' 'multiply' 'times' 'x' '.*' '*'}
        func = @(a,b) a.*b;
    case {'divide' 'quotient' 'over' 'fraction' './' '/'}
        func = @(a,b) a./b;
    otherwise
        disp(operation)
        disp("Unknown operation. Aborting...")
        outTable = 0;
        return
end
outputTable = rowfun(func ,extract, 'SeparateInputs', 1, 'OutputVariableNames', columnName);
end

