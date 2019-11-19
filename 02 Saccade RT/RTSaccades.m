classdef RTSaccades < handle
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

        %% fakeDataTrace
        function posTrace = fakeDataTrace(~, data)
            samples = length(data.posTrace);
            posTrace = zeros(samples, 1);
            accel = 0.01;
            time = floor(sqrt(2.0 * data.stepSizeDeg / 2.0 / accel));
            positions = zeros(time * 2, 1);
            accel = accel * data.stepDirection;
            for t = 1:time
                positions(t) = 0.5 * accel * t^2;
            end
            for t = 1:time
                positions(time + t) = positions(time) + accel * time * t - 0.5 * accel * t^2;
            end
            preStimSamples = floor((data.targetTimeS + 0.1) * data.sampleRateHz);
            posTrace(preStimSamples + 1:preStimSamples + length(positions)) = positions;
            for i = preStimSamples + length(positions) + 1:length(posTrace)
                posTrace(i) = positions(time * 2);
            end
            % make the trace decay to zero
            decayTrace = zeros(samples, 1);
            decayValue = mean(posTrace(1:floor(data.sampleRateHz * 0.250))); 
            multiplier = 1.0 / (0.250 * data.sampleRateHz);                % tau of 250 ms
            for i = 1:samples
                decayTrace(i) = decayValue;
                decayValue = decayValue * (1.0 - multiplier) + posTrace(i) * multiplier;
            end
            % add random noise
            posTrace = posTrace - decayTrace + 2.0 * rand(size(posTrace)) - 1.0;
            % smooth with a boxcar to take out the highest frequencies
            filterSamples = max(1, floor(data.sampleRateHz * 10.0 / 1000.0));
            b = (1 / filterSamples) * ones(1, filterSamples);
            posTrace = filter(b, 1, posTrace);
            % add 60Hz noise
            dt = 1/data.sampleRateHz;                   % seconds per sample
            t = (0:dt:samples * dt - dt)';              % seconds
            posTrace = posTrace + cos(2.0 * pi * 60 * t) * 0.25;
        end
        
        %% findSaccade: extract the saccade timing using speed threshold
        function [sIndex, eIndex] = findSaccade(obj, data, posTrace, velTrace, stepSign, startIndex)
%            calSamples = floor(data.prestimDurS * data.sampleRateHz);    % use preStim for calibration
            if data.calTrialsDone < 4                              	% still getting a calibration
                if (stepSign == 1)
                    DPV = abs(data.stepSizeDeg / (max(posTrace(:)) - mean(posTrace(1:startIndex)))); 
                    range = (max(posTrace(:)) - mean(posTrace(1:startIndex)));
                else
                    DPV = abs(data.stepSizeDeg / (mean(posTrace(1:startIndex) - min(posTrace(:)))));
                    range = (mean(posTrace(1:startIndex) - min(posTrace(:))));
                end
                fprintf('stepDeg %.1f rangeV: %.1f DPV %.1f\n', data.stepSizeDeg, range, DPV);
                obj.degPerV = (obj.degPerV * data.calTrialsDone + DPV) / (data.calTrialsDone + 1);
                obj.degPerSPerV = obj.degPerV * data.sampleRateHz;	% needed for velocity plots
                data.calTrialsDone = data.calTrialsDone + 1;
                sIndex = 0; eIndex = 0;
                return;                                             % no saccades until we have a calibration
            end
            sIndex = startIndex;
            seq = 0;
            seqLength = 5;                                          % number seq. samples used for saccade detection
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
                if eIndex - sIndex < 0.005 * data.sampleRateHz      % no saccades less than 5 ms
                    sIndex = 0;
                    eIndex = 0;
                end
            else
                sIndex = 0;
                eIndex = 0;
            end
            % add some jitter to defeat the alignment on noise
            if sIndex > 0 && eIndex > 0
                offset = floor(data.sampleRateHz * 0.01666 * rand(1));
                sIndex = sIndex - offset;
                eIndex = eIndex - offset;
            end
            fprintf('startIndex %f endIndex %f\n', sIndex, eIndex);
        end

        %% processSignals: function to process data from one trial
        function [startIndex, endIndex] = processSignals(obj, data)
            c = RTConstants;
            % remove the DC offset
            if ~data.testMode
                data.posTrace = data.rawData - mean(data.rawData(1:floor(data.sampleRateHz * data.prestimDurS)));
            else
                data.posTrace = fakeDataTrace(obj, data);
            end
            % do 60 Hz filtering
            if data.doFilter
                data.posTrace = filter(data.filter60Hz, data.posTrace);
            end
            % make the velocity trace and then apply boxcar filter
            data.velTrace(1:end - 1) = diff(data.posTrace);
            data.velTrace(end) = data.velTrace(end - 1);
            if data.doFilter
                data.velTrace = filter(data.filterLP, data.velTrace);
            end
            % find a saccade and make sure we have enough samples before and after its start
            sIndex = floor(data.targetTimeS * data.sampleRateHz); 	% no saccades before stimon
            [startIndex, endIndex] = obj.findSaccade(data, data.posTrace, data.velTrace, data.stepDirection, sIndex);
            saccadeOffset = floor(data.saccadeSamples / 2);
            firstIndex = startIndex - saccadeOffset;
            lastIndex = startIndex + saccadeOffset;
            if mod(data.saccadeSamples, 2) == 0                     % make sure the samples are divisible by 2
                lastIndex = lastIndex - 1;
            end
            if (firstIndex < 1 || lastIndex > data.trialSamples)    % not enough samples around saccade to process
                startIndex = 0;
                return;
            end
            % sum into the average pos and vel plot, inverting for negative steps
            data.posSummed = data.posSummed + data.posTrace(firstIndex:lastIndex) * data.stepDirection;  
            data.velSummed = data.velSummed + data.velTrace(firstIndex:lastIndex) * data.stepDirection;  
            % tally the sums and compute the averages
            data.numSummed = data.numSummed + 1;
            data.posAvg = data.posSummed / data.numSummed;
            data.velAvg = data.velSummed / data.numSummed;
            data.trialTypesDone(data.trialType) = data.trialTypesDone(data.trialType) + 1;
            % now that we've updated all the traces, compute the degrees per volt if we have enough trials
            % take average peaks to get each point
            if data.trialType ~= c.kCenteringTrial && sum(data.numSummed) > c.kTrialTypes
                rangeV = max(data.posAvg) - min(data.posAvg);
                obj.degPerV = mean(data.stepSizeDeg ./ rangeV);
                fprintf('avg: max %.1f min %.1f degPerV %.1f\n', max(data.posAvg), min(data.posAvg), obj.degPerV);
                obj.degPerSPerV = obj.degPerV * data.sampleRateHz;          % needed for velocity plots
            end
        end
   
    end
end

