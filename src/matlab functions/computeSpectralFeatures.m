function varargout = computeSpectralFeatures(inputSignal,variableNamePrefix)
%computeSpectralFeatures Calculates the 5 spectral features of a timetable

%   Takes in a timetable and calculates all spectral features listed below.
%   If output is a single variable, only the spectral features will be returned, else, the power
%   spectrum and spectral features table will be stored in 2 separate
%   variables.


if class(inputSignal) == "timetable" || class(inputSignal) == "table"
    if ~exist("variableNamePrefix",'var') || isempty(variableNamePrefix)
        prefix = inputSignal.Properties.VariableNames{1};
    else
        prefix = variableNamePrefix;
    end
    
    if class(inputSignal) == "table"
        timeColumn = seconds(0:size(inputSignal,1)); % If a table is given, assume the values are evenly spaced secondly
    else
        timeColumn = inputSignal.Properties.RowTimes;
    end
    inputSignal = inputSignal.(inputSignal.Properties.VariableNames{1});

elseif exist("variableNamePrefix",'var') ~= 1 || isempty(variableNamePrefix)
    prefix = "data";
end


% PowerSpectrum
try
    % Get units to use in computed spectrum.
    tuReal = "seconds";
    tuTime = tuReal;

    % Compute effective sampling rate.
    tNumeric = time2num(timeColumn,tuReal);
    [Fs,irregular] = effectivefs(tNumeric);
    Ts = 1/Fs;

    % Resample non-uniform signals.
    if irregular
        inputSignal = resample(inputSignal,tNumeric,Fs,'linear');
    end

    % Compute the autoregressive model.
    data = iddata(inputSignal,[],Ts,'TimeUnit',tuTime,'OutputName','data');
    arOpt = arOptions('Approach','fb','Window','now','EstimateCovariance',false);
    model = ar(data,4,arOpt);

    % Compute the power spectrum.
    [ps,w] = spectrum(model);
    ps = idfrd(zeros(1,0,numel(w)),w,Ts,'SpectrumData',ps,'OutputName','data');

    % Configure the computed spectrum.
    warn = warning('off','Ident:dataprocess:freqAboveNyquist');
    ps = nyqcut(ps);
    warning(warn);
    ps.TimeUnit = tuTime;
    ps = chgFreqUnit(ps,'cycles/TimeUnit');
    ps.UserData = struct('IVName',"Time",'IVUnit',tuReal);
    inputSignal_ps = ps;
catch ME
%     disp(ME.message)
    % Get units to use in computed spectrum.
    tuReal = "seconds";
    tuTime = tuReal;

    % Configure the computed spectrum.
    ps = idfrd(zeros(1,0,1),0,1,'SpectrumData',NaN,'OutputName','data');

    % Configure the computed spectrum.
    warn = warning('off','Ident:dataprocess:freqAboveNyquist');
    ps = nyqcut(ps);
    warning(warn);
    ps.TimeUnit = tuTime;
    ps = chgFreqUnit(ps,'cycles/TimeUnit');
    ps.UserData = struct('IVName',"Time",'IVUnit',tuReal);
    inputSignal_ps = ps;
end


powerSpectrum = table({inputSignal_ps},'VariableNames',prefix + "_ps");
 
% SpectrumFeatures
try
    % Compute spectral features.
    sys = inputSignal_ps;
    sysdata = getPlotLTIData(sys);
    nu = size(sys,2);
    if nu == 0
        [ps,w] = noiseSpectrumSpec(sysdata,3,[],true);
    else
        [ps,w] = outputSpectrumSpec(sysdata,3,[],true);
    end
    factor = funitconv('Hz','rad/TimeUnit','seconds');
    mask_1 = (w>=factor*0.00159154943091895) & (w<=factor*0.5);
    ps = ps(mask_1);
    w = w(mask_1);

    % Compute spectral peaks.
    [peakAmp,peakFreq] = findpeaks(ps,w/factor,'MinPeakHeight',-Inf, ...
        'MinPeakProminence',0,'MinPeakDistance',0.001,'SortStr','descend','NPeaks',1);
    peakAmp = [peakAmp(:); NaN(1-numel(peakAmp),1)];
    peakFreq = [peakFreq(:); NaN(1-numel(peakFreq),1)];

    % Compute modal coefficients.
    if isa(sys,'frd')
        [wn,zeta] = modalfit(ps,w/2/pi,1/sys.Ts,1,'FitMethod','lsrf','Feedthrough',true);
        wn = 2*pi*wn/factor;
    else
        [wn,zeta] = modalfit(sys,w,1);
    end
    wn = [wn(:); NaN(1-numel(wn),1)];
    zeta = [zeta(:); NaN(1-numel(zeta),1)];

    % Extract individual feature values.
    data_PeakAmp1 = peakAmp(1);
    data_PeakFreq1 = peakFreq(1);
    data_Wn1 = wn(1);
    data_Zeta1 = zeta(1);
    data_BandPower = trapz(w/factor,ps);

    % Concatenate signal features.
    featureValues = [data_PeakAmp1,data_PeakFreq1,data_Wn1,data_Zeta1,data_BandPower];


catch ME
%     disp(ME.message)
    % Package computed features into a table.
    featureValues = NaN(1,5);
end

% Package computed features into a table.
featureNames_suffix = ["PeakAmp","PeakFreq","Wn","Zeta","BandPower"];
featureNames = prefix + "/" + featureNames_suffix;
spectralFeatures = array2table(featureValues,'VariableNames',featureNames);



if nargout == 1
    varargout{1} = spectralFeatures;
elseif nargout == 2
    varargout{1} = spectralFeatures;
    varargout{2} = powerSpectrum;
end
    
end


