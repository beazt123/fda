% This script calculates the features using the sliding window approach and
% stores the features in the custom properties of each gen table

clear
Conf = config;
PATH_TO_IDG_TRANSFORMED_DATA = Conf.PATH_TO_IDG_TRANSFORMED_DATA;
PATH_TO_REM_DATES_MATFILE = Conf.PATH_TO_REM_DATES_MATFILE;
PATH_TO_IDG_DATA = Conf.PATH_TO_IDG_DATA;
WINDOW_SIZE = Conf.WINDOW_SIZE;
step_size = WINDOW_SIZE;

mat_file = load(fullfile(PATH_TO_IDG_TRANSFORMED_DATA, "dataMasterList.mat"));
dataMasterList = mat_file.data;


parfor row = 1:size(dataMasterList,1)
	aircraftData = dataMasterList(row,:);
    currentAircraft = aircraftData.Aircraft
    allFlightData = aircraftData.data{1};
    
    flightDataFilepaths = allFlightData.filepath;
    
    for flight = 1:size(flightDataFilepaths,1)
%         disp(string(row) + "/" + string(flight))
        
    	singleFlightData = allFlightData(flight,:);
        filepath = singleFlightData.filepath;
        
        flight_matfile = load(filepath);
        
        for gen = 1:2
            flightData = flight_matfile.("gen" + string(gen));
            Vars = flightData.Properties.CustomProperties.Vars;
            SELECTED_PARAMS = Vars.NormData;
            
            
            selectedGenParams = flightData(:,SELECTED_PARAMS);
            flightFeatures = [allVarLinearTimeDomainFeatures(selectedGenParams), ...
                allVarLinearFreqDomainFeatures(selectedGenParams)];
            
            nWindows = ceil(size(flightData,1) / WINDOW_SIZE);
            featureTbl = table;
            for window = 1:nWindows
                nSteps = window - 1;
                
                lowerIdx = nSteps * step_size + 1;
                upperIdx = lowerIdx + window - 1;
                
                try
                    extract = selectedGenParams(lowerIdx:upperIdx,:);
                catch
                    try
                        extract = selectedGenParams(lowerIdx:end,:);
                    catch
                        extract = selectedGenParams; %for empty tables
                    end
                end
                features = [allVarLinearTimeDomainFeatures(extract), ...
                    allVarLinearFreqDomainFeatures(extract)];
                featureTbl = [featureTbl ; features];
            end
            
            flightData.Properties.CustomProperties.Features.Windowed = featureTbl;
            flightData.Properties.CustomProperties.Features.Flight = flightFeatures;
            flight_matfile.("gen" + string(gen)) = flightData;
%             return
%             break
        end
        gen1=flight_matfile.gen1;
        gen2=flight_matfile.gen2;
        
        parsaveGen(filepath, gen1, gen2);
%         break
    end
%     break
end
function status = parsaveGen(filepath, gen1, gen2)
save(filepath,"gen1","gen2");
status = 0;
end