classdef MetricsAmpDur < handle
  % MetricsAmpDur Handle saccade-duration data for EOG
  %   Accumulates and plots amplitude-duration relationships
  
  properties
    accFit;
    ampLabels
    lastN
    n
    reactTimesMS
    speedFit;
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
      obj.accFit = -1;
      obj.speedFit = -1;
      obj.ampLabels = cell(1, app.numOffsets);
      for i = 1:app.numOffsets
        obj.ampLabels{i} = sprintf('%.0f', app.offsetsDeg(i));
      end
    end

    %% addAmpDur
    function blockDone = addAmpDur(obj, app, sIndex, eIndex)
      if sIndex > 0 && eIndex > 0
        obj.n(app.offsetIndex) = obj.n(app.offsetIndex) + 1;
        obj.reactTimesMS(obj.n(app.offsetIndex), app.offsetIndex) = (eIndex - sIndex) / app.lbj.SampleRateHz * 1000.0;
      end
      minN = min(obj.n);
      blockDone = minN > obj.lastN;
      if blockDone
        obj.lastN = minN;
      end
    end
    
    %% clearAll
    function clearAll(obj, app)
      obj.n = zeros(1, app.numOffsets);
      obj.lastN = 0;
      obj.accFit = -1;
      obj.speedFit = -1;
      cla(app.ampDurAxes);
      axis(app.ampDurAxes, [0 1 0 1]);
    end
    
    %% plotAmpDur
    function plotAmpDur(obj, app)
      if obj.lastN <= 2             % we need enough data for the boxplot
        return;
      end
      app.medians = median(obj.reactTimesMS(1:obj.lastN, :));
      quartiles = prctile(obj.reactTimesMS(1:obj.lastN, :), [25 75]);
      [maxQ, indexMax] = max(max(quartiles));      cla(app.ampDurAxes);
      boxplot(app.ampDurAxes, obj.reactTimesMS(1:obj.lastN, :), 'labels', num2str(app.offsetsDeg(:)), ...
            'notch', 'on', 'whisker', 0, 'positions', app.offsetsDeg, 'symbol', '');
      title(app.ampDurAxes, sprintf('Duration v. Amplitude (n\x2265%d)', app.blocksDone), 'FontSize', 12, ...
            'FontWeight', 'Bold');
      xlabel(app.ampDurAxes, 'Saccade Amplitude (deg)', 'FontSize', 14);
      ylabel(app.ampDurAxes, 'Saccade Duration (ms)', 'FontSize', 14);
      axis(app.ampDurAxes, [xlim(app.ampDurAxes), 0, app.medians(indexMax) + 2.0 * (maxQ - app.medians(indexMax))]);
      hold(app.ampDurAxes, 'off');
      plotFits(obj, app);
    end 

    %% plotFits -- add fit functions to the amplitude/duration plot
    function plotFits(obj, app)
      if (obj.accFit == -1) || (obj.speedFit == -1)
        return;
      end
      hold(app.ampDurAxes, 'on');
      posX = 0:max(app.offsetsDeg);
      negX = min(app.offsetsDeg):0;
      posY = polyval([1000.0 / obj.speedFit, 0], posX);
      negY = -polyval([1000.0 / obj.speedFit, 0], negX);
      plot(app.ampDurAxes, [negX, posX], [negY, posY], ':r');      
      posY = sqrt(polyval([4.0 / (obj.accFit / 1000000), 0], posX));
      negY = sqrt(-polyval([4.0 / (obj.accFit / 1000000), 0], negX));
      plot(app.ampDurAxes, [negX, posX], [negY, posY], ':b');
      legend(app.ampDurAxes, {'const. speed', 'const. accel.'}, 'location', 'north', 'box', 'off');
      hold(app.ampDurAxes, 'off');
    end

    %% writeAmpDurData
    % return a cell array suitable for creating an Excel spreadsheet reporting the ampDur statistics
    function writeAmpDurData(obj, app, timeString)
      if min(obj.n) < 3                 % need at least 3 reps to have savable data
        % fprintf('writeAmpDurData -- not writing, too few\n');
        return;
      end
      if nargin < 3
        timeString = string(datetime('now', 'Format', 'MMM-dd-HHmmss'));
      end
      c = cell(app.numOffsets + 1, 7);
      [c{1, :}] = deal('Samples', 'Step (deg)', 'Amp. (deg)', 'Dur. Median (ms)', 'Dur. Median 95% CI (ms)', ...
        '25th Percentile Dur.', '75th Percentile Dur.');
      for offset = 1:app.numOffsets
        sortRT = sort(obj.reactTimesMS(1:obj.n(offset), offset));
        percentiles = prctile(sortRT, [50, 25, 75]);
        stat = 1.96 * sqrt(obj.n(offset)) * 0.5;
        indices = ceil(0.5 * obj.n(offset) + [-stat, stat]);
        indices(indices < 1) = 1;
        indices(indices > length(sortRT)) = length(sortRT);
        c{offset + 1, 1} = app.blocksDone;
        c{offset + 1, 2} = app.offsetsDeg(offset);
        c{offset + 1, 3} = abs(app.offsetsDeg(offset));
        c{offset + 1, 4} = percentiles(1);
        c{offset + 1, 5} = sprintf('%.1f-%.1f', sortRT(indices));
        c{offset + 1, 6} = percentiles(2);
        c{offset + 1, 7} = percentiles(3);
      end
      fPath = [app.folderPath, 'AmpDur'];
      if ~isfolder(fPath)
        mkdir(fPath);
      end
      filePath = fullfile(fPath, ['MT-', timeString, '.xlsx']);
      % fprintf('writeAmpDurData -- writing, %s\n', filePath);
      writecell(c, filePath, 'writeMode', 'replacefile', 'autoFitWidth', 1);
      backupFile(filePath, '~/Desktop', '~/Documents/Respository');     % save backup in repository directory
    end
  end
end

