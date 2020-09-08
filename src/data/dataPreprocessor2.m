% This script loops thru all the tables:
% - removes the unwanted parameters
% - separates each table into 2 parts(1 for each generator)
% - Calculates the 1st & 2nd deriatives of each selected parameter
% - Saves the result as a struct:
% Struct:
    %- gen1
    %- gen2
    
Conf = config;
% PATH_TO_IDG_RAW_CLEAN_DATA = Conf.PATH_TO_IDG_RAW_CLEAN_DATA;
SELECTED_DATA_COLUMNS = string(Conf.SELECTED_DATA_COLUMNS);
AIRCRAFTS = Conf.AIRCRAFTS;
PATH_TO_IDG_TRANSFORMED_DATA = Conf.PATH_TO_IDG_TRANSFORMED_DATA;
dataMinMax = Conf.dataMinMax;
cleanDataMasterList = fullfile(PATH_TO_IDG_TRANSFORMED_DATA,"dataMasterList.mat");

mat_file = load(cleanDataMasterList);
dataMasterList = mat_file.data;
filteredDataMasterList = dataMasterList(ismember(dataMasterList.Aircraft,AIRCRAFTS), :);
%%
parfor row = 1:size(filteredDataMasterList,1)
    aircraftData = filteredDataMasterList(row,:);
    currentAircraft = aircraftData.Aircraft;
    allFlightData = aircraftData.data{1};
    
    flightDataFilepaths = allFlightData.filepath;
    
    for flight = 1:size(flightDataFilepaths,1)
    	singleFlightData = allFlightData(flight,:);
        filepath = singleFlightData.filepath;
        [path, name, ext] = fileparts(filepath);
        [aircraft, date, num] = flightDataFileNameDecoder(name);
        
        % Save the file in the target filepath
        path_to_save = fullfile(PATH_TO_IDG_TRANSFORMED_DATA,currentAircraft);
        full_path_to_save = fullfile(path_to_save,name + ext);
        
        saving = true;
        if exist(full_path_to_save,"file") ~= 2
            ME = MException("NoFileFound:Nofile","No pre-procssed file. Run dataPreprocessor1.mlx first");
            throw(ME)
        end 
        
        flight_matfile = load(filepath);
        
        
        for gen = 1:2
            genData = flight_matfile.("gen" + string(gen));
            if any(contains(string(genData.Properties.VariableNames),"norm"))
                continue
            end
            
            paramsToNormalise = [genData.Properties.CustomProperties.PARAMS.SELECTED_GEN_PARAMS,...
                genData.Properties.CustomProperties.PARAMS.d_SELECTED_GEN_PARAMS,...
                genData.Properties.CustomProperties.PARAMS.dd_SELECTED_GEN_PARAMS];
            
            notUsed = size(genData,1) == 0;
            if notUsed   
                bigNormalisedTable = table;
                for param = 1:numel(paramsToNormalise)
                    bigNormalisedTable.(paramsToNormalise(param) + "_norm") = zeros(0);
                end
                
                genData = [genData bigNormalisedTable];
                finalTbl = table2timetable(genData);
                
                finalTbl = addprop(finalTbl, {'Vars', 'FlightDetails', 'Features'}, ...
                    {'table', 'table', 'table'});
                vars = string(finalTbl.Properties.VariableNames);
                finalTbl.Properties.CustomProperties.Vars.NormData = vars(contains(vars,"norm"));
                finalTbl.Properties.CustomProperties.Vars.Data = setdiff(vars, ...
                    [finalTbl.Properties.CustomProperties.Vars.NormData, ...
                    finalTbl.Properties.CustomProperties.PARAMS.INDEPENDENT_PARAMS]);
                finalTbl.Properties.CustomProperties.FlightDetails.Date = date;
                finalTbl.Properties.CustomProperties.FlightDetails.Num = num;
                finalTbl.Properties.CustomProperties.FlightDetails.Aircraft = aircraft;
                
                flight_matfile.("gen" + string(gen)) = finalTbl;
                if size(finalTbl,2) ~= 37 && size(finalTbl,2) ~= 36 || class(finalTbl) ~= "timetable"
                    gong=load("gong.mat");sound(gong.y)
                    head(finalTbl)
                    ME = MException("BadTableFormat:IncorrectNumberOfColumns", "Empty Table does not have 37 columns");
                    throw(ME)
                end
                
                continue
            end          
            
            
            try
                genData = genData(genData.FlightPhase >= 3 & genData.FlightPhase <= 12,:);
            catch
                L = size(genData,1);
                lowerIdx = ceil(Conf.("gen"+string(gen)).TIME_TO_PHASE_3 * L);
                upperIdx = ceil(L - Conf.("gen"+string(gen)).TIME_TO_END_FROM_PHASE_12 * L);
                genData = genData(lowerIdx:upperIdx,:);
            end
            
            
            normalisedTbl = table;
            for param = 1:numel(paramsToNormalise)
                minimum = dataMinMax.("gen" + string(gen)).(paramsToNormalise(param)).Min;
                maximum = dataMinMax.("gen" + string(gen)).(paramsToNormalise(param)).Max;

                df = genData.(paramsToNormalise(param)) - minimum;

                range = maximum - minimum;


                normalised = df / range;
                normalisedTbl.(paramsToNormalise(param) + "_norm") = normalised;
            end

            
            tbl = [genData normalisedTbl];
            try
                tbl.Time = tbl.Time - tbl.Time(1);
            catch
            end
            finalTbl = table2timetable(tbl);
            finalTbl = addprop(finalTbl, {'Vars', 'FlightDetails', 'Features'}, ...
                {'table', 'table', 'table'});
            vars = string(finalTbl.Properties.VariableNames);
            finalTbl.Properties.CustomProperties.Vars.NormData = vars(contains(vars,"norm"));
            finalTbl.Properties.CustomProperties.Vars.Data = setdiff(vars, ...
                [finalTbl.Properties.CustomProperties.Vars.NormData, ...
                finalTbl.Properties.CustomProperties.PARAMS.INDEPENDENT_PARAMS]);
            finalTbl.Properties.CustomProperties.FlightDetails.Date = date;
            finalTbl.Properties.CustomProperties.FlightDetails.Num = num;
            finalTbl.Properties.CustomProperties.FlightDetails.Aircraft = aircraft;
            
            
            v=string(tbl.Properties.VariableNames);
            % 18 columns each for normalised & un-normalised. + Flight phase column
            if size(finalTbl,2) ~= 37 && size(finalTbl,2) ~= 36 || class(finalTbl) ~= "timetable"
                gong=load("gong.mat");sound(gong.y)
                head(finalTbl)
                ME = MException("BadTableFormat:IncorrectNumberOfColumns", "Params does not have 37 columns");
                throw(ME)
            elseif sum(tbl{:,v(contains(v,"norm"))} < 0,'all') > 0
                ME = MException("BadTableFormat:IncorrectNormalisation", "some elements negative");
                throw(ME)
            end
            
            flight_matfile.("gen" + gen) = finalTbl;            
        end
%         break
     
        
        if saving
            % Save it in that folder
            % Flights with generators totally turned off will remain
            % uncleaned.
            gen1 = flight_matfile.gen1;
            gen2 = flight_matfile.gen2;
            parallelSave(full_path_to_save, gen1, gen2); % gen1 & gen2 must be in order!
        end
       
    end
%     break
end


function status = parallelSave(full_path_to_save, gen1, gen2)
    try
        save(full_path_to_save,"gen1","gen2");
        status = 1;
    catch ME
        status = ME.message;
    end
end