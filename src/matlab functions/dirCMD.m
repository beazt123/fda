function dirOutput = dirCMD(filepath)
    % dirCMD Use dir programmatically as if using the command line
    % Takes in file path and returns a string array without the '.' & '..' 
    % directories.
    a=dir(filepath);
    
    % Eliminate the '.' & '..'
    b=a({a.name}~="." & {a.name}~="..");
    
    % Merge the folder & name columns as a string
    folder = string({b.folder});
    name=string({b.name});
    dirOutput = fullfile(folder,name);
end

