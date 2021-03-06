function status = consolidateImages2Excel(folderContainingAllGraphs, ExcelFileName)
% CONSOLIDATEIMAGES2EXCEL This function takes in a path to a folder containing images and
% consolidates all of them into an excel spreadsheet. 
% The spreadsheet will be named after the folder and saved inside that
% folder. It is meant to organise graphs to illustrate changes in 
% features generated by PM toolbox


% The images must be named using the convention below:
% <differential>_<parameter name>_<feature>.png 
% Example 1: d1_temperatureDifference_Peakvalue.jpg     --> peak value of the first derivative of temperature difference.
% Example 2: d0_Inlettemperature_Peakfreq.jpg           --> peak frequency of the original function of temperature difference.
% Example 3: d2_temperatureDifference_Mean.jpg          --> Mean of 2nd derivative of temperature difference.
% Strictly no underscores in the differentials, parameter name or feature names




dir_parts = split(folderContainingAllGraphs,filesep);

if nargin == 1
    ExcelFileName = dir_parts(end);
end

fullExcelFileName = fullfile(folderContainingAllGraphs, ExcelFileName + ".xlsx");

% Constants
width = 6;  % width of each graph
height = 16; % height of each graph
freqDomainFeatureNames = ["PeakAmp1", "PeakFreq1", "Wn1", "Zeta1", "BandPower", "PeakAmp", "PeakFreq", "Wn", "Zeta"];

files = dirCMD(folderContainingAllGraphs);
imgFiles = files(extractAfter(files,".") == "png" | extractAfter(files,".") == "jpg")';

nameElements = strings([size(imgFiles,1) 3]);
for img = 1:numel(imgFiles)
    [~, name, ~] = fileparts(imgFiles(img));
    nameElements(img,:) = split(name,"_")';
end

differentials = unique(nameElements(:,1));
parameters = sort(unique(nameElements(:,2)));
features = unique(nameElements(:,3));

features = [features(~ismember(lower(features), lower(freqDomainFeatureNames))); features(ismember(lower(features), lower(freqDomainFeatureNames)))];

% Open Excel as an ActiveX server.
objExcel = actxserver('Excel.Application');
objExcel.Visible = true;
objExcel.DisplayAlerts = false;

if exist(fullExcelFileName,"file") == 2
    ExcelWorkbook = objExcel.Workbooks.Open(fullExcelFileName); % Full path is necessary!
else
    ExcelWorkbook = objExcel.Workbooks.Add();  % Add new, blank workbook.
end  
ExcelWorkbook.Activate;


for param = 1:numel(parameters)
    Sheets = ExcelWorkbook.Sheets;   
    if param == 1
        currentSheet = ExcelWorkbook.ActiveSheet;
    else
        currentSheet = Sheets.Add();
    end
    
    originalFunction = currentSheet.Range("F2");
    originalFunction.Value = "Original Function";
    
    firstDerivative = currentSheet.Range("M2");
    firstDerivative.Value = "1st Derivative";
    
    secondDerivative = currentSheet.Range("T2");
    secondDerivative.Value = "2nd Derivative";
    
    currentSheet.Name = parameters(param);
    Shapes = currentSheet.Shapes;
    
    for feature = 1:numel(features)
        rowNum = 3 + (feature * 18) - 11;
        targetCell = "A" + string(rowNum);
        currentCell = currentSheet.Range(targetCell);
        currentCell.Value = upper(features(feature));
        
        for differential = 1:numel(differentials)
            fileName = differentials(differential) + "_" + parameters(param) + "_" + features(feature);
            fullFileName = fullfile(folderContainingAllGraphs,fileName);
            
            % Find the position to put the image
            distFromLeft = ((differential - 1) * 7) + 3;
            distFromTop = ((feature - 1) * 18) + 3;

            % Put in the image
            if exist(fullFileName + ".png","file") == 2
                Shapes.AddPicture(fullFileName + ".png", 0, 1, nCellWidth(distFromLeft), nCellHeight(distFromTop), nCellWidth(width), nCellHeight(height));%left,top,width,height
            elseif exist(fullFileName + ".jpg","file") == 2 
                Shapes.AddPicture(fullFileName + ".jpg", 0, 1, nCellWidth(distFromLeft), nCellHeight(distFromTop), nCellWidth(width), nCellHeight(height));%left,top,width,height
            else
                continue % Skip if no image
            end 
        end
    end

end

% Save this workbook we just created to disk.  Image will be saved with the workbook.
ExcelWorkbook.SaveAs(fullExcelFileName);

% Close the workbook.  Excel will still be open though.
ExcelWorkbook.Close(false);
objExcel.Quit;  % Shut down Excel.
fprintf("Graphs have been consolidated. Saved as \n%s",fullExcelFileName)

status = 1;

end


function width = nCellWidth(n)
    if nargin == 0
        n = 1;
    end
    width = 50*n;
end

function height = nCellHeight(n)
    if nargin == 0
        n = 1;
    end
    height = 15*n;
end