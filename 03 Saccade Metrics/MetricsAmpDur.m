classdef MetricsAmpDur < handle
  %MetricsAmpDur Handle saccade-duration data for EOG
  %   Accumulates the data and handles the plot
  
  properties
    ampLabels
%     offsetsDeg
%     numOffsets
    fHandle
    lastN
    n
    reactTimesMS
%     sampleRateHz
  end
  
  methods
    
    function obj = MetricsAmpDur(app)
      
      %% Pre Initialization %%
%       % Any code not using output argument (obj)
%       if nargin == 0
%         offsetList = 10;
%       end
      
      %% Object Initialization %%
      % Call superclass constructor before accessing object
      % You cannot conditionalize this statement
      %          obj = obj@handle(args{:});
      obj = obj@handle();
      
      %% Post Initialization %%
      obj.fHandle = app.ampDurAxes;
%       obj.sampleRateHz = sampleRate;
%       obj.offsetsDeg = offsetList;
%       obj.numOffsets = length(app.offsetsDeg);
      obj.reactTimesMS = zeros(10000, app.numOffsets);                  % preallocate a generous buffer
      obj.n = zeros(1, app.numOffsets);
      obj.lastN = 0;
      obj.ampLabels = cell(1, app.numOffsets);
      for i = 1:app.numOffsets
        obj.ampLabels{i} = sprintf('%.0f', app.offsetsDeg(i));
      end
    end

    %% addAmpDur
    function addAmpDur(obj, app, offsetIndex, sIndex, eIndex)
      if sIndex > 0 && eIndex > 0
        obj.n(offsetIndex) = obj.n(offsetIndex) + 1;
        obj.reactTimesMS(obj.n(offsetIndex), offsetIndex) = (eIndex - sIndex) / app.lbj.SampleRateHz * 1000.0;
      end
    end
    
    %% clearAll
    function clearAll(obj, app)
      obj.n = zeros(1, app.numOffsets);
      obj.lastN = 0;
      cla(obj.fHandle);
      axis(obj.fHandle, [0 1 0 1]);
%       text(0.05, 0.1, '5', 'parent', obj.fHandle, 'FontSize', 24, 'FontWeight', 'Bold');
    end
    
    %% plotAmpDur
    function plotAmpDur(obj, app)
      minN = min(obj.n);
      if minN < 2 || minN == obj.lastN
        return;
      end
      cla(obj.fHandle);
      boxplot(obj.fHandle, obj.reactTimesMS(1:minN, :), 'labels', num2str(app.offsetsDeg(:)), ...
        'notch', 'on', 'whisker', 0, 'positions', app.offsetsDeg, 'symbol', '');
      title(obj.fHandle, sprintf('Duration v. Amplitude (n\x2265%d)', app.blocksDone), 'FontSize', 12, 'FontWeight', 'Bold');
      xlabel(obj.fHandle, 'Saccade Amplitude (deg)','FontSize',14);
      ylabel(obj.fHandle, 'Saccade Duration (ms)','FontSize',14);
      a = axis(obj.fHandle);
      medians = median(obj.reactTimesMS(1:minN, :));
      quartiles = prctile(obj.reactTimesMS(1:minN, :), [25 75]);
      [maxQ, indexMax] = max(max(quartiles));
%       [minQ, indexMin] = min(min(quartiles));
%       axis(obj.fHandle, [a(1), a(2), (medians(indexMin) - 2.0 * (medians(indexMin) - minQ))...
      axis(obj.fHandle, [a(1), a(2), 0, medians(indexMax) + 2.0 * (maxQ - medians(indexMax))]);
%       a = axis(obj.fHandle);
%       text(a(1) + 0.05 * (a(2) - a(1)), 0.1 * (a(4) - a(3)) + a(3), '5', 'parent', obj.fHandle, 'FontSize', 24,...
%         'FontWeight', 'Bold');
      hold(obj.fHandle, 'off');
      obj.lastN = minN;
    end
  end
end

