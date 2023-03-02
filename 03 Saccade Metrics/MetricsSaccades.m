classdef MetricsSaccades < handle
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
  function obj = MetricsSaccades(app)
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
    
  %% processSignals: function to process data from one trial
  function [startIndex, endIndex] = processSignals(obj, app)
    % remove the DC offset
    if ~app.testMode
      app.posTrace = app.rawData - mean(app.rawData(1:floor(app.lbj.SampleRateHz * app.prestimDurS)));
    else
      % test mode -- create an artificial trace
      samples = length(app.posTrace);
      app.posTrace = zeros(samples, 1);
      accel = 0.01;
      time = floor(sqrt(2.0 * abs(app.offsetsDeg(app.offsetIndex)) / 2.0 / accel));
      positions = zeros(time * 2, 1);
      accel = accel * app.stepSign;
      for t = 1:time
        positions(t) = 0.5 * accel * t^2;
      end
      for t = 1:time
        positions(time + t) = positions(time) + accel * time * t - 0.5 * accel * t^2;
      end
      preStimSamples = floor((app.stimTimeS + 0.1) * app.lbj.SampleRateHz);
      app.posTrace(preStimSamples + 1:preStimSamples + length(positions)) = positions;
      for i = preStimSamples + length(positions) + 1:length(app.posTrace)
        app.posTrace(i) = positions(time * 2);
      end
      % make the trace decay to zero
      decayTrace = zeros(samples, 1);
      decayValue = mean(app.posTrace(1:floor(app.lbj.SampleRateHz * 0.250)));
      multiplier = 1.0 / (0.250 * app.lbj.SampleRateHz);                % tau of 250 ms
      for i = 1:samples
        decayTrace(i) = decayValue;
        decayValue = decayValue * (1.0 - multiplier) + app.posTrace(i) * multiplier;
      end
      % decay to zero and add random noise
      app.posTrace = app.posTrace - decayTrace + 2.0 * rand(size(app.posTrace)) - 1.0;
      % smooth with a boxcar to take out the highest frequencies
      filterSamples = max(1, floor(app.lbj.SampleRateHz * 10.0 / 1000.0));
      b = (1 / filterSamples) * ones(1, filterSamples);
      app.posTrace = filter(b, 1, app.posTrace);
      % add 60Hz noise
      dt = 1/app.lbj.SampleRateHz;                   % seconds per sample
      t = (0:dt:samples * dt - dt)';              % seconds
      app.posTrace = app.posTrace + cos(2.0 * pi * 60 * t) * 0.25;
    end
    if app.Filter60Hz.Value
      app.posTrace = filter(obj.filter60Hz, app.posTrace);
      app.velTrace(1:end - 1) = diff(app.posTrace);
      app.velTrace(end) = app.velTrace(end - 1);
      app.velTrace = filter(obj.filterLP, app.velTrace);
    else
      app.velTrace(1:end - 1) = diff(app.posTrace);
      app.velTrace(end) = app.velTrace(end - 1);
    end
    % find a saccade and make sure we have enough samples before and after its start
    sIndex = floor(app.prestimDurS * app.lbj.SampleRateHz);
    [startIndex, endIndex] = findSaccade(obj, app, sIndex);
    saccadeOffset = floor(app.saccadeSamples / 2);
    firstIndex = startIndex - saccadeOffset;
    lastIndex = startIndex + saccadeOffset;
    if mod(app.saccadeSamples, 2) == 0                     % make sure the samples are divisible by 2
      lastIndex = lastIndex - 1;
    end
    if (firstIndex < 1 || lastIndex > app.trialSamples)    % not enough samples around saccade to process
      startIndex = 0;
      return;
    end
    % sum into the average pos and vel plot, inverting for negative steps
    app.posSummed(:, app.offsetIndex) = app.posSummed(:, app.offsetIndex) + ...
      app.posTrace(firstIndex:lastIndex);
    app.velSummed(:, app.offsetIndex) = app.velSummed(:, app.offsetIndex) + app.velTrace(firstIndex:lastIndex);
    % tally the sums and compute the averages
    app.numSummed(app.offsetIndex) = app.numSummed(app.offsetIndex) + 1;
    app.posAvg(:, app.offsetIndex) = app.posSummed(:, app.offsetIndex) / app.numSummed(app.offsetIndex);
    app.velAvg(:, app.offsetIndex) = app.velSummed(:, app.offsetIndex) / app.numSummed(app.offsetIndex);
    % now that we've updated all the traces, compute the degrees per volt if we have enough trials
    % take average peaks to get each point
    if sum(app.numSummed) > length(app.numSummed)
      endPointsV = [max(app.posAvg(:, 1:app.numOffsets / 2)) ...
        min(app.posAvg(:, app.numOffsets / 2 + 1:app.numOffsets))];
      obj.degPerV = mean(app.offsetsDeg ./ endPointsV);
      obj.degPerSPerV = obj.degPerV * app.lbj.SampleRateHz;          % needed for velocity plots
    end
  end
end
end