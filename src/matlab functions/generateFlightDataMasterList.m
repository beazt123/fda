function data = generateFlightDataMasterList(PATH_TO_IDG_MATFILES, autoSave)
%GENERATEFLIGHTDATAMASTERLIST Goes into the path specified and generates
% a masterlist of all the flight data contained inside. The master list will be saved as
% dataMasterList.mat in PATH_TO_IDG_MATFILES.
% PATH_TO_IDG_MATFILES must be a folder containing 1 level of folders, underwhich the data is
% located. It will look at all the folders under the path specified. 
% Make sure the flight data are named using the format below:

% <AIRCRAFT>_<dd-MM-yyyy>_<number>.mat


% The resulting master list will  
% sort the filepaths by the folder they are under.  I.e. 

% /folder
%     |---/group 1
%     |     |--ABCDE_01-01-2020_1.mat
%     |     |--ABCDE_01-01-2020_2.mat
%     |---/group 2
%     |     |--BCDE_01-02-2020_1.mat
%     |     |--BCDE_01-02-2020_2.mat
%     |---/group 3
%     |     |--CDE_01-03-2020_1.mat
%     |     |--CDE_01-03-2020_2.mat
%     |     |--CDE_01-03-2020_3.mat
% someOtherFile.xlsx 
%
% generateFlightDataMasterList(folder) will create a masterlist like below

% Aircraft | Num files | data
% _________|___________|_______________
% group 1  | 2         | {2 x 1 table}
% group 2  | 2         | {2 x 1 table}
% group 3  | 3         | {3 x 1 table}


% Each table within the "data" column has the structure:

% date        | Num       | filepath
% ____________|___________|_______________
% 01-03-2020  | 1         | "C:\\....."
% 01-03-2020  | 2         | "C:\\....."
% 01-03-2020  | 3         | "C:\\....."


    if nargin == 1
        autoSave = 0;
    end
    
    allFiles = dirCMD(PATH_TO_IDG_MATFILES);
    allAircraftFolders = allFiles(~contains(allFiles,"."))';%to avoid touching the remdates mat file and datamasterlist
    
    % Loop thru the matfiles and see how many of each we have. Collect their
    % filepaths as well
    aircrafts = strings(size(allAircraftFolders));
    nFiles = zeros(size(allAircraftFolders));
    data = cell(numel(allAircraftFolders),1);
    for folder = 1:numel(allAircraftFolders)
        folderPath = allAircraftFolders(folder);
        [~, aircraft, ~] = fileparts(folderPath);
        aircrafts(folder) = aircraft;
        
        allFlights = dirCMD(folderPath);
        dates = NaT(numel(allFlights),1,'Format',"dd-MM-uuuu");
        allNum = zeros([numel(allFlights),1]);
        paths = strings([numel(allFlights),1]);
        for flight = 1:numel(allFlights)
            filepath = allFlights(flight);
            [~, date, num] = flightDataFileNameDecoder(filepath);
            dates(flight) = date;
            allNum(flight) = num;
            paths(flight) = filepath;
        end
        
        singleTbl = table(dates,allNum,paths,'VariableNames',{'date' 'num' 'filepath'});
        sortedSingleTbl = sortrows(singleTbl,{'date', 'num'},{'ascend','descend'});
        data{folder} = sortedSingleTbl;
        nFiles(folder) = size(sortedSingleTbl,1);
    end
    
    % Collect their results into a table
    data = table(aircrafts,nFiles,data,'VariableNames',{'Aircraft' 'NumFiles' 'data'});
    
    if autoSave
        save(fullfile(PATH_TO_IDG_MATFILES,"dataMasterList.mat"),"data")
    end

end
