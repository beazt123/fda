% This script loops thru all the tables:
% - removes the unwanted parameters
% - separates each table into 2 parts(1 for each generator)
% - Calculates the 1st & 2nd deriatives of each selected parameter
% - Saves the result as a struct:
% Struct:
    %- gen1
    %- gen2
    
Conf = config;
SELECTED_DATA_COLUMNS = string(Conf.SELECTED_DATA_COLUMNS);
AIRCRAFTS = Conf.AIRCRAFTS;
PATH_TO_IDG_RAW_CLEAN_DATA = Conf.PATH_TO_IDG_RAW_CLEAN_DATA;
PATH_TO_IDG_TRANSFORMED_DATA = Conf.PATH_TO_IDG_TRANSFORMED_DATA;
cleanDataMasterList = fullfile(PATH_TO_IDG_RAW_CLEAN_DATA,"dataMasterList.mat");
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
        
        % Save the file in the target filepath
        path_to_save = fullfile(PATH_TO_IDG_TRANSFORMED_DATA,currentAircraft);
        full_path_to_save = fullfile(path_to_save,name + ext);
        if exist(path_to_save,'dir') ~= 7
            mkdir(path_to_save);
        end
        
        saving = true;
        if exist(full_path_to_save,"file") == 2
            saving=false;
            continue
        end 
        
        flight_matfile = load(filepath);
        
        
        for gen = 1:2
            genData = flight_matfile.("gen" + string(gen));

            
            %Calculate derivatives
            PARAMS = genData.Properties.CustomProperties.PARAMS;
            g = [PARAMS.GEN_PARAMS, PARAMS.DERIVED_GEN_PARAMS];
            try
                relevantGenData = genData(:, [PARAMS.INDEPENDENT_PARAMS, g]);
            catch
                relevantGenData = genData(:, ["Time", g]);
            end
            

            timeVar = relevantGenData.Time;
            d1 = differentiateTable(relevantGenData, timeVar, g, []);
            d2 = differentiateTable(d1, timeVar, [], []);% Can handle empty tables
            
            
            params = [relevantGenData d1 d2];
            
            if size(params,2) ~= 19 && size(params,2) ~= 20 || class(params) ~= "table"
                gong=load("gong.mat");sound(gong.y)
                head(params)
                ME = MException("BadTableFormat:IncorrectNumberOfColumns", "Empty Table does not have 20 columns");
                throw(ME)
            end
            varNames = string(params.Properties.VariableNames);
            params.Properties.CustomProperties.PARAMS.SELECTED_GEN_PARAMS = g;
            params.Properties.CustomProperties.PARAMS.d_SELECTED_GEN_PARAMS = varNames(startsWith(varNames,"d_"));
            params.Properties.CustomProperties.PARAMS.dd_SELECTED_GEN_PARAMS = varNames(startsWith(varNames,"dd_"));
            flight_matfile.("gen" + gen) = params;
              
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
%%
function status = parallelSave(full_path_to_save, gen1, gen2)
    try
        save(full_path_to_save,"gen1","gen2");
        status = 1;
    catch ME
        status = ME.message;
    end
end