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
        
        saving = true;
        if exist(full_path_to_save,"file") ~= 2
            ME = MException("NoFileFound:Nofile","No pre-procssed file. Run dataPreprocessor1.mlx first");
            throw(ME)
        end 
        
        flight_matfile = load(filepath);
        
        % Check if the flightphase colum is there
        flightData = flight_matfile.gen1;
        if ~any(contains(string(flightData.Properties.VariableNames),"FlightPhase"))
            system("echo " + name + " >> " + "noFlightPhase.txt"); 
            % Keep a record of those flights without flightphase
            continue

        end
        
        
        
        for gen = 1:2
            genData = flight_matfile.("gen" + string(gen));
            if any(contains(string(genData.Properties.VariableNames),"norm"))
                continue
            end
            
            
            tempTbl = removevars(genData,["FlightPhase" "Time"]);
            paramsToNormalise = string(tempTbl.Properties.VariableNames);           
            
            notUsed = size(genData,1) == 0;
            if notUsed   
%                 system("echo " + name + " >> " + "TotallyMalfunctional.txt");
                bigNormalisedTable = table;
                for param = 1:numel(paramsToNormalise)
                    bigNormalisedTable.(paramsToNormalise(param) + "_norm") = zeros(0);
                end
                
                genData = [genData bigNormalisedTable];
                finalTbl = table2timetable(genData);
                flight_matfile.("gen" + string(gen)) = finalTbl;
                if size(finalTbl,2) ~= 37 || class(finalTbl) ~= "timetable"
                    gong=load("gong.mat");sound(gong.y)
                    head(finalTbl)
                    ME = MException("BadTableFormat:IncorrectNumberOfColumns", "Empty Table does not have 37 columns");
                    throw(ME)
                end
                
                continue
            end          
            
            % FlightPhases 1,2,13,14 contain a lot of noise and variations
            genData = genData(genData.FlightPhase >= 3 & genData.FlightPhase <= 12,:);
            
            bigNormalisedTable = table;
            for phase_group = 1:4
                normalisedTbl = table;
                
                switch phase_group
                    case 1
                        OC = genData.FlightPhase == 3 | genData.FlightPhase == 4;
                    case 2
                        OC = genData.FlightPhase >= 5 & genData.FlightPhase <= 7;
                    case 3
                        OC = genData.FlightPhase >= 8 & genData.FlightPhase <= 10;
                    case 4
                        OC = genData.FlightPhase == 11 | genData.FlightPhase == 12;
                end
                
                for param = 1:numel(paramsToNormalise)
                    minimum = dataMinMax.("gen" + string(gen)).("phase_group" + string(phase_group)).(paramsToNormalise(param)).Min;
                    maximum = dataMinMax.("gen" + string(gen)).("phase_group" + string(phase_group)).(paramsToNormalise(param)).Max;
                    
                    df = genData{OC, paramsToNormalise(param)} - minimum;

                    range = maximum - minimum;
                   
                    
                    normalised = df / range;
                    normalisedTbl.(paramsToNormalise(param) + "_norm") = normalised;
                end
                bigNormalisedTable = [bigNormalisedTable; normalisedTbl];
            end
            
            tbl = [genData bigNormalisedTable];
            try
                tbl.Time = tbl.Time - tbl.Time(1);
            catch
            end
            finalTbl = table2timetable(tbl);

            
            
            v=string(tbl.Properties.VariableNames);
            % 18 columns each for normalised & un-normalised. + Flight phase column
            if size(finalTbl,2) ~= 37 || class(finalTbl) ~= "timetable"
                gong=load("gong.mat");sound(gong.y)
                head(finalTbl)
                ME = MException("BadTableFormat:IncorrectNumberOfColumns", "Params does not have 19 columns");
                throw(ME)
            elseif sum(tbl{:,v(contains(v,"norm"))} < 0,'all') > 0
                ME = MException("BadTableFormat:IncorrectNormalisation", "some elements negative");
                throw(ME)
            end
            
            flight_matfile.("gen" + gen) = finalTbl;            
        end
        
     
        
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
% function recognisedTblName = variableMap(validated)
%     switch validated
%         case {'IDG1INLETTEMP' 'IDG2INLETTEMP'}
%             recognisedTblName = "INLETTEMP";
%         case {'IDG1OUTLETTEMP' 'IDG2OUTLETTEMPERATURE'}
%             recognisedTblName = "OUTLETTEMP";
%         case {'GEN1FREQ' 'GEN2FREQ'}
%             recognisedTblName = "GENFREQ";
%         case {'GEN1VOLTAGE' 'GEN2VOLTAGE'}
%             recognisedTblName = "GENVOLTAGE";
%         case {'IDG1TEMPDIFF' 'IDG2TEMPDIFF'}
%             recognisedTblName = "TEMPDIFF";
%         case {'IDG1VHZRATIO' 'IDG2VHZRATIO'}
%             recognisedTblName = "VHZRATIO";
%             
%             
%         case {'d_IDG1INLETTEMP' 'd_IDG2INLETTEMP'}
%             recognisedTblName = "d_INLETTEMP";
%         case {'d_IDG1OUTLETTEMP' 'd_IDG2OUTLETTEMPERATURE'}
%             recognisedTblName = "d_OUTLETTEMP";
%         case {'d_GEN1FREQ' 'd_GEN2FREQ'}
%             recognisedTblName = "d_GENFREQ";
%         case {'d_GEN1VOLTAGE' 'd_GEN2VOLTAGE'}
%             recognisedTblName = "d_GENVOLTAGE";
%         case {'d_IDG1TEMPDIFF' 'd_IDG2TEMPDIFF'}
%             recognisedTblName = "d_TEMPDIFF";
%         case {'d_IDG1VHZRATIO' 'd_IDG2VHZRATIO'}
%             recognisedTblName = "d_VHZRATIO";
%             
%             
%         case {'dd_IDG1INLETTEMP' 'dd_IDG2INLETTEMP'}
%             recognisedTblName = "dd_INLETTEMP";
%         case {'dd_IDG1OUTLETTEMP' 'dd_IDG2OUTLETTEMPERATURE'}
%             recognisedTblName = "dd_OUTLETTEMP";
%         case {'dd_GEN1FREQ' 'dd_GEN2FREQ'}
%             recognisedTblName = "dd_GENFREQ";
%         case {'dd_GEN1VOLTAGE' 'dd_GEN2VOLTAGE'}
%             recognisedTblName = "dd_GENVOLTAGE";
%         case {'dd_IDG1TEMPDIFF' 'dd_IDG2TEMPDIFF'}
%             recognisedTblName = "dd_TEMPDIFF";
%         case {'dd_IDG1VHZRATIO' 'dd_IDG2VHZRATIO'}
%             recognisedTblName = "dd_VHZRATIO";
%         otherwise
%             disp("NONE")
%     end
% end

function status = parallelSave(full_path_to_save, gen1, gen2)
    try
        save(full_path_to_save,"gen1","gen2");
        status = 1;
    catch ME
        status = ME.message;
    end
end