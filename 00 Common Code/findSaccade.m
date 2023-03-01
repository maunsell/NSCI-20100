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
  switch app.ThresholdType.SelectedObject.Value
    case app.kPosition
      thresholdV = mean(app.posTrace(1:startIndex)) + obj.thresholdDeg / obj.degPerV;
      trace = app.posTrace;
    case app.kSpeed
      thresholdV = mean(app.velTrace(1:startIndex)) + obj.thresholdDPS / obj.degPerSPerV;
      trace = app.velTrace;
  end
  sIndex = startIndex;
  seq = 0;
  seqLength = 5;                                        % number seq. samples needed above threshold
  limit = length(trace);
  while (seq < seqLength && sIndex < limit)	            % find the first sequence of seqLength > than threshold
    if trace(sIndex) * app.stepSign < thresholdV
      seq = 0;
    else
      seq = seq + 1;
    end
    sIndex = sIndex + 1;
  end
  % if we found a saccade start, look for the saccade end, consisting of seqLength samples below the peak
  if sIndex >= limit
    sIndex = 0;
    eIndex = 0;
  else
    seq = 0;
    maxPos = trace(sIndex);
    maxIndex = sIndex;
    eIndex = sIndex;
    while seq < seqLength && eIndex < (limit - 1)
      if trace(eIndex + 1) * app.stepSign < maxPos * app.stepSign
        seq = seq + 1;
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

% function sIndex = findSaccadeStart(obj, app, startIndex)
%   switch app.ThresholdType.SelectedObject.Value
%     case app.kPosition
%       thresholdV = mean(app.posTrace(1:startIndex)) + obj.thresholdDeg / obj.degPerV;
%       trace = app.posTrace;
%     case app.kSpeed
%       thresholdV = mean(app.velTrace(1:startIndex)) + obj.thresholdDPS / obj.degPerSPerV;
%       trace = app.velTrace;
%   end
%   sIndex = startIndex;
%   seq = 0;
%   seqLength = 5;                                        % number seq. samples needed above threshold
%   limit = length(trace);
%   while (seq < seqLength && sIndex < limit)	            % find the first sequence of seqLength > than threshold
%     if trace(sIndex) * app.stepSign < thresholdV
%       seq = 0;
%     else
%       seq = seq + 1;
%     end
%     sIndex = sIndex + 1;
%   end
%   if sIndex >= limit
%     sIndex = [];
%   end
% end
% 
