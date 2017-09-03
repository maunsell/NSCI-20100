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
            if sum(data.numSummed) < length(data.numSummed)
                DPV = abs(data.offsetsDeg(data.offsetIndex) /...
                                                (mean(data.posTrace(end - 50:end)) - mean(data.posTrace(1:50))));
            else
                DPV = obj.degPerV;
            end
            DPSPV = DPV * data.sampleRateHz;                        % degrees per second per volt unit
            if (stepSign == 1)
                fast = theTrace >= obj.thresholdDPS / DPSPV;
                [~, maxIndex] = max(theTrace);
            else
                fast = theTrace <= -obj.thresholdDPS / DPSPV;
                [~, maxIndex] = min(theTrace);
            end
            sIndex = 1;
            seq = 0;
            while (seq < 5 && sIndex < length(fast))                     % find the first sequence of 5 > than threshold
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
            data.posTrace = data.rawData(:, 1) - data.rawData(:, 2);
            data.posTrace = data.posTrace - ...
                                        mean(data.posTrace(1:floor(data.sampleRateHz * data.prestimDurS)));
            % Debug: add some noise to make things realistic
            data.posTrace = data.posTrace + 0.3 * rand(size(data.posTrace)) - 0.15;

            % do a boxcar filter of the raw signal
            filterSamples = floor(data.sampleRateHz * obj.filterWidthMS / 1000.0);     
            b = (1 / filterSamples) * ones(1, filterSamples);
            data.posTrace = filter(b, 1, data.posTrace);
            data.velTrace(1:end - 1) = diff(data.posTrace);
            data.velTrace(end) = data.velTrace(end - 1);

            % if we don't have a complete block yet, estimate the degPerV using the
            % start and end of the trial
            [startIndex, endIndex] = obj.findSaccade(data, data.velTrace, data.stepSign);
            saccadeOffset = floor(data.saccadeSamples / 2);
            if (startIndex - saccadeOffset < 1 || startIndex + saccadeOffset > data.trialSamples)
                startIndex = 0;
            end
            if startIndex == 0
                return;
            end
            if (data.stepSign == 1)
                data.posSummed(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex)... 
                            + data.posTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
                data.velSummed(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex)... 
                            + data.velTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
            else
                data.posSummed(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex)...
                            - data.posTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
                data.velSummed(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex)... 
                            - data.velTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
            end
            data.numSummed(data.offsetIndex) = data.numSummed(data.offsetIndex) + 1;
            data.posAvg(:, data.offsetIndex) = data.posSummed(:, data.offsetIndex) ...
                / data.numSummed(data.offsetIndex);
            data.velAvg(:, data.offsetIndex) = data.velSummed(:, data.offsetIndex) ...
                / data.numSummed(data.offsetIndex);
            data.offsetsDone(data.offsetIndex) = data.offsetsDone(data.offsetIndex) + 1;

            % now that we've updated all the traces, compute the degrees per volt if
            % we have enough trials

            if sum(data.numSummed) < length(data.numSummed)
                obj.degPerV = 0.0;
            else
                endPointsV = mean(data.posAvg(end - 50:end, :));        % average trace ends to get each endpoint
                obj.degPerV = mean(data.offsetsDeg ./ endPointsV);
            end
            obj.degPerSPerV = obj.degPerV * data.sampleRateHz;

            % find the average saccade duration using the average speed trace

            [sAvgIndex, eAvgIndex] = obj.findSaccade(data, data.velAvg(:, data.offsetIndex), 1);
            data.saccadeDurS(data.offsetIndex) = eAvgIndex - sAvgIndex;
        end
   
    end
end

