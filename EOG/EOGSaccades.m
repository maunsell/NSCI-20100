classdef EOGSaccades < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
        filterWidthMS = 0;
        thresholdDPS = 0;
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

        function [sIndex, eIndex] = findSaccade(obj, data, theTrace, stepSign)
            if data.calTrialsDone < 4                               % still getting a calibration
                calSamples = floor(0.050 * data.sampleRateHz);      % compare 50 ms at start and end
                DPV = abs(data.offsetsDeg(data.offsetIndex) /...
                             (mean(data.posTrace(end - calSamples:end)) - mean(data.posTrace(1:calSamples))));
                obj.degPerV = (obj.degPerV * data.calTrialsDone + DPV) / (data.calTrialsDone + 1);
                obj.degPerSPerV = obj.degPerV * data.sampleRateHz;
               data.calTrialsDone = data.calTrialsDone + 1;
                sIndex = 0; eIndex = 0;
                return;
%             if sum(data.numSummed) < length(data.numSummed)         % are we calibrated?
%                 calSamples = floor(0.050 * data.sampleRateHz);      % no, compare 50 ms at start and end;
%                 DPV = abs(data.offsetsDeg(data.offsetIndex) /...
%                              (mean(data.posTrace(end - calSamples:end)) - mean(data.posTrace(1:calSamples))));
% %                 DPV = abs(data.offsetsDeg(data.offsetIndex) /...
% %                              (max(data.posTrace(:)) / 2 - mean(data.posTrace(1:calSamples))));
%             else
%                 DPV = obj.degPerV;
            end
%             DPSPV = obj.degPerV * data.sampleRateHz;                        % degrees per s per sample
            if (stepSign == 1)
                fast = theTrace >= obj.thresholdDPS / obj.degPerSPerV;
%                 fast = theTrace >= 0.0150;
                
                
                [~, maxIndex] = max(theTrace);
            else
                fast = theTrace <= -obj.thresholdDPS / obj.degPerSPerV;
%                 fast = theTrace <= -0.0150;
                
                
                
                [~, maxIndex] = min(theTrace);
            end
            sIndex = 1;
            seq = 0;
            while (seq < 5 && sIndex < length(fast))                % find the first sequence of 5 > than threshold
                if fast(sIndex) == 0 
                    seq = 0;
                else
                    seq = seq + 1;
                end
                sIndex = sIndex + 1;
            end
            if sIndex < length(fast)
                sIndex = sIndex - 5;
                eIndex = max(sIndex, maxIndex);
                seq = 0;
                while (seq < 5 && eIndex < length(fast))
                    if fast(eIndex) == 0
                        seq = seq + 1;
                    else
                        seq = 0;
                    end
                    eIndex = eIndex + 1;
                end
                if eIndex >= length(fast)
                    eIndex = 0;
                else
                    eIndex = eIndex - 5;
                end
            else
                sIndex = 0;
                eIndex = 0;
            end
        end

        %% processSignals: function to process data from one trial
        function [startIndex, endIndex] = processSignals(obj, data)
            % take the difference between the electrodes, and then normalize to
            % prestim voltage
%             data.posTrace = data.rawData(:, 1) - data.rawData(:, 2);    % take differences between electrodes
            data.posTrace = data.rawData;
            data.posTrace = data.posTrace - ...
                                        mean(data.posTrace(1:floor(data.sampleRateHz * data.prestimDurS)));
            % debug: add some noise to make things realistic
            if data.testMode
                data.posTrace = data.posTrace + 0.3 * rand(size(data.posTrace)) - 0.15;
            end
            % boxcar filter of the raw signal and make the velocity trace
            filterSamples = floor(data.sampleRateHz * obj.filterWidthMS / 1000.0);     
            b = (1 / filterSamples) * ones(1, filterSamples);
            data.posTrace = filter(b, 1, data.posTrace);
            data.velTrace(1:end - 1) = diff(data.posTrace);
            data.velTrace(end) = data.velTrace(end - 1);
          % find a saccade and make sure we have enough samples before and
            % after its start
            [startIndex, endIndex] = obj.findSaccade(data, data.velTrace, data.stepSign);
            saccadeOffset = floor(data.saccadeSamples / 2);
            firstIndex = startIndex - saccadeOffset;
            lastIndex = startIndex + saccadeOffset;
            if mod(data.saccadeSamples, 2) == 0
                lastIndex = lastIndex - 1;
            end
            if (firstIndex < 1 || lastIndex > data.trialSamples)
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
                calSamples = floor(0.050 * data.sampleRateHz);                         % use last 50 ms of position trace
                endPointsV = mean(data.posAvg(end - calSamples:end, :));        % average trace ends to get each endpoint
                obj.degPerV = mean(data.offsetsDeg ./ endPointsV);
            end
            % find the average saccade duration using the average speed trace
            [sAvgIndex, eAvgIndex] = obj.findSaccade(data, data.velAvg(:, data.offsetIndex), 1);
            if eAvgIndex > sAvgIndex 
                data.saccadeDurS(data.offsetIndex) = eAvgIndex - sAvgIndex;
            else
                data.saccadeDurS(data.offsetIndex) = 0;
            end
        end
   
    end
end

