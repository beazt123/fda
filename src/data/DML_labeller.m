% This script goes thru all selected flights in the /transformed folder

clear
Conf = config;
PATH_TO_IDG_TRANSFORMED_DATA = Conf.PATH_TO_IDG_TRANSFORMED_DATA;
PATH_TO_REM_DATES_MATFILE = Conf.PATH_TO_REM_DATES_MATFILE;
PATH_TO_IDG_DATA = Conf.PATH_TO_IDG_DATA;
CATworkable = readtable(fullfile(PATH_TO_IDG_DATA,"CaseAccountingTableMetaDataForLabelling.xlsx"));
% CATworkable = CAT(CAT.Workability == 1,:);

remdates = load(PATH_TO_REM_DATES_MATFILE);
remdates = remdates.RemovalDataandSFRfor15ComponentsS3;
idgRemovalDates = remdates(remdates.DESCRIPTION == "IDG-INTEGRATED DRIVE GENERATOR",:);

mat_file = load(fullfile(PATH_TO_IDG_TRANSFORMED_DATA, "dataMasterList.mat"));
dataMasterList = mat_file.data;

%%
for row = 1:size(dataMasterList,1)
	aircraftData = dataMasterList(row,:);
    currentAircraft = aircraftData.Aircraft;
    allFlightData = aircraftData.data{1};
    
    flightDataFilepaths = allFlightData.filepath;
    
    for flight = 1:size(flightDataFilepaths,1)
    	singleFlightData = allFlightData(flight,:);
        filepath = singleFlightData.filepath;
        [aircraft, date, num] = flightDataFileNameDecoder(filepath);
        
        allRemDates = CATworkable{string(CATworkable.AIRCRAFT) == aircraft,"RemovalDate"};
        sortedAllRemDates = sort(allRemDates);
        
        nRemDates = numel(sortedAllRemDates);
        for remDateIdx = nRemDates:-1:1
            remDate = sortedAllRemDates(remDateIdx);
            
            if date > remDate && remDateIdx == nRemDates
                label = 0;
                specifyLabel = 0;
            elseif date <= remDate
                specifyLabel = 1;
            end
            
            if specifyLabel == 1
                CATrow = CATworkable(string(CATworkable.AIRCRAFT) == aircraft & ...
                    CATworkable.RemovalDate == remDate,:);
                if CATrow.HighOilConsumption == 1 && ...
                        CATrow.HighOilTemp == 1 && ...
                        CATrow.GenFault == 1
                    label = 6;
                elseif CATrow.DPIPopout == 1
                    label = 1;
                elseif CATrow.HighOilTemp == 1
                    label = 2;
                elseif CATrow.HighOilConsumption == 1
                    label = 3;
                elseif CATrow.LowOilPressure == 1
                    label = 4;
                elseif CATrow.GenFault == 1
                    label = 5;
                end
            end
            specifyLabel = 0;
        end
        
        allFlightData.label(flight) = label;

    end
    aircraftData.data{1} = allFlightData;

    dataMasterList(row,:) = aircraftData;
end
data = dataMasterList;
save(fullfile(PATH_TO_IDG_TRANSFORMED_DATA, "dataMasterList.mat"),"data");