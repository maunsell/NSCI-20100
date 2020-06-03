classdef MetricsAmpDur < handle
  % MetricsAmpDur Handle saccade-duration data for EOG
  %   Accumulates and plots amplitude-duration relationships
  
  properties
    ampLabels
    lastN
    n
    reactTimesMS
  end
  
  methods
    
    function obj = MetricsAmpDur(app)      
      %% Object Initialization %%
      % Call superclass constructor before accessing object
      % You cannot conditionalize this statement
      %          obj = obj@handle(args{:});
      obj = obj@handle();
      
      %% Post Initialization %%
      obj.reactTimesMS = zeros(10000, app.numOffsets);                  % preallocate a generous buffer
      obj.n = zeros(1, app.numOffsets);
      obj.lastN = 0;
      obj.ampLabels = cell(1, app.numOffsets);
      for i = 1:app.numOffsets
        obj.ampLabels{i} = sprintf('%.0f', app.offsetsDeg(i));
      end
    end

    %% addAmpDur
    function addAmpDur(obj, app, sIndex, eIndex)
      if sIndex > 0 && eIndex > 0
        obj.n(app.offsetIndex) = obj.n(app.offsetIndex) + 1;
        obj.reactTimesMS(obj.n(app.offsetIndex), app.offsetIndex) = (eIndex - sIndex) / app.lbj.SampleRateHz * 1000.0;
      end
    end
    
    %% clearAll
    function clearAll(obj, app)
      obj.n = zeros(1, app.numOffsets);
      obj.lastN = 0;
      cla(app.ampDurAxes);
      axis(app.ampDurAxes, [0 1 0 1]);
    end
    
    %% plotAmpDur
    function plotAmpDur(obj, app)
      minN = min(obj.n);
      if minN < 2 || minN == obj.lastN
        return;
      end
      cla(app.ampDurAxes);
      boxplot(app.ampDurAxes, obj.reactTimesMS(1:minN, :), 'labels', num2str(app.offsetsDeg(:)), ...
        'notch', 'on', 'whisker', 0, 'positions', app.offsetsDeg, 'symbol', '');
      title(app.ampDurAxes, sprintf('Duration v. Amplitude (n\x2265%d)', app.blocksDone), 'FontSize', 12, 'FontWeight', 'Bold');
      xlabel(app.ampDurAxes, 'Saccade Amplitude (deg)','FontSize',14);
      ylabel(app.ampDurAxes, 'Saccade Duration (ms)','FontSize',14);
      a = axis(app.ampDurAxes);
      medians = median(obj.reactTimesMS(1:minN, :));
      quartiles = prctile(obj.reactTimesMS(1:minN, :), [25 75]);
      [maxQ, indexMax] = max(max(quartiles));
      axis(app.ampDurAxes, [a(1), a(2), 0, medians(indexMax) + 2.0 * (maxQ - medians(indexMax))]);
      hold(app.ampDurAxes, 'off');
      obj.lastN = minN;
    end
  end
end

