function cleanedFlightData = cleanFlightData(flightData, Conf)
    SELECTED_DATA_COLUMNS = Conf.SELECTED_DATA_COLUMNS;
    
    % Outliers can occur when the generator is first turned off and when it
    % is just turned off. Eliminating them first will save time.
    flightData = flightData(2:end-1,:);
    
    % Calculate new columns to analyse and also help remove absurd data
    flightData.IDG1TEMPDIFF = flightData.IDG1OUTLETTEMP - flightData.IDG1INLETTEMP;
    flightData.IDG2TEMPDIFF = flightData.IDG2OUTLETTEMPERATURE - flightData.IDG2INLETTEMP;
    
    flightData.IDG1VHZRATIO = flightData.GEN1VOLTAGE ./ flightData.GEN1FREQ;
    flightData.IDG2VHZRATIO = flightData.GEN2VOLTAGE ./ flightData.GEN2FREQ;
    
    % Try to filter them by flight phase, leave them as is if flightphase
    % isn't available
    try
        correctFlightPhase = flightData(flightData.FlightPhase >= 1 & flightData.FlightPhase <= 14, :);
        correctFlightPhase{correctFlightPhase.BarometricAltitude < 0, "BarometricAltitude"} = NaN;
        correctFlightPhase{correctFlightPhase.CalibratedAirSpeed < 0, "CalibratedAirSpeed"} = NaN;
        
    catch 
        correctFlightPhase = flightData;
    end
    
    % Separate the tables into 2 parts, one for each generator
    tables = {};
    for genNum = 1:2
        whereGenIsOperational = correctFlightPhase.("GEN" + string(genNum) + "FREQ") > 0 & ...
            correctFlightPhase.("GEN" + string(genNum) + "VOLTAGE") > 0;
        otherGenParams = SELECTED_DATA_COLUMNS(~contains(SELECTED_DATA_COLUMNS,string(genNum)));
        genParams = SELECTED_DATA_COLUMNS(contains(SELECTED_DATA_COLUMNS,string(genNum)));
        genParamsAndOthers = setdiff(string(correctFlightPhase.Properties.VariableNames), otherGenParams);
        
        tblForCleaning = correctFlightPhase(whereGenIsOperational, genParamsAndOthers);
        
        % Standardise the selected parameters
        genParams = string(genParams);
        for varName = 1:numel(genParams)
            pName = genParams(varName);
            newName = extractBefore(pName,string(genNum)) + ...
                extractAfter(pName,string(genNum));
            
            if strcmp(newName,"IDGOUTLETTEMPERATURE") 
                % "IDG2OUTLETTEMPERATURE" was named as such,
                % while that of IDG 1 was named "IDG1OUTLETTEMP"
                newName = "IDGOUTLETTEMP";
            end
            genParams(varName) = newName;
            tblForCleaning = renamevars(tblForCleaning,pName,newName);
        end

        tblForCleaning = addprop(tblForCleaning,...
            {'PARAMS'},...
            {'table'});
        
        tblForCleaning.Properties.CustomProperties.PARAMS.GEN_PARAMS = ["IDGINLETTEMP",...
            "IDGOUTLETTEMP",...
            "GENFREQ",...
            "GENVOLTAGE"];
        tblForCleaning.Properties.CustomProperties.PARAMS.INDEPENDENT_PARAMS = ["Time", "FlightPhase"];
        tblForCleaning.Properties.CustomProperties.PARAMS.DERIVED_GEN_PARAMS = ["IDGTEMPDIFF", "IDGVHZRATIO"];

        if size(tblForCleaning,1) ~= 0
            % Given that we're monitoring only when genfreq > 0: genfreq > 0 iff temp diff > 0
%             tempSensorWorking = tblForCleaning.(genFreq) > 0 & tblForCleaning.(tempDiff) > 0;
%             tblForCleaning = tblForCleaning(tempSensorWorking,:); %in place!!!


            tblForCleaning(:,genParams) = fillmissing(tblForCleaning(:,genParams),'linear');

%             [~,TF] = rmoutliers(tblForCleaning(:, genParams), 'movmean', 15, 'ThresholdFactor', 1.5);

            cleanedTbl = tblForCleaning;

            
            % Calibrate & format time column, otherwise leave them as is.
            cleanedTbl.Time = seconds(cleanedTbl.SfCount - cleanedTbl.SfCount(1)); %Does not work with empty tables

        else
            cleanedTbl = tblForCleaning; % gives empty table
        end
        
        tables(genNum) = {cleanedTbl};
    end

    [gen1, gen2] = tables{:};    % gen1 & gen2 contain generator parameters for each generator where genfreq>0
    
 
    cleanedFlightData = struct;
    cleanedFlightData.gen1 = gen1;
    cleanedFlightData.gen2 = gen2;
    
    
end    