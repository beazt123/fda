function outputTable = differentiateTable(tbl, timeVar, vars, sameLength)
%DIFFERENTIATETABLE(tbl, timeVar, vars, sameLength) Uses diff function on the selected columns
% Takes in a table and selected table variable names and performs
% differentiation. Set sameLength = 0 if you want to retain the original
% result of diff. If not given, sameLength defaults to true and the
% function tries to make the output array of diff() the same length as the
% input array by extrapolation or duplication and appending of the last
% element. 
% timeVar is the table variable in tbl that corresponds to time. timeVar
% also accepts a numeric array of the same length as the number of rows in
% the table, either in duration or numeric form.       

    % if no timeVar, assume diff(t) = ones(size(tbl,1),1)
    if exist("timeVar","var")
        try
            if class(timeVar) == "string" || class(timeVar) == "char"
                t = tbl{:,string(timeVar)};
                if class(t) == "duration"
                    t = seconds(t); 
                end
            elseif class(timeVar) == "duration" && numel(timeVar) == size(tbl,1)
                t = seconds(timeVar);
            elseif isnumeric(timeVar) && numel(timeVar) == size(tbl,1)
                t = timeVar;
            else
%                 disp("all else failed")
                t = [1 2];
            end
        catch
%             disp("all else failed catch block")
            t = [1 2];            
        end
 
    elseif ~exist("timeVar","var") || isempty(timeVar)
%         disp("all else failed else block")
        t = [1 2];  
    end
    

    % if no vars, assume all vars    
    if ~exist("vars","var") || isempty(vars)
        vars = string(tbl.Properties.VariableNames);
    else
        vars = string(vars);
    end

    % if no sameLength, assume same length
    if ~exist("sameLength","var") || isempty(sameLength)
        sameLength = 1;
    end
    

    
    outputTable = table;    
    timeComponent = diff(t);  
    
    % If empty table is put in, return empty table
    if size(tbl,1) == 0
        emptycells = cell(1,numel(vars));
        if sum(contains(vars,"d_")) == 0
            d_Vars = "d_" + vars;
        else sum(contains(vars,"d_")) > 0;
            d_Vars = "d" + vars;
        end
        
        
        outputTable = table(emptycells{:},'VariableNames', d_Vars);
        return
    end
    
    for var = 1:numel(vars)
        if contains(vars(var),"d_")
            prefix = "d";
        else
            prefix = "d_";
        end
        
        df = diff(tbl{:,vars(var)}) ./ timeComponent;
        if sameLength == 1 %Extrapolate the last element to make the output the same dimension as the input
            try
                ndf = numel(df);
                last = interp1(1:ndf,df,ndf+1,"linear","extrap");
            catch
                last = df(end);
            end
            df = [df; last];
        end
        outputTable.(prefix + vars(var)) = df;
    end
end
