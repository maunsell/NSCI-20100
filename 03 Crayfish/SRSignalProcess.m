classdef SRSignalProcess < handle
    % SRSignalProcess
    %   Support for filtering voltage traces and finding spikes
    properties
        audioBuffer
        audioBufferSize
        audioMultiplier
        audioOutDevice
        fH
        audioOutIndex
        outSampleRatio
    end
    
    methods
          %% Object Initialization %%
        function obj = SRSignalProcess(handles)
            obj = obj@handle();                                            % object initialization
            obj.fH = handles;
            inSampleRateHz = handles.lbj.SampleRateHz;
            obj.outSampleRatio = 1;
            outSampleRateHz = inSampleRateHz;
            while outSampleRateHz < 8000                                    % must be 8 kHz or greater
                obj.outSampleRatio = obj.outSampleRatio + 1;
                outSampleRateHz = inSampleRateHz * obj.outSampleRatio;
            end
            obj.audioBufferSize = 512;
            while mod(obj.audioBufferSize, obj.outSampleRatio) ~= 0         % must fit whole sample ratios
                obj.audioBufferSize = obj.audioBufferSize + 1;
            end
            obj.audioBuffer = int16(zeros(obj.audioBufferSize, 1));
            obj.audioOutIndex = 0;
            obj.audioOutDevice = audioDeviceWriter('SampleRate', outSampleRateHz, ...
                'SupportVariableSizeInput', true, 'BufferSize', obj.audioBufferSize);
            setVolume(obj);
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
        
        %% clearAll: clear buffers and release audio output hardware
        function clearAll(obj)
            release(obj.audioOutDevice);
            obj.audioOutIndex = 0;
        end
        
        %% processSignals: function to process data from one trial
        function processSignals(obj, data, old, new)
            data.rawTrace(old + 1:old + new) = data.rawData(old + 1:old + new);
            data.filteredTrace(old + 1:old + new) = filter(data.filter, data.rawData(old + 1:old + new));
            inIndex = old;                              % range to read from filtered trace
            inEndIndex = old + new;
            while inIndex < inEndIndex                         % output in chunk of audioBufferSize
                inNum = min(inEndIndex - inIndex, ...
                    (obj.audioBufferSize - obj.audioOutIndex) / obj.outSampleRatio);
                ptr = obj.audioOutIndex + 1;
                for i = inIndex + 1:inIndex + inNum
                    for rep = 1:obj.outSampleRatio
                        obj.audioBuffer(ptr) = int16(data.filteredTrace(i) * obj.audioMultiplier);
                        ptr = ptr + 1;
                    end
                end
                if obj.audioOutIndex + inNum * obj.outSampleRatio == obj.audioBufferSize
                   try                                         % full buffer, send to audio output
                        underrun = obj.audioOutDevice(obj.audioBuffer);
                        if underrun ~= 0
                            fprintf('Audio underrun (%d samples)\n', underrun / obj.outSampleRatio);
                        end
                    catch
                        fprintf('error trying to output to audioOutDevice');
                    end
                    obj.audioOutIndex = 0;                      % start a new buffer
                else
                    obj.audioOutIndex = obj.audioOutIndex + inNum * obj.outSampleRatio;
                end
                if obj.audioOutIndex > obj.audioBufferSize
                    fprintf('Audio buffer mishandling -- buffer overrun\n');
                end
                inIndex = inIndex + inNum;  
            end

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
                        if sIndices(i) > lastIndex + 1 && (sIndices(i) - lastIndex) > obj.fH.plots.triggerSamples
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
        
        %% setVolume -- set volume based on the volume slider
        function setVolume(obj)
            obj.audioMultiplier = 10^get(obj.fH.volumeSlider, 'value');
        end

    end
end

