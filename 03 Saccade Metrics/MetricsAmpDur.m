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
    function refresh = plotAmpDur(obj, app)
      minN = min(obj.n);
      refresh = minN >= 2 && minN > obj.lastN;
      if ~refresh
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

    %% writeAmpDurData
    % return a cell array suitable for creating an Excel spreadsheet reporting the ampDur statistics
    function writeAmpDurData(obj, app, timeString)
      minN = min(obj.n);
      if minN < 3
        return;
      end
      if nargin < 3
        timeString = datestr(now, 'mmm-dd-HHMMSS');
      end
      c = cell(app.numOffsets + 1, 6);
      [c{1, :}] = deal('Amp. (deg)', 'Samples', 'Dur. Median (ms)', 'Dur. Median 95% CI (ms)', ...
        '25th Percentile Dur.', '75th Percentile Dur.');
      for offset = 1:app.numOffsets
        sortRT = sort(obj.reactTimesMS(1:minN, offset));
        percentiles = prctile(sortRT, [50, 25, 75]);
        stat = 1.96 * sqrt(minN) * 0.5;
        c{offset + 1, 1} = app.offsetsDeg(offset);
        c{offset + 1, 2} =  obj.n(offset);
        c{offset + 1, 3} =  percentiles(1);
        c{offset + 1, 4} =  sprintf('%.1f-%.1f', sortRT(ceil(0.5 * minN + [-stat, stat])));
        c{offset + 1, 5} =  percentiles(2);
        c{offset + 1, 6} =  percentiles(3);
      end
      filePath = fullfile('~/Desktop/MetricsData/AmpDur', ['MT-', timeString, '.xlsx']);
      writecell(c, filePath, 'writeMode', 'replacefile', 'autoFitWidth', 1);
      backupFile(filePath, '~/Desktop', '~/Documents/Respository');     % save backup in repository directory
    end
  end
end

