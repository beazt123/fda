function status = parsave(path,tbl,v73)
% parsave Calls save in a parallel for loop
% Saves the variable under the name "tbl" into the specified file path
if nargin == 2 
    v73 = 0;
end

if v73 == 1
    save(path,"tbl",'-v7.3')
    status=1;

elseif v73 == 0
    save(path,"tbl")
    status=1;

else
    disp("Unknown input for v73")
    status = 0;
end
    
end