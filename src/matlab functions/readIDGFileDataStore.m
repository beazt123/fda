function data = readIDGFileDataStore(filepath)
% function to read from fileDatastore
    data = readtable(filepath,'PreserveVariableNames',0);
    data = convertvars(data,@iscellstr,'string');
    
    % Ignore the first line of data
    data = data(2:end,:);
    if ismember("Current Date",string(data.Properties.VariableNames))
        data.("Current Date").Format = 'dd-MMM-uu';
        data.("Current Date") = datetime(string(data.("Current Date")), 'InputFormat', 'dd-MMM-yy');
    end
end

