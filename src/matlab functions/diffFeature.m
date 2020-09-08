function diffColumn = diffFeature(col,colName,operation)
% column should be a cell array(of timetables) or a 
% table(of timetables) with only 1 variable

% Use the diff() function by default
if nargin == 2
    operation = "diff";
end

if class(col) == "table"
    if nargin == 1
        colName = strcat("d_",col.Properties.VariableNames{1});
    end
    col = [col{:,1}];
elseif class(col) == "cell"
    if nargin == 1
        colName = "diffVar";
    end
end


if operation == "diff"
    diffColumn = cell2table(cellfun(@(dft) diffTimetable(dft,"data"),col),'VariableNames',colName);

elseif operation == "grad" | operation == "gradient"
    diffColumn = cell2table(cellfun(@gradTimetable,col),'VariableNames',colName);

end



end

% Helper function
function diff_Timetable = diffTimetable(timetbl,colname)
%UNTITLED Summary of this function goes here
%   Derivative of a variable of a timetable with a duration column
% Timetable must contain only 1 variable other than time
% Alternatively, timetbl can be a table with a single variable

if class(timetbl) == "table"
    dt = 1;
elseif class(timetbl) == "timetable"
    dt = diff(seconds(timetbl.Properties.RowTimes));
end  

diff_feature = diff(timetbl{:,end}) ./ dt;
var = timetbl.Properties.VariableNames{1};
diff_Timetable = timetbl(1:end-1,:);
diff_Timetable = renamevars(diff_Timetable,var,colname);

diff_Timetable.(colname) = diff_feature;
diff_Timetable = {diff_Timetable};

end

% Helper function
function grad_Timetable = gradTimetable(timetbl)
%UNTITLED Summary of this function goes here
%   Derivative of a variable of a timetable with a duration column
% Timetable must contain only 1 variable other than time
% Alternatively, timetbl can be a table with a single variable

if class(timetbl) == "table"
    dt = 1;
elseif class(timetbl) == "timetable"
    dt = gradient(seconds(timetbl.Properties.RowTimes));
end  

grad_feature = gradient(timetbl{:,end}) ./ dt;
var = timetbl.Properties.VariableNames{1};
grad_Timetable = timetbl;

% Replace inf with nan
% grad_feature = arrayfun(@replaceInfwNaN, grad_feature);

grad_Timetable.(var) = grad_feature;
grad_Timetable = {grad_Timetable};

end

