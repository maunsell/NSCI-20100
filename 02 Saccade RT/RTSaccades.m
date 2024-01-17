classdef RTSaccades < handle
% saccades
%   Support for processing eye traces and detecting saccades

properties
  filter60Hz;           % 60 Hz notch filter
  filterLP;             % low pass filter
  filterWidthMS = 0;
  thresholdDeg = 0;
  thresholdDPS = 0;
  degPerSPerV = 0;
  degPerV = 0;
end

methods
  function obj = RTSaccades(app)
    %% Object Initialization %%
    obj = obj@handle();                                   % object initialization
    nyquistHz = app.lbj.SampleRateHz / 2.0;
    % create a 60 Hz bandstop filter  for the sample rate
    obj.filter60Hz = design(fdesign.bandstop('Fp1,Fst1,Fst2,Fp2,Ap1,Ast,Ap2', ...
      55 / nyquistHz, 59 / nyquistHz, 61 / nyquistHz, 65 / nyquistHz, 1, 60, 1), 'butter');
    obj.filter60Hz.persistentmemory = false;              % no piecewise filtering of trace
    obj.filter60Hz.states = 1;                            % uses scalar expansion.
    % create a lowpass filter for velocity trace
    obj.filterLP = design(fdesign.lowpass('Fp,Fst,Ap,Ast', 30 / nyquistHz, 120 / nyquistHz, 0.1, 40), 'butter');
    obj.filterLP.persistentmemory = false;                % no piecemeal filtering of trace
    obj.filterLP.states = 1;                              % uses scalar expansion.
  end
  
  %% clearAll
  function clearAll(obj, ~)
    obj.degPerV = 0;
    obj.degPerSPerV = 0;
  end

  %% fakeDataTrace
  function posTrace = fakeDataTrace(~, app)
    samples = length(app.posTrace);               % samples in the fake eye position trace
    posTrace = zeros(samples, 1);
    accel = 0.01;                                 % acceleration/deceleration of saccade
    time = floor(sqrt(2.0 * app.stepSizeDeg / 2.0 / accel));  % number of accel/decel samples
    positions = zeros(time * 2, 1);               % positions during the saccade
    accel = accel * app.stepSign;                 % sign of acceleration (left or right)
    for t = 1:time                                % load the positions during the acceleartion
      positions(t) = 0.5 * accel * t^2;
    end
    for t = 1:time                                % load the positions during the deceleration (second half)
      positions(time + t) = positions(time) + accel * time * t - 0.5 * accel * t^2;
    end
    % We make gamma distributions of saccade delays, with means of 170, 210 and 275.  For all of these
    % the shape parameter is 9.  To get a SD of 1/3 the mean, the scale parameters are set as shown.
    % the mean of the gamma is shape*scale, the SD is sqrt(shape) * scale.  
    % The shape is (mean/SD)^2, the scale is mean/shape
    switch app.trialType
      case {0, 1}             % gap condition -- mean 170 SD 57
        pShape = 18.06;
        pScale = 9.41;
      case 2                  % step condition -- mean 210 SD 70
        pShape = 9.0;
        pScale = 23.3;
      case 3                  % overlap condition -- mean 250 SD 120
        pShape = 4.34;
        pScale = 57.6;
    end
    while true                % get a random saccade latency longer than 100 ms
      offsetMS = gamrnd(pShape, pScale);
      preStimSamples = floor((app.targetTimeS + offsetMS / 1000.0) * app.lbj.SampleRateHz);
      if preStimSamples + length(positions) > length(posTrace)
        preStimSamples = length(posTrace) - length(positions) - 100;
        break;
      end
      if offsetMS > 100 && preStimSamples + length(positions) <= length(posTrace)
        break;
      end
      % fprintf('app.targetTimeS %.2f sampleRateHz %.1f, preStimSamples %d\n', ...
      %   app.targetTimeS, app.lbj.SampleRateHz, preStimSamples);
      % fprintf(' offsetMS %.2f length(positions) %d avail %d\n', offsetMS, length(positions), length(posTrace));
    end
    posTrace(preStimSamples + 1:preStimSamples + length(positions)) = positions;
    for i = preStimSamples + length(positions) + 1:length(posTrace)
      posTrace(i) = positions(time * 2);
    end
    % make the trace decay to zero
    decayTrace = zeros(samples, 1);
    decayValue = mean(posTrace(1:floor(app.lbj.SampleRateHz * 0.250)));
    multiplier = 1.0 / (0.250 * app.lbj.SampleRateHz);                % tau of 250 ms
    for i = 1:samples
      decayTrace(i) = decayValue;
      decayValue = decayValue * (1.0 - multiplier) + posTrace(i) * multiplier;
    end
    % add random noise
    posTrace = posTrace - decayTrace + 2.0 * rand(size(posTrace)) - 1.0;
    % smooth with a boxcar to take out the highest frequencies
    filterSamples = max(1, floor(app.lbj.SampleRateHz * 10.0 / 1000.0));
    b = (1 / filterSamples) * ones(1, filterSamples);
    posTrace = filter(b, 1, posTrace);
    % add 60Hz noise
    dt = 1 / app.lbj.SampleRateHz;               	% seconds per sample
    t = (0:dt:samples * dt - dt)';              % seconds
    posTrace = posTrace + cos(2.0 * pi * 60 * t) * 0.25;
  end

  %% processSignals: function to process data from one trial
  function [startIndex, endIndex] = processSignals(obj, app)
    % remove the DC offset
    if app.taskMode == app.kNormal || app.taskMode == app.kTiming
      app.posTrace = app.rawData - mean(app.rawData(1:floor(app.lbj.SampleRateHz * app.prestimDurS)));
    else
      app.posTrace = fakeDataTrace(obj, app);
    end
    % do 60 Hz filtering
    if app.Filter60Hz.Value
      app.posTrace = filter(obj.filter60Hz, app.posTrace);
      app.velTrace(1:end - 1) = diff(app.posTrace);
      app.velTrace(end) = app.velTrace(end - 1);
      app.velTrace = filter(obj.filterLP, app.velTrace);
    else
      % make the velocity trace and then apply boxcar filter
      app.velTrace(1:end - 1) = diff(app.posTrace);
      app.velTrace(end) = app.velTrace(end - 1);
    end
    % find a saccade and make sure we have enough samples before and after its start
    startIndex = floor(app.targetTimeS * app.lbj.SampleRateHz);   % no saccades before stimon
    if app.taskMode == app.kTiming
      app.stepSign = -1;                                          % photodiode always driven negative
    end
    [startIndex, endIndex] = findSaccade(obj, app, startIndex);
    saccadeOffset = floor(app.saccadeSamples / 2);
    firstIndex = startIndex - saccadeOffset;
    lastIndex = startIndex + saccadeOffset;
    if mod(app.saccadeSamples, 2) == 0                     % make sure the samples are divisible by 2
      lastIndex = lastIndex - 1;
    end
    if (firstIndex < 1 || lastIndex > app.trialSamples)    % not enough samples around saccade to process
      startIndex = 0;
      return
    end
   % sum into the average pos and vel plot, inverting for negative steps
    app.posSummed = app.posSummed + app.posTrace(firstIndex:lastIndex) * app.stepSign;
    app.velSummed = app.velSummed + app.velTrace(firstIndex:lastIndex) * app.stepSign;
    % tally the sums and compute the averages
    app.numSummed = app.numSummed + 1;
    app.posAvg = app.posSummed / app.numSummed;
    app.velAvg = app.velSummed / app.numSummed;
    app.trialTypesDone(app.trialType) = app.trialTypesDone(app.trialType) + 1;
    % now that we've updated all the traces, compute the degrees per volt if we have enough trials
    % take average peaks to get each point
    if app.trialType ~= app.kCenteringTrial && sum(app.numSummed) > app.numTrialTypes
      rangeV = max(app.posAvg) - min(app.posAvg);
      obj.degPerV = mean(app.stepSizeDeg ./ rangeV);
      obj.degPerSPerV = obj.degPerV * app.lbj.SampleRateHz;          % needed for velocity plots
    end
  end 
end
end