classdef MetricsSaccades < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
      filterWidthMS = 0;
      thresholdDeg = 0;
      degPerSPerV = 0;
      degPerV = 0;
    end
    
    methods
      
      %% clearAll
      function clearAll(obj)
        obj.degPerV = 0;
        obj.degPerSPerV = 0;
      end
      
      %% findSaccade: extract the saccade timing using speed threshold
      function [sIndex, eIndex] = findSaccade(obj, data, app, posTrace, velTrace, stepSign, startIndex)
        %            calSamples = floor(data.prestimDurS * app.lbj.SampleRateHz);    % use preStim for calibration
        seqLength = 5;
        if app.calTrialsDone < 4                                    % still getting a calibration
          if (stepSign == 1)
            DPV = abs(data.offsetsDeg(data.offsetIndex) / (max(posTrace(:)) - mean(posTrace(1:startIndex))));
          else
            DPV = abs(data.offsetsDeg(data.offsetIndex) / (mean(posTrace(1:startIndex) - min(posTrace(:)))));
          end
          obj.degPerV = (obj.degPerV * app.calTrialsDone + DPV) / (app.calTrialsDone + 1);
          obj.degPerSPerV = obj.degPerV * app.lbj.SampleRateHz;      % needed for velocity plots
          app.calTrialsDone = app.calTrialsDone + 1;
          sIndex = 0; eIndex = 0;
          return;
        end
        sIndex = startIndex;
        seq = 0;
        thresholdV = mean(posTrace(1:startIndex)) + obj.thresholdDeg / obj.degPerV;
        while (seq < seqLength && sIndex < length(posTrace))	% find the first sequence of seqLength > than threshold
          if posTrace(sIndex) * stepSign < thresholdV
            seq = 0;
          else
            seq = seq + 1;
          end
          sIndex = sIndex + 1;
        end
        % if we found a saccade start, look for the saccade end, consisting of seqLength samples below the peak
        if sIndex < length(posTrace)
          seq = 0;
          maxPos = posTrace(sIndex);
          maxIndex = sIndex;
          eIndex = sIndex;
          while seq < seqLength && eIndex < (length(posTrace) - 1)
            if posTrace(eIndex + 1) * stepSign < maxPos * stepSign
              seq = seq + 1;
            else
              seq = 0;
              maxPos = posTrace(eIndex + 1);
              maxIndex = eIndex + 1;
            end
            eIndex = eIndex + 1;
          end
          if eIndex >= length(posTrace) - 1
            eIndex = 0;
          else
            eIndex =  maxIndex;
          end
          % if we have found the start and end of a saccade, walk the start from the position threshold to the
          % point where velocity turned positive at the start of the saccade
          if eIndex > sIndex
            while sIndex > startIndex && velTrace(sIndex - 1) * stepSign > 0
              sIndex = sIndex - 1;
            end
          end
          if eIndex - sIndex < 0.005 * app.lbj.SampleRateHz      % no saccades less than 5 ms
            sIndex = 0;
            eIndex = 0;
          end
        else
          sIndex = 0;
          eIndex = 0;
        end
        % add some jitter to defeat the alignment on noise
        if sIndex > 0 && eIndex > 0
          offset = floor(app.lbj.SampleRateHz * 0.01666 * rand(1));
          sIndex = sIndex - offset;
          eIndex = eIndex - offset;
        end
      end
      
      %% processSignals: function to process data from one trial
      function [startIndex, endIndex] = processSignals(obj, app, data)
        % remove the DC offset
        if ~app.testMode
          app.posTrace = app.rawData - mean(app.rawData(1:floor(app.lbj.SampleRateHz * data.prestimDurS)));
        else
          samples = length(app.posTrace);
          app.posTrace = zeros(samples, 1);
          accel = 0.01;
          time = floor(sqrt(2.0 * abs(data.offsetsDeg(data.offsetIndex)) / 2.0 / accel));
          positions = zeros(time * 2, 1);
          accel = accel * data.stepSign;
          for t = 1:time
            positions(t) = 0.5 * accel * t^2;
          end
          for t = 1:time
            positions(time + t) = positions(time) + accel * time * t - 0.5 * accel * t^2;
          end
          preStimSamples = floor((data.stimTimeS + 0.1) * app.lbj.SampleRateHz);
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
          app.posTrace = filter(app.filter60Hz, app.posTrace);
          app.velTrace(1:end - 1) = diff(app.posTrace);
          app.velTrace(end) = app.velTrace(end - 1);
          app.velTrace = filter(app.filterLP, app.velTrace);
        else
          app.velTrace(1:end - 1) = diff(app.posTrace);
          app.velTrace(end) = app.velTrace(end - 1);
        end
        % find a saccade and make sure we have enough samples before and after its start
        %             sIndex = floor(data.stimTimeS * app.lbj.SampleRateHz);         % no saccades before stimon
        sIndex = floor(data.prestimDurS * app.lbj.SampleRateHz);
        [startIndex, endIndex] = obj.findSaccade(data, app, app.posTrace, app.velTrace, data.stepSign, sIndex);
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
        app.posSummed(:, data.offsetIndex) = app.posSummed(:, data.offsetIndex) + ...
          app.posTrace(firstIndex:lastIndex);
        app.velSummed(:, data.offsetIndex) = app.velSummed(:, data.offsetIndex) + app.velTrace(firstIndex:lastIndex);
        % tally the sums and compute the averages
        app.numSummed(data.offsetIndex) = app.numSummed(data.offsetIndex) + 1;
        app.posAvg(:, data.offsetIndex) = app.posSummed(:, data.offsetIndex) / app.numSummed(data.offsetIndex);
        app.velAvg(:, data.offsetIndex) = app.velSummed(:, data.offsetIndex) / app.numSummed(data.offsetIndex);
        app.offsetsDone(data.offsetIndex) = app.offsetsDone(data.offsetIndex) + 1;
        % now that we've updated all the traces, compute the degrees per volt if we have enough trials
        % take average peaks to get each point
        if sum(app.numSummed) > length(app.numSummed)
          endPointsV = [max(app.posAvg(:, 1:app.numOffsets / 2)) ...
            min(app.posAvg(:, app.numOffsets / 2 + 1:app.numOffsets))];
          obj.degPerV = mean(data.offsetsDeg ./ endPointsV);
          obj.degPerSPerV = obj.degPerV * app.lbj.SampleRateHz;          % needed for velocity plots
        end
        % find the average saccade duration using the average speed trace
        [sAvgIndex, eAvgIndex] = obj.findSaccade(data, app, app.posAvg(:, data.offsetIndex), ...
          app.velAvg(:, data.offsetIndex), data.stepSign, length(app.posAvg(:, data.offsetIndex)) / 2);
        if eAvgIndex > sAvgIndex
          app.saccadeDurS(app.absStepIndex) = (eAvgIndex - sAvgIndex) / app.lbj.SampleRateHz;
        else
          app.saccadeDurS(app.absStepIndex) = 0;
        end
      end
      
    end
end

