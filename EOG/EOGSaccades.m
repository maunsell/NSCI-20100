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
        function [sIndex, eIndex] = findSaccade(obj, data, posTrace, velTrace, stepSign)
           calSamples = floor(data.prestimDurS * data.sampleRateHz);    % use preStim for calibration
           if data.calTrialsDone < 4                                    % still getting a calibration
                mean(posTrace(1:calSamples));
                min(posTrace(:));
                max(posTrace(:))    ;            
                if (stepSign == 1)
                    DPV = abs(data.offsetsDeg(data.offsetIndex) /...
                             (max(posTrace(:)) - mean(posTrace(1:calSamples)))); 

                else
                    DPV = abs(data.offsetsDeg(data.offsetIndex) /...
                             (mean(posTrace(1:calSamples) - min(posTrace(:)))));
                end
                obj.degPerV = (obj.degPerV * data.calTrialsDone + DPV) / (data.calTrialsDone + 1);
                obj.degPerSPerV = obj.degPerV * data.sampleRateHz;      % needed for velocity plots
                data.calTrialsDone = data.calTrialsDone + 1;
                sIndex = 0; eIndex = 0;
                return;
            end
            sIndex = floor(data.stimTimeS * data.sampleRateHz);         % no saccades before stimon
            seq = 0;
            thresholdV = mean(posTrace(1:calSamples)) + obj.thresholdDeg / obj.degPerV;
            while (seq < 5 && sIndex < length(posTrace))	% find the first sequence of 5 > than threshold
                if posTrace(sIndex) * stepSign < thresholdV
                    seq = 0;
                else
                    seq = seq + 1;
                end
                sIndex = sIndex + 1;
            end
            % if we found a saccade start, look for the saccade end, consisting of 5 samples below the peak
            if sIndex < length(posTrace)
                seq = 0;
                maxPos = posTrace(sIndex);
                maxIndex = sIndex;
                eIndex = sIndex;
                while seq < 5 && eIndex < (length(posTrace) - 1)
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
                    while sIndex > calSamples && velTrace(sIndex - 1) * stepSign > 0
                        sIndex = sIndex - 1;
                    end
                end
                if eIndex - sIndex < 0.005 * data.sampleRateHz;      % no saccades less than 5 ms
                    sIndex = 0;
                    eIndex = 0;
                end
            else
                sIndex = 0;
                eIndex = 0;
            end
        end

        %% processSignals: function to process data from one trial
        function [startIndex, endIndex] = processSignals(obj, data)
            data.posTrace = data.rawData - mean(data.rawData(1:floor(data.sampleRateHz * data.prestimDurS)));
            if data.testMode                % in test mode filter and add some noise to make things realistic
                decayTrace = zeros(length(data.posTrace), 1);
                decayValue = mean(data.posTrace(1:floor(data.sampleRateHz * 0.250))); 
                multiplier = 1.0 / (0.250 * data.sampleRateHz);                % tau of 250 ms
                for i = 1:length(decayTrace)
                    decayTrace(i) = decayValue;
                    decayValue = decayValue * (1.0 - multiplier) + data.posTrace(i) * multiplier;
                end
                data.posTrace = data.posTrace - decayTrace + 0.3 * rand(size(data.posTrace)) - 0.15;
                filterSamples = floor(data.sampleRateHz * 50.0 / 1000.0);      % smooth with 50 ms boxcar   
                b = (1 / filterSamples) * ones(1, filterSamples);
                data.posTrace = filter(b, 1, data.posTrace);
           end
            % make the velocity trace and then apply boxcar filter
%             data.posTrace = filter(b, 1, data.posTrace);
            data.velTrace(1:end - 1) = diff(data.posTrace);
            data.velTrace(end) = data.velTrace(end - 1);
            filterSamples = floor(data.sampleRateHz * obj.filterWidthMS / 1000.0);     
            b = (1 / filterSamples) * ones(1, filterSamples);
            data.velTrace = filter(b, 1, data.velTrace);
            % find a saccade and make sure we have enough samples before and after its start
            [startIndex, endIndex] = obj.findSaccade(data, data.posTrace, data.velTrace, data.stepSign);
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
            if (data.stepSign == 1)
                data.posSummed(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex)... 
                            + data.posTrace(firstIndex:lastIndex);  
                data.velSummed(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex)... 
                            + data.velTrace(firstIndex:lastIndex);  
            else
                data.posSummed(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex)...
                            - data.posTrace(firstIndex:lastIndex);  
                data.velSummed(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex)... 
                            - data.velTrace(firstIndex:lastIndex);  
            end
            % tally the sums and compute the averages
            data.numSummed(data.offsetIndex) = data.numSummed(data.offsetIndex) + 1;
            data.posAvg(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex) ...
                / data.numSummed(data.offsetIndex);
            data.velAvg(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex) ...
                / data.numSummed(data.offsetIndex);
            data.offsetsDone(data.offsetIndex) = data.offsetsDone(data.offsetIndex) + 1;
            % now that we've updated all the traces, compute the degrees per volt if
            % we have enough trials
            if sum(data.numSummed) > length(data.numSummed)
%                 calSamples = floor(0.050 * data.sampleRateHz);            % use last 50 ms of position trace
                endPointsV = max(data.posAvg(:, :));                        % take average peaks to get each point
                obj.degPerV = mean(data.offsetsDeg ./ endPointsV);
                obj.degPerSPerV = obj.degPerV * data.sampleRateHz;          % needed for velocity plots
            end
            % find the average saccade duration using the average speed trace
            [sAvgIndex, eAvgIndex] = obj.findSaccade(data, data.posAvg(:, data.offsetIndex), ...
                            data.velAvg(:, data.offsetIndex), 1);
            if eAvgIndex > sAvgIndex 
                data.saccadeDurS(data.offsetIndex) = eAvgIndex - sAvgIndex;
            else
                data.saccadeDurS(data.offsetIndex) = 0;
            end
        end
   
    end
end

