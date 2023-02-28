classdef SRSignalProcess < handle
  % SRSignalProcess
  %   Support for filtering voltage traces, audio out and finding spikes
  properties
    audioBuffer
    audioBufferSize
    audioMultiplier
    audioOutDevice
    audioOutIndex
    displaySamples
    fakeNoise
    fakeSpike             % profile of a fakeSpike
    fakeSpike0Drift        % drift in fake spike rate 
    lastProcessed         % last sample processed
    lastSpikeIndex        % index of last spike time processed
    lastSpikeTimeMS
    longCount
    longStartTimeMS
    nextFakeSpike0Sample
    outSampleRatio
    shortCount
    shortStartTimeMS
    tracesRead
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
      makeFakeSpike(obj, app);
      setVolume(obj, app);
      clearAll(obj, app);
    end
    
    % addISI: add a spike time to the spike time array
    % note that obj.lastSpikeIndex is maintained relative to the end of the
    % last read, and will frequently be negative. 
    function addISI(obj, app, spikeIndex)
      if obj.lastSpikeIndex > app.maxContSamples      	% first spike, no ISI, just save this index
        obj.lastSpikeIndex = spikeIndex;
        return;
      end
      if ~atCountLimit(app)
        addISI(app.isiPlot, app, (spikeIndex - obj.lastSpikeIndex) / app.lbj.SampleRateHz * 1000.0);
        obj.lastSpikeIndex = spikeIndex;                   % update the reference index
      end
    end
    
    % addSpikeTime: add a spike time to the long and short window counts.
    % We need to keep track of time across trace cycles. For this we use
    % tracesRead
    function addSpikeTime(obj, app, spikeIndex)
      if atCountLimit(app)
        return;
      end
      spikeTimeMS = (obj.lastProcessed + spikeIndex + obj.tracesRead * app.contSamples) / app.lbj.SampleRateHz * 1000.0;
      obj.lastSpikeTimeMS = spikeTimeMS;
      while spikeTimeMS > obj.shortStartTimeMS + app.shortWindowMS
        addShortCount(app.countPlot, app, obj.shortCount);
        obj.shortCount = 0;
        obj.shortStartTimeMS = obj.shortStartTimeMS + app.shortWindowMS;
      end
      obj.shortCount = obj.shortCount + 1;
     while spikeTimeMS > obj.longStartTimeMS + app.longWindowMS
       addLongCount(app.countPlot, app, obj.longCount);
       obj.longCount = 0;
       obj.longStartTimeMS = obj.longStartTimeMS + app.longWindowMS;
      end
      obj.longCount = obj.longCount + 1;
   end

    % clearAll: clear buffers and release audio output hardware
    function clearAll(obj, app)
      obj.audioOutIndex = 0;
      obj.lastProcessed = 0;
      obj.lastSpikeTimeMS = 0;
      obj.longCount = 0;
      obj.longStartTimeMS = 0;
      obj.lastSpikeIndex = 2 * app.maxContSamples;              % flag start of ISI sequence
      obj.nextFakeSpike0Sample = floor(app.lbj.SampleRateHz / app.fakeSpikeRateHz);
      obj.fakeSpike0Drift = randn() * 0.0002;
      obj.shortCount = 0;
      obj.shortStartTimeMS = 0;
      obj.tracesRead = 0;
      app.inSpike = false;
    end
    
    % insertFakeSpikes: replace the rawData with synthetic data
    function insertFakeSpikes(obj, app)
      app.rawData(obj.lastProcessed + 1:app.samplesRead) = ...
                          rand(1, app.samplesRead - obj.lastProcessed) * obj.fakeNoise;
      while obj.nextFakeSpike0Sample < app.samplesRead
        endSample = obj.nextFakeSpike0Sample + length(obj.fakeSpike) - 1;
        app.rawData(obj.nextFakeSpike0Sample:endSample) = obj.fakeSpike + ...
                          rand(1, length(obj.fakeSpike)) * obj.fakeNoise - obj.fakeNoise / 2.0;
        app.samplesRead = max(app.samplesRead, endSample);
        obj.nextFakeSpike0Sample = obj.nextFakeSpike0Sample + ...
                  floor(app.lbj.SampleRateHz / app.fakeSpikeRateHz * (1 + randn() * 0.1));
        app.fakeSpikeRateHz = max(1.0, min(35, app.fakeSpikeRateHz * (1 + obj.fakeSpike0Drift)));
      end
    end

    % makeFakeSpike: make a trace with a spike profile for test mode
    function makeFakeSpike(obj, app)
      spikeDurMS = 5;
      templateSampleRateKHz = 10;
      templateSamples = spikeDurMS * templateSampleRateKHz;
      templateSpike = zeros(1, templateSamples);
      templateSpike(1:templateSamples) = [2, 5, 15, 25, 35, 50, 65, 75, 85, 98, ...
                100, 90, 75, 60, 45, 30, 15, 5, 0, -5, ...
                -10, -13, -15, -17, -18, -19, -19, -19, -18, -17, ...
                -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, ...
                -6, -5, -4, -4, -3, -3, -2, -2, -1, -1];
      spikeSamples = spikeDurMS * app.lbj.SampleRateHz / 1000;
      peakV = app.vPerDiv * app.vDivs / 2 * 0.75;
      obj.fakeSpike = decimate(templateSpike, length(templateSpike) / spikeSamples) * peakV / 100;
      obj.fakeNoise = 0.2;
    end

    % outputAudio: output the audio signal
    function outputAudio(obj, app)
      inIndex = obj.lastProcessed + 1;                    % range to read from filtered trace
      inEndIndex = app.samplesRead;
      % output to audio output in chunks of audioBufferSize
      while inIndex < inEndIndex
        inNum = min(inEndIndex - inIndex, (obj.audioBufferSize - obj.audioOutIndex) / obj.outSampleRatio);
        ptr = obj.audioOutIndex + 1;
        for i = inIndex + 1:inIndex + inNum
          for rep = 1:obj.outSampleRatio
            obj.audioBuffer(ptr) = int16(app.filteredTrace(i) * obj.audioMultiplier);
            ptr = ptr + 1;
          end
        end
        if obj.audioOutIndex + inNum * obj.outSampleRatio == obj.audioBufferSize
          try                                         % full buffer, send to audio output
            obj.audioOutDevice(obj.audioBuffer);
%             underrun = obj.audioOutDevice(obj.audioBuffer);
%             if underrun ~= 0
%               fprintf('Audio underrun (%d samples)\n', underrun / obj.outSampleRatio);
%             end
          catch
            fprintf('error trying to output to audioOutDevice\n');
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
    end

    %% processSignals: function to process data from one trial
    function overRun = processSignals(obj, app)
      if app.testMode
        insertFakeSpikes(obj, app);
      end
      app.filteredTrace(obj.lastProcessed + 1:app.samplesRead) = ...
                            filter(app.filter, app.rawData(obj.lastProcessed + 1:app.samplesRead));
      outputAudio(obj, app);
      % Find spikes
      spikesEnabled = ~any((app.thresholdSlider.Limits - app.thresholdSlider.Value) == 0);            
      if spikesEnabled
        if app.thresholdV >= 0
          sIndices = find(app.filteredTrace(obj.lastProcessed + 1:app.samplesRead) > app.thresholdV);
        else
          sIndices = find(app.filteredTrace(obj.lastProcessed + 1:app.samplesRead) < app.thresholdV);
        end
        if isempty(sIndices)                                  % nothing above threshold
          app.inSpike = false;                                % clear the inSpike flag
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
             overRun = false;
              return;
            end
            sIndices = sIndices(i:end);                       % work with >thresholds past any spike tail
          end
          % Process newly detected spikes
          numSpikes = 1;                                      % we have at least one spike
          lastIndex = sIndices(1);                            % used to find gaps between spikes
          spikeIndices = lastIndex;                           % save the start of this spike
          addISI(obj, app, sIndices(1));                      % add this spike to the ISIs
          addSpikeTime(obj, app, sIndices(1));
          if length(sIndices) > 1                             % for all the remaining indices...
            for i = 2:length(sIndices)
              % we only allow one trigger per trigger cycle, but a bit more
              % so we can see 60 Hz noise triggering
              if sIndices(i) > lastIndex + 1 && (sIndices(i) - lastIndex) > app.spikePlots.triggerSamples - 25
                numSpikes = numSpikes + 1;                    % it's a new spike
                spikeIndices(numSpikes) = sIndices(i);        % record the index for this spike
               addISI(obj, app, sIndices(i));                % add this spike to the ISIs
                addSpikeTime(obj, app, sIndices(i));
              end
              lastIndex = sIndices(i);                        % used to find gaps between spikes
            end
          end
          if sIndices(end) == app.samplesRead - obj.lastProcessed % end of new data in middle of a spike?
            app.inSpike = true;
          end
          app.spikeIndices = [app.spikeIndices, spikeIndices + obj.lastProcessed]; % add new spikes to the list of spikes
        end
        obj.lastSpikeIndex = obj.lastSpikeIndex - (app.samplesRead - obj.lastProcessed);
      end
      % check whether we've run past the end of the continuous display
      overRun = app.samplesRead - app.contSamples;
      if overRun > 0
        app.rawData(1:overRun) = app.rawData(app.contSamples + 1:app.samplesRead);
        app.filteredTrace(1:overRun) = app.filteredTrace(app.contSamples + 1:app.samplesRead);
        app.spikeIndices = app.spikeIndices - app.contSamples;
        obj.nextFakeSpike0Sample = obj.nextFakeSpike0Sample - app.contSamples;
        app.samplesRead = overRun;
        obj.tracesRead = obj.tracesRead + 1;
      end
      obj.lastProcessed = app.samplesRead;
    end
    
    %% setVolume -- set volume based on the volume slider
    function setVolume(obj, app)
      obj.audioMultiplier = 10^get(app.volumeSlider, 'value');
    end
  end
end

