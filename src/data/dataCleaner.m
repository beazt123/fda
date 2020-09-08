Conf = config;

PATH_TO_IDG_MATFILES = Conf.PATH_TO_IDG_MATFILES;
PATH_TO_IDG_RAW_CLEAN_DATA = Conf.PATH_TO_IDG_RAW_CLEAN_DATA;
mat_file = load(fullfile(PATH_TO_IDG_MATFILES, "dataMasterList.mat"));
dataMasterList = mat_file.data;
SELECTED_DATA_COLUMNS = Conf.SELECTED_DATA_COLUMNS;

parfor row = 1:size(dataMasterList,1)
    disp(row)
	aircraftData = dataMasterList(row,:);
    currentAircraft = aircraftData.Aircraft;
    allFlightData = aircraftData.data{1};
    
    filepaths = allFlightData.filepath;
    
    for flight = 1:size(filepaths,1)
    	singleFlightData = allFlightData(flight,:);
        filepath = singleFlightData.filepath;
        [path, name, ext] = fileparts(filepath);
        
        flight_matfile = load(filepath);
        flightData = flight_matfile.tbl;
        if sum(ismember(string(flightData.Properties.VariableNames),SELECTED_DATA_COLUMNS)) == 0
            % If table does not contain generator parameters, skip it
            continue
        end
        
        
        try
            cleanedTbls = cleanFlightData(flightData, Conf);
        catch ME
%             disp(ME.message)
            continue
        end
        
        
        path_to_save = fullfile(PATH_TO_IDG_RAW_CLEAN_DATA, currentAircraft);
        full_path_to_save = fullfile(path_to_save,name + ext);
        if exist(path_to_save,'dir') ~= 7
            mkdir(path_to_save);
        end
        
        saving = true;
        if exist(full_path_to_save,"file") == 2
%             disp("Duplicates found. Skipping the current table.")
            saving = false;
            continue
        end               

        if saving
            % Save it in that folder
%             system('findstr /V "' + name + '" failedTables.txt > failedTables.txt');
            gen1 = cleanedTbls.gen1;
            gen2 = cleanedTbls.gen2;
            status = parallelSaveGenTables(full_path_to_save, gen1, gen2);
            if status
                throw(MException("BADSAVE:savefailed","save failed"));
            end
                
        end        
%         break
    end
%     break
end

function status = parallelSaveGenTables(full_path_to_save, gen1, gen2)
    try
        save(full_path_to_save,"gen1","gen2");
        status = 0;
    catch ME
        disp(ME.message)
        status = 1;
    end
end