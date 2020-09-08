clear
Conf = config;
PATH_TO_IDG_TRANSFORMED_DATA = Conf.PATH_TO_IDG_TRANSFORMED_DATA;
PATH_TO_REM_DATES_MATFILE = Conf.PATH_TO_REM_DATES_MATFILE;
PATH_TO_IDG_PROCESSED_DATA = Conf.PATH_TO_IDG_PROCESSED_DATA;
% PATH_TO_IDG_DATA = Conf.PATH_TO_IDG_DATA;
% CATworkable = readtable(fullfile(PATH_TO_IDG_DATA,"CaseAccountingTableMetaDataForLabelling.xlsx"));
% CATworkable = CAT(CAT.Workability == 1,:);

mat_file = load(fullfile(PATH_TO_IDG_TRANSFORMED_DATA, "dataMasterList.mat"));

g1 = ["HS-BBR",...
"HS-ABJ",...
"HS-ABH",...
"HS-ABG",...
"HS-ABC",...
"HS-BBS",...
"HS-ABA",...
"HS-ABU",...
"HS-ABP"];

g2 = ["HS-ABM",...
"HS-ABT",...
"HS-ABI",...
"HS-BBI"];

g12 = ["HS-ABF",...
    "HS-ABV",...
    "HS-ABX"];



dataMasterList = mat_file.data;

dataMasterList = dataMasterList(ismember(dataMasterList.Aircraft,g12(3)),:);


%%
X_y = table;
parfor row = 1:size(dataMasterList,1)
	aircraftData = dataMasterList(row,:);
    currentAircraft = aircraftData.Aircraft;
    allFlightData = aircraftData.data{1};
    
%     remDate = datetime("18-12-2019",'InputFormat',"dd-MM-yyyy");
%     selectedFlightData = allFlightData(allFlightData.date > remDate,:);
    
    
    for flight = 1:size(allFlightData,1)
    	singleFlightData = allFlightData(flight,:);
        filepath = singleFlightData.filepath;
        label = singleFlightData.label;
        flightData = load(filepath);
        
        gen1 = flightData.gen1;
        
        featTbl = gen1.Properties.CustomProperties.Features.Windowed;
        labelCol = [];
        for i = 1:size(featTbl,1)
            labelCol = [labelCol; categorical(label)];
        end
        featTbl.Label = labelCol;
        try
            X_y = [X_y; featTbl];
        catch
            disp("Skipped")
            continue
        end
    end
end
%%
save(fullfile(PATH_TO_IDG_PROCESSED_DATA,"allXYtrainingData.mat"),"xyTable")


%%
Conf = config;
PATH_TO_IDG_TRANSFORMED_DATA = Conf.PATH_TO_IDG_TRANSFORMED_DATA;
PATH_TO_REM_DATES_MATFILE = Conf.PATH_TO_REM_DATES_MATFILE;
PATH_TO_IDG_PROCESSED_DATA = Conf.PATH_TO_IDG_PROCESSED_DATA;

XYfiles = ["X_y1",...
"X_y2",...
"X_y(ABF1))",...
"X_y(ABF2))",...
"X_y(ABF3))",...
"X_y(ABV))",...
"X_y(ABV2))",...
"X_y(ABV3))",...
"X_y(ABX))"];

xyTable = table;
for XY = 1:numel(XYfiles)
    data = load(fullfile(PATH_TO_IDG_PROCESSED_DATA,XYfiles(XY)+".mat"));
    xy = data.X_y;
    xyTable = [xyTable; xy];
end