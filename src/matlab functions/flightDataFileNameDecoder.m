function [aircraft, date, num] = flightDataFileNameDecoder(filename, stringOutput)
%flightDataFileNameDecoder File naming protocol
% Takes in file path, returns it in 3 parts: Aircraft, date(datetime), num(int16)
% Date and num will be converted to the appropriate data types
% Optional to leave them as strings
    if nargin == 1
        stringOutput = 0;
    end
    
    [~, name, ~] = fileparts(filename);
    filenameParts = split(name,"_");
    [aircraft, dateStr, numStr] = filenameParts{:};
    
    if stringOutput == 0
        date = datetime(dateStr,"InputFormat","dd-MM-uuuu");
        date.Format = "dd-MM-uuuu";
        num = str2double(numStr);
    else
        date = dateStr;
        num = numStr;
    end
end
