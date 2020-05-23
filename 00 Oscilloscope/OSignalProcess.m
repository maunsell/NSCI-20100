classdef OSignalProcess < handle
  % OSignalProcess
  %   Support for filtering voltage traces and finding spikes
  properties
    fH
    outSampleRatio
  end
  
  methods
    %% Object Initialization %%
    function obj = OSignalProcess(handles, app)
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
    function clearAll(~, app)
      app.inTrigger = false;
    end
    
    %% processSignals: function to process data from one trial
    function processSignals(obj, app, data, old, new)
      if app.testMode
        % add 60Hz noise and random noise
        dt = 1/app.sampleRateHz;                   % seconds per sample
        samples = old + 1:old + new;                 % seconds
        data.rawData(old + 1:old + new) = ones(new, 1) + cos(2.0 * pi * 60 * samples * dt)' * 0.5...
          + 0.25 * rand(new, 1) - 0.125;
      end
      data.filteredTrace(old + 1:old + new) = filter(app.filter, data.rawData(old + 1:old + new));
      % Find parts of the trace above the trigger level
      if app.thresholdV >= 0
        sIndices = find(data.filteredTrace(old + 1:old + new) > app.thresholdV);
      else
        sIndices = find(data.filteredTrace(old + 1:old + new) < app.thresholdV);
      end
      if isempty(sIndices)                                    % nothing above threshold
        app.inTrigger = false;                           	% clear the inTrigger flag
      else
        % If we entered this call partway through a spike, we need to get past any trailing parts of the spike.
        % That tail will start at index 1, so we can just eliminate from sIndices all indices that are equal to
        % their own index
        if app.inTrigger                                 	% we were part way through a spike before
          for i = 1:length(sIndices)
            if sIndices(i) ~= i
              app.inTrigger = false;               	% clear the inTrigger flag
              break;
            end
          end
          if app.inTrigger                            	% never got below trigger level, return
            return;
          end
          sIndices = sIndices(i:end);                     % remove the eliminated indices
        end
        numSpikes = 1;                                      % we have one above trigger sample (at least)
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
        if sIndices(end) == new                             % end of new data in middle of a triggered trace?
          app.inTrigger = true;
        end
        data.spikeIndices = [data.spikeIndices, spikeIndices + old]; % add new spikes to the list of spikes
      end
      app.lastSpikeIndex = app.lastSpikeIndex - new;        % save index for computing ISIs
    end
    
  end
  
end

