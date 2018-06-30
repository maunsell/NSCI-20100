classdef SRSignalProcess < handle
    % SRSignalProcess
    %   Support for filtering voltage traces and finding spikes
    properties
        fH
    end
    
    methods
          %% Object Initialization %%
        function obj = SRSignalProcess(handles)
            obj = obj@handle();                                            % object initialization
            obj.fH = handles;
        end

        %% addISI: add a spike time to the spike time array
        function addISI(obj, data, spikeIndex)
            if data.lastSpikeIndex > data.maxContSamples      	% first spike, no ISI, just save this index
                data.lastSpikeIndex = spikeIndex;
                return;
            end
            addISI(obj.fH.isiPlot, (spikeIndex - data.lastSpikeIndex) / data.sampleRateHz * 1000.0);
            data.lastSpikeIndex = spikeIndex;                   % update the reference index
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
            if ~isempty(sIndices)
                numSpikes = 1;
                lastIndex = sIndices(1);
                spikeIndices = lastIndex;
                addISI(obj, data, sIndices(1));
                if length(sIndices) > 1 
                    for i = 2:length(sIndices)
                        if sIndices(i) > lastIndex + 1 && (sIndices(i) - lastIndex) > data.spikeSamples
                            numSpikes = numSpikes + 1;
                            spikeIndices(numSpikes) = sIndices(i);
                            addISI(obj, data, sIndices(i));
                        end
                        lastIndex = sIndices(i);
                    end
                end
                data.spikeIndices = [data.spikeIndices, spikeIndices + old];
            end
            data.lastSpikeIndex = data.lastSpikeIndex - new;
        end
    end
end

