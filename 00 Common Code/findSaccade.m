function [sIndex, eIndex] = findSaccade(obj, app, startIndex)
  if app.calTrialsDone < 4                                    % still getting a calibration
    if (app.stepSign == 1)
      DPV = abs(app.stepSizeDeg / (max(app.posTrace(:)) - mean(app.posTrace(1:startIndex))));
    else
      DPV = abs(app.stepSizeDeg / (mean(app.posTrace(1:startIndex) - min(app.posTrace(:)))));
    end
    obj.degPerV = (obj.degPerV * app.calTrialsDone + DPV) / (app.calTrialsDone + 1);
    obj.degPerSPerV = obj.degPerV * app.lbj.SampleRateHz;
    app.calTrialsDone = app.calTrialsDone + 1;
    sIndex = 0; eIndex = 0;
    return;                                                   % no saccades until we have a calibration
  end
  % set up to use the selected threshold type (position or speed)
  if strcmp(app.ThresholdType.SelectedObject.Text, 'Position')
      thresholdV = mean(app.posTrace(1:startIndex)) + obj.thresholdDeg / obj.degPerV;
      trace = app.posTrace;
  elseif strcmp(app.ThresholdType.SelectedObject.Text, 'Speed')
      thresholdV = mean(app.velTrace(1:startIndex)) + obj.thresholdDPS / obj.degPerSPerV;
      trace = app.velTrace;
  else
    fprintf('findSaccade: unrecognized threshold type ''%s''\n', app.ThresholdType.SelectedObject.Text);
    sIndex = 0; eIndex = 0;
    return;
  end
  % search for a sequence of point above the threshold
  sIndex = startIndex;
  seq = 0;
  seqLength = 5;                                        % number seq. samples needed above threshold
  limit = length(trace);
  while (seq < seqLength && sIndex < limit)	            % find the first sequence of seqLength > than threshold
    if trace(sIndex) * app.stepSign < thresholdV
      seq = 0;                                          % below threshold, no sequence
    else
      seq = seq + 1;                                    % above threshold, add to sequence count
    end
    sIndex = sIndex + 1;                                % move to next value
  end
  % no saccade found, return zeros
  if sIndex >= limit
    sIndex = 0;
    eIndex = 0;
  % saccade start found, look for the saccade end, consisting of seqLength samples below the peak
  else
    seq = 0;
    maxPos = trace(sIndex);
    maxIndex = sIndex;
    eIndex = sIndex;
    while seq < seqLength && eIndex < (limit - 1)
      % below peak, add to sequence
      if trace(eIndex + 1) * app.stepSign < maxPos * app.stepSign
        seq = seq + 1;
      % above previous peak, clear sequence
      else
        seq = 0;
        maxPos = trace(eIndex + 1);
        maxIndex = eIndex + 1;
      end
      eIndex = eIndex + 1;
    end
    if eIndex >= limit - 1
      eIndex = 0;
    else
      eIndex =  maxIndex;
    end
    % if we are using a speed threshold, we've only just reach the peak
    % speed. We continue on to find when the speed change drops to zero
    if eIndex > sIndex && strcmp(app.ThresholdType.SelectedObject.Text, 'Speed')
      while eIndex < (limit - 1) && app.velTrace(eIndex + 1) * app.stepSign > 0
        eIndex = eIndex + 1;
      end
    end
    % if we have found the start and end of a saccade, walk the start from the position threshold to the
    % point where velocity turned positive at the start of the saccade
    if eIndex > sIndex
      while sIndex > startIndex && app.velTrace(sIndex - 1) * app.stepSign > 0
        sIndex = sIndex - 1;
      end
    end
    if eIndex - sIndex < 0.005 * app.lbj.SampleRateHz      % no saccades less than 5 ms
      sIndex = 0;
      eIndex = 0;
    end
  end
  % add some jitter to reduce alignment on noise
  if sIndex > 0 && eIndex > 0
    offset = floor(app.lbj.SampleRateHz * 0.01666 * rand(1));
    sIndex = sIndex - offset;
    eIndex = eIndex - offset;
  end
end