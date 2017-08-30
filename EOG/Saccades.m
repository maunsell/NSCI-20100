classdef Saccades < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
        thresholdDPS = 0;
        degPerSPerV = 0;
        degPerV = 0;
    end
    
    methods
    %% findSaccade: extract the saccade timing using speed threshold
    
    function [sIndex, eIndex] = findSaccade(obj, taskData, theTrace, stepSign)
        if sum(taskData.numSummed) < length(taskData.numSummed)
            DPV = abs(taskData.offsetsDeg(taskData.offsetIndex) /...
                                            (mean(taskData.posTrace(end - 50:end)) - mean(taskData.posTrace(1:50))));
        else
            DPV = obj.degPerV;
        end
        DPSPV = DPV * taskData.sampleRateHz;                        % degrees per second per volt unit
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
    function [taskData, startIndex, endIndex] = processSignals(obj, taskData)
        taskData.posTrace = taskData.rawData(:, 1) - taskData.rawData(:, 2);
        taskData.posTrace = taskData.posTrace - ...
                                    mean(taskData.posTrace(1:floor(taskData.sampleRateHz * taskData.prestimDurS)));
        % Debug: add some noise to make things realistic
        taskData.posTrace = taskData.posTrace + 0.3 * rand(size(taskData.posTrace)) - 0.15;
        
        % do a boxcar filter of the raw signal
        windowSize = 50;
        b = (1 / windowSize) * ones(1, windowSize);
        taskData.posTrace = filter(b, 1, taskData.posTrace);
        taskData.velTrace(1:end - 1) = diff(taskData.posTrace);
        taskData.velTrace(end) = taskData.velTrace(end - 1);

        % if we don't have a complete block yet, estimate the degPerV using the
        % start and end of the trial
        [startIndex, endIndex] = obj.findSaccade(taskData, taskData.velTrace, taskData.stepSign);
        saccadeOffset = floor(taskData.saccadeSamples / 2);
        if (startIndex - saccadeOffset < 1 || startIndex + saccadeOffset > taskData.trialSamples)
            startIndex = 0;
        end
        if startIndex == 0
            return;
        end
        if (taskData.stepSign == 1)
            taskData.posSummed(:, taskData.offsetIndex) = taskData.posSummed(:, taskData.offsetIndex)... 
                        + taskData.posTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
            taskData.velSummed(:, taskData.offsetIndex) = taskData.velSummed(:, taskData.offsetIndex)... 
                        + taskData.velTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
        else
            taskData.posSummed(:, taskData.offsetIndex) = taskData.posSummed(:, taskData.offsetIndex)...
                        - taskData.posTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
            taskData.velSummed(:, taskData.offsetIndex) = taskData.velSummed(:, taskData.offsetIndex)... 
                        - taskData.velTrace(startIndex - saccadeOffset:startIndex + saccadeOffset - 1);  
        end
        taskData.numSummed(taskData.offsetIndex) = taskData.numSummed(taskData.offsetIndex) + 1;
        taskData.posAvg(:, taskData.offsetIndex) = taskData.posSummed(:, taskData.offsetIndex) ...
            / taskData.numSummed(taskData.offsetIndex);
        taskData.velAvg(:, taskData.offsetIndex) = taskData.velSummed(:, taskData.offsetIndex) ...
            / taskData.numSummed(taskData.offsetIndex);
        taskData.offsetsDone(taskData.offsetIndex) = taskData.offsetsDone(taskData.offsetIndex) + 1;
        
        % now that we've updated all the traces, compute the degrees per volt if
        % we have enough trials
        
        if sum(taskData.numSummed) < length(taskData.numSummed)
            obj.degPerV = 0.0;
        else
            endPointsV = mean(taskData.posAvg(end - 50:end, :));        % average trace ends to get each endpoint
            obj.degPerV = mean(taskData.offsetsDeg ./ endPointsV);
        end
        obj.degPerSPerV = obj.degPerV * taskData.sampleRateHz;
        
        % find the average saccade duration using the average speed trace
        
        [sAvgIndex, eAvgIndex] = obj.findSaccade(taskData, taskData.velAvg(:, taskData.offsetIndex), 1);
        taskData.saccDur(taskData.offsetIndex) = eAvgIndex - sAvgIndex;
    end
   
    end
end

