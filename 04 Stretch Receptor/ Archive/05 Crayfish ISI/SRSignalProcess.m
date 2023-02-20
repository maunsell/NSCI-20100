classdef SRSignalProcess < handle
  % SRSignalProcess
  %   Support for filtering voltage traces, audio out and finding spikes
  properties
    audioBuffer
    audioBufferSize
    audioMultiplier
    audioOutDevice
    audioOutIndex
    outSampleRatio
  end
  
  methods
    %% Object Initialization %%
    function obj = SRSignalProcess(app)
      obj = obj@handle();                                            % object initialization
      inSampleRateHz = app.lbj.SampleRateHz;
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
      setVolume(obj, app);
    end
    
    %% addISI: add a spike time to the spike time array
    function addISI(~, app, spikeIndex)
      if app.lastSpikeIndex > app.maxContSamples      	% first spike, no ISI, just save this index
        app.lastSpikeIndex = spikeIndex;
        return;
      end
      if ~atISILimit(app)
        addISI(app.isiPlot, app, (spikeIndex - app.lastSpikeIndex) / app.lbj.SampleRateHz * 1000.0);
        app.lastSpikeIndex = spikeIndex;                   % update the reference index
      end
    end
    
    %% clearAll: clear buffers and release audio output hardware
    function clearAll(obj, app)
      release(obj.audioOutDevice);
      obj.audioOutIndex = 0;
      app.inSpike = false;
    end
    
    %% processSignals: function to process data from one trial
    function processSignals(obj, app, old, new)
      app.rawTrace(old + 1:old + new) = app.rawData(old + 1:old + new);
      app.filteredTrace(old + 1:old + new) = filter(app.filter, app.rawData(old + 1:old + new));
      inIndex = old;                              % range to read from filtered trace
      inEndIndex = old + new;
      while inIndex < inEndIndex                         % output in chunk of audioBufferSize
        inNum = min(inEndIndex - inIndex, ...
          (obj.audioBufferSize - obj.audioOutIndex) / obj.outSampleRatio);
        ptr = obj.audioOutIndex + 1;
        for i = inIndex + 1:inIndex + inNum
          for rep = 1:obj.outSampleRatio
            obj.audioBuffer(ptr) = int16(app.filteredTrace(i) * obj.audioMultiplier);
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
      if app.thresholdV >= 0
        sIndices = find(app.filteredTrace(old + 1:old + new) > app.thresholdV);
      else
        sIndices = find(app.filteredTrace(old + 1:old + new) < app.thresholdV);
      end
      if isempty(sIndices)                                    % nothing above threshold
        app.inSpike = false;                               % clear the inSpike flag
      else
        % If we entered this call partway through a spike, we need to get rid of any trailing parts of the spike.
        % That tail will start at index 1, so we can just eliminate from sIndices all indices that are equal to
        % their own index
        if app.inSpike                                      % we were part way through a spike before
          for i = 1:length(sIndices)
            if sIndices(i) ~= i
              app.inSpike = false;                          % clear the inSpike flag
              break;
            end
          end
          if app.inSpike                                    % never got out of spike, return
            return;
          end
          sIndices = sIndices(i:end);
        end
        numSpikes = 1;                                      % we have one spike (at least)
        lastIndex = sIndices(1);                            % used to find gaps between spikes
        spikeIndices = lastIndex;                           % save the start of this spike
        addISI(obj, app, sIndices(1));                      % add this spike to the ISIs
        if length(sIndices) > 1                             % for all the remaining indices...
          for i = 2:length(sIndices)
            if sIndices(i) > lastIndex + 1 && (sIndices(i) - lastIndex) > app.tracePlots.triggerSamples
              numSpikes = numSpikes + 1;                    % it's a new spike
              spikeIndices(numSpikes) = sIndices(i);        % record the index for this spike
              addISI(obj, app, sIndices(i));                % add this spike to the ISIs
            end
            lastIndex = sIndices(i);                        % used to find gaps between spikes
          end
        end
        if sIndices(end) == new                             % end of new data in middle of a spike?
          app.inSpike = true;
        end
        app.spikeIndices = [app.spikeIndices, spikeIndices + old]; % add new spikes to the list of spikes
      end
      app.lastSpikeIndex = app.lastSpikeIndex - new;        % save index for computing ISIs
      % if we've just hit the ISI limit, ask the data collection to stop
      if atISILimit(app) && strcmp(app.startButton.Text, 'Stop')
        doStartButton(app);
      end
    end
    
    %% setVolume -- set volume based on the volume slider
    function setVolume(obj, app)
      obj.audioMultiplier = 10^get(app.volumeSlider, 'value');
    end
  end
end

