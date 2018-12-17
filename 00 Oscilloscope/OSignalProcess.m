classdef OSignalProcess < handle
    % OSignalProcess
    %   Support for filtering voltage traces and finding spikes
    properties
        fH
        outSampleRatio
    end
    
    methods
          %% Object Initialization %%
        function obj = OSignalProcess(handles)
            obj = obj@handle();                                            % object initialization
            obj.fH = handles;
            inSampleRateHz = handles.lbj.SampleRateHz;
            obj.outSampleRatio = 1;
            outSampleRateHz = inSampleRateHz;
            while outSampleRateHz < 8000                                    % must be 8 kHz or greater
                obj.outSampleRatio = obj.outSampleRatio + 1;
                outSampleRateHz = inSampleRateHz * obj.outSampleRatio;
            end
        end
        
        %% clearAll: clear buffers
        function clearAll(obj)
            obj.fH.data.inSpike = false;
        end
        
        %% processSignals: function to process data from one trial
        function processSignals(obj, data, old, new)
            data.rawTrace(old + 1:old + new) = data.rawData(old + 1:old + new);
            data.filteredTrace(old + 1:old + new) = filter(data.filter, data.rawData(old + 1:old + new));
            % Find spikes
            if data.thresholdV >= 0
                sIndices = find(data.filteredTrace(old + 1:old + new) > data.thresholdV);
            else
                sIndices = find(data.filteredTrace(old + 1:old + new) < data.thresholdV);
            end
           if isempty(sIndices)                                    % nothing above threshold
                data.inSpike = false;                               % clear the inSpike flag
            else
            % If we entered this call partway through a spike, we need to get rid of any trailing parts of the spike.
            % That tail will start at index 1, so we can just eliminate from sIndices all indices that are equal to
            % their own index
                if data.inSpike                                     % we were part way through a spike before
                    for i = 1:length(sIndices)
                        if sIndices(i) ~= i
                            data.inSpike = false;                   % clear the inSpike flag
                            break;
                        end
                    end
                    if data.inSpike                                 % never got out of spike, return
                        return;
                    end
                    sIndices = sIndices(i:end);
                end
                numSpikes = 1;                                      % we have one spike (at least)
                lastIndex = sIndices(1);                            % used to find gaps between spikes
                spikeIndices = lastIndex;                           % save the start of this spike
                if length(sIndices) > 1                             % for all the remaining indices...
                    for i = 2:length(sIndices)
                        if sIndices(i) > lastIndex + 1 && (sIndices(i) - lastIndex) > obj.fH.plots.triggerSamples
                            numSpikes = numSpikes + 1;              % it's a new spike
                            spikeIndices(numSpikes) = sIndices(i);  % record the index for this spike
                        end
                        lastIndex = sIndices(i);                    % used to find gaps between spikes
                    end
                end
                if sIndices(end) == new                             % end of new data in middle of a spike?
                    data.inSpike = true;
                end
                data.spikeIndices = [data.spikeIndices, spikeIndices + old]; % add new spikes to the list of spikes
            end
            data.lastSpikeIndex = data.lastSpikeIndex - new;        % save index for computing ISIs
       end
        
    end

end

