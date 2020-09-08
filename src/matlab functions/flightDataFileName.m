function filename = flightDataFileName(aircraft,date,num,matExtension)
% flightDataFileName Standard format for each IDG flight data mat file
if nargin == 3
    matExtension = 0
end

if class(num) ~= "string"
    num = string(num);
end

if class(date) == "datetime"
    date.Format = "dd-MM-uuuu";
    date = string(date);
end

filename = aircraft + "_" + date + "_" + num;

if matExtension == true
    filename = filename + ".mat";
end

end