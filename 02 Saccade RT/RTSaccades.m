classdef EOGSaccades < handle
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
        function [sIndex, eIndex] = findSaccade(obj, data, posTrace, velTrace, stepSign, startIndex)
%            calSamples = floor(data.prestimDurS * data.sampleRateHz);    % use preStim for calibration
            seqLength = 5;
            if data.calTrialsDone < 4                                    % still getting a calibration
                if (stepSign == 1)
                    DPV = abs(data.offsetsDeg(data.offsetIndex) / (max(posTrace(:)) - mean(posTrace(1:startIndex)))); 
                else
                    DPV = abs(data.offsetsDeg(data.offsetIndex) / (mean(posTrace(1:startIndex) - min(posTrace(:)))));
                end
                obj.degPerV = (obj.degPerV * data.calTrialsDone + DPV) / (data.calTrialsDone + 1);
                obj.degPerSPerV = obj.degPerV * data.sampleRateHz;      % needed for velocity plots
                data.calTrialsDone = data.calTrialsDone + 1;
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
        end

        %% processSignals: function to process data from one trial
        function [startIndex, endIndex] = processSignals(obj, data)
            % remove the DC offset
           if ~data.testMode
                data.posTrace = data.rawData - mean(data.rawData(1:floor(data.sampleRateHz * data.prestimDurS)));
            else
                samples = length(data.posTrace);
                data.posTrace = zeros(samples, 1);
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
                preStimSamples = floor((data.stimTimeS + 0.1) * data.sampleRateHz);
                data.posTrace(preStimSamples + 1:preStimSamples + length(positions)) = positions;
                for i = preStimSamples + length(positions) + 1:length(data.posTrace)
                    data.posTrace(i) = positions(time * 2);
                end
                % make the trace decay to zero
                decayTrace = zeros(samples, 1);
                decayValue = mean(data.posTrace(1:floor(data.sampleRateHz * 0.250))); 
                multiplier = 1.0 / (0.250 * data.sampleRateHz);                % tau of 250 ms
                for i = 1:samples
                    decayTrace(i) = decayValue;
                    decayValue = decayValue * (1.0 - multiplier) + data.posTrace(i) * multiplier;
                end
                % decay to zero and add random noise
                data.posTrace = data.posTrace - decayTrace + 2.0 * rand(size(data.posTrace)) - 1.0;
                % smooth with a boxcar to take out the highest frequencies
                filterSamples = max(1, floor(data.sampleRateHz * 10.0 / 1000.0));
                b = (1 / filterSamples) * ones(1, filterSamples);
                data.posTrace = filter(b, 1, data.posTrace);
                % add 60Hz noise
                dt = 1/data.sampleRateHz;                   % seconds per sample
                t = (0:dt:samples * dt - dt)';              % seconds
                data.posTrace = data.posTrace + cos(2.0 * pi * 60 * t) * 0.25;
            end
            % do 60 Hz filtering
            if data.doFilter
                data.posTrace = filter(data.filter60Hz, data.posTrace);
            end
            % make the velocity trace and then apply boxcar filter
            data.velTrace(1: end - 1) = diff(data.posTrace);
            data.velTrace(end) = data.velTrace(end - 1);
            if data.doFilter
                data.velTrace = filter(data.filterLP, data.velTrace);
            end
            % find a saccade and make sure we have enough samples before and after its start
%             sIndex = floor(data.stimTimeS * data.sampleRateHz);         % no saccades before stimon
            sIndex = floor(data.prestimDurS * data.sampleRateHz);
            [startIndex, endIndex] = obj.findSaccade(data, data.posTrace, data.velTrace, data.stepSign, sIndex);
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
            data.posSummed(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex) + ...
                data.posTrace(firstIndex:lastIndex);  
            data.velSummed(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex) + ...
                data.velTrace(firstIndex:lastIndex);  
            % tally the sums and compute the averages
            data.numSummed(data.offsetIndex) = data.numSummed(data.offsetIndex) + 1;
            data.posAvg(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex) / data.numSummed(data.offsetIndex);
            data.velAvg(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex) / data.numSummed(data.offsetIndex);
            data.offsetsDone(data.offsetIndex) = data.offsetsDone(data.offsetIndex) + 1;
           % now that we've updated all the traces, compute the degrees per volt if we have enough trials
            % take average peaks to get each point
            if sum(data.numSummed) > length(data.numSummed)
                endPointsV = [max(data.posAvg(:, 1:data.numOffsets / 2)) ...
                                min(data.posAvg(:, data.numOffsets / 2 + 1:data.numOffsets))];
                obj.degPerV = mean(data.offsetsDeg ./ endPointsV);
                obj.degPerSPerV = obj.degPerV * data.sampleRateHz;          % needed for velocity plots
            end
            % find the average saccade duration using the average speed trace
            [sAvgIndex, eAvgIndex] = obj.findSaccade(data, data.posAvg(:, data.offsetIndex), ...
                        data.velAvg(:, data.offsetIndex), data.stepSign, length(data.posAvg(:, data.offsetIndex)) / 2);
           if eAvgIndex > sAvgIndex 
                data.saccadeDurS(data.absStepIndex) = (eAvgIndex - sAvgIndex) / data.sampleRateHz;
            else
                data.saccadeDurS(data.absStepIndex) = 0;
            end
        end
   
    end
end

