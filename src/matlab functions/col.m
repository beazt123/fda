function columnForm = col(inputArg1)
%col Forces an array to be in column form
%   Takes in a vector, whether or not it is in column or row form and
%   returns a column form.
    if ~iscolumn(inputArg1)
        columnForm = inputArg1';
    else
        columnForm = inputArg1;
    end
end

