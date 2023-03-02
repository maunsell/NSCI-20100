classdef MetricsPosVelPlots < handle
  % saccades
  %   Support for processing eye traces and detecting saccades
  
  properties
    posAvgAxes
    posAxes
    velAvgAxes
    velAxes
  end
  
  methods
    function obj = MetricsPosVelPlots(app)
      % Object Initialization
      obj = obj@handle();                                            % object initialization
      
      % Post Initialization
      obj.posAvgAxes = app.avgPosAxes;
      obj.posAxes = app.posAxes;
      obj.velAvgAxes = app.avgVelAxes;
      obj.velAxes = app.velAxes;
    end

    function calibratedLabels(~, theAxes, conversion, unit)
      yLim = max(abs(ylim(theAxes)));
      maxCalValue = ceil((yLim * conversion) / unit) * unit;  % rounded to nearest unit
      increment = unit;
      while maxCalValue / increment > 5
        increment = increment * 2;
      end
      yTicks = (-maxCalValue:increment:maxCalValue) / conversion;
      yLabels = cell(length(yTicks), 1);
      for i = 1:length(yTicks)
        yLabels{i} = num2str(yTicks(i) * conversion, '%.0f');
      end
      set(theAxes, 'YTick', yTicks);
      set(theAxes, 'YTickLabel', yLabels);
    end
    
    function plotPosVel(obj, app, startIndex, endIndex, mustPlot)
      %doPlot Update all plots for EOG
      mustPlot = mustPlot || (mod(sum(app.numSummed), app.numOffsets) == 0);
      posPlots(obj, app, startIndex, endIndex, mustPlot);
      velPlots(obj, app, startIndex, endIndex, mustPlot);
    end
    
    %% posPlots: do the trial and average position plots
    function posPlots(obj, app, startIndex, endIndex, mustPlot)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;                   	% time interval of samples
      trialTimes = (0:1:size(app.posTrace, 1) - 1) * timestepMS;	% make array of trial time points
      saccadeTimes = (-(size(app.posAvg, 1) / 2):1:(size(app.posAvg,1) / 2) - 1) * timestepMS;
      colors = get(obj.posAxes, 'ColorOrder');
      % current trial position trace
      cla(obj.posAxes, 'reset');                                  % need 'reset' to clear axis scaling
      plot(obj.posAxes, trialTimes, app.posTrace, 'color', colors(app.absStepIndex,:));
      saccades = app.saccades;
      if saccades.degPerV > 0                                     % plot saccade threshold
        hold(obj.posAxes, 'on');
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Position')
          thresholdV = saccades.thresholdDeg / saccades.degPerV * app.stepSign;
        plot(obj.posAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], ':r');
%           ':', 'color', colors(app.absStepIndex,:));
        end
        hold(obj.posAxes, 'off');
        ylabel(obj.posAxes, 'Avg Eye Position (deg)','FontSize', 14);
      else
        ylabel(obj.posAxes,'Analog Input (V)','FontSize', 14); 
      end
      title(obj.posAxes, 'Most recent position trace', 'FontSize', 12,'FontWeight','Bold')
      % average position traces every complete block
      if mustPlot
        cla(obj.posAvgAxes, 'reset');
        if sum(app.numSummed) > 0
          plot(obj.posAvgAxes, saccadeTimes, app.posAvg(:, 1:app.numOffsets / 2), '-');
          hold(obj.posAvgAxes, 'on');
          obj.posAvgAxes.ColorOrderIndex = 1;
          plot(obj.posAvgAxes, saccadeTimes, app.posAvg(:, app.numOffsets / 2 + 1:app.numOffsets), '-');
          hold(obj.posAvgAxes, 'off');
          title(obj.posAvgAxes, sprintf('Average position traces (n\x2265%d)', app.blocksDone), ...
            'FontSize',12,'FontWeight','Bold')
          % set both plots to the same y scale
          yLim = max(abs(ylim(obj.posAvgAxes)));
          axis(obj.posAvgAxes, [-inf inf -yLim yLim]);
          hold(obj.posAvgAxes, 'on');
          plot(obj.posAvgAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':'); % saccade start, t = 0
          for i = 1:length(app.medians)          % draw saccade median for each average trace
            yEnd = yLim - floor((i - 1) / (app.numOffsets / 2)) * 2 * yLim;
            plot(obj.posAvgAxes, [app.medians(i), app.medians(i)], ...
              [0, yEnd], ':', 'color', colors(mod(i - 1, app.numOffsets / 2) + 1, :));
          end
          hold(obj.posAvgAxes, 'off');
          % if eye position has been calibrated, change the y scaling on the average to degrees
          % rather than volts
          if saccades.degPerV > 0
            yTicks = [fliplr(-app.offsetsDeg(1:app.numOffsets/2)), 0, ...
              app.offsetsDeg(1:app.numOffsets/2)] / saccades.degPerV;
            yLabels = cell(length(yTicks), 1);
            for i = 1:length(yTicks)
              yLabels{i} = num2str(yTicks(i) * saccades.degPerV, '%.0f');
            end
            set(obj.posAvgAxes, 'YTick', yTicks);
            set(obj.posAvgAxes, 'YTickLabel', yLabels);
            ylabel(obj.posAvgAxes,'Avg Eye Position (deg)','FontSize',14);
          end
        end
      end
      if sum(app.numSummed) > app.numOffsets
        yLim = max(abs(ylim(obj.posAvgAxes)));
        axis(obj.posAxes, [-inf inf -yLim yLim]);         % scale pos plot to avgPos plot y-axis
      end
      yLim = ylim(obj.posAxes);
      % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
      hold(obj.posAxes, 'on');
      plot(obj.posAxes, [app.stimTimeS, app.stimTimeS] * 1000.0, yLim, 'k-.');
      if (startIndex > 0)
        plot(obj.posAxes, [startIndex, startIndex] * timestepMS, yLim, 'color', ...
          colors(app.absStepIndex,:), 'linestyle', ':');
        if (endIndex > 0)
          plot(obj.posAxes, [endIndex, endIndex] * timestepMS, yLim, 'color', ...
            colors(app.absStepIndex,:), 'linestyle', ':');
        end
      end
      hold(obj.posAxes, 'off');
    end
    
    %% velPlots: do the trial and average velocity plots
    function velPlots(obj, app, startIndex, endIndex, mustPlot)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;                       	% time interval of samples
      trialTimes = (0:1:size(app.posTrace, 1) - 1) * timestepMS;     % make array of trial time points
      saccadeTimes = (-(size(app.posAvg, 1) / 2):1:(size(app.posAvg,1) / 2) - 1) * timestepMS;
      colors = get(obj.velAxes, 'ColorOrder');
      % plot the trial velocity trace
      cla(obj.velAxes, 'reset');
      plot(obj.velAxes, trialTimes, app.velTrace, 'color', colors(app.absStepIndex,:));
      yLim = max(abs(ylim(obj.velAxes)));
      axis(obj.velAxes, [-inf, inf, -yLim, yLim]);
      title(obj.velAxes, 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold');
      ylabel(obj.velAxes,'Analog Input (dV/dt)','FontSize',14);
      xlabel(obj.velAxes,'Time (ms)','FontSize',14);
      hold(app.velAxes, 'on');                                    % mark fixOff and targetOn
      saccades = app.saccades;
      % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
      if saccades.degPerSPerV > 0
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Speed')
          thresholdV = saccades.thresholdDPS / saccades.degPerSPerV * app.stepSign;
          plot(app.velAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], 'r:');
        end
        calibratedLabels(obj, app.velAxes, app.saccades.degPerSPerV, 100)
        ylabel(app.velAxes,'Eye Speed (deg/s)','FontSize',14);
      else
        ylabel(app.velAxes,'Analog Input (dV/dt)','FontSize',14);
      end
      % plot the average velocity traces every time a set of step sizes is completed
      if mustPlot
        cla(obj.velAvgAxes, 'reset');
        if sum(app.numSummed) > 0                  % make sure there is at least one set of steps
          plot(obj.velAvgAxes, saccadeTimes, app.velAvg(:, 1:app.numOffsets / 2), '-');
          hold(obj.velAvgAxes, 'on');
          obj.velAvgAxes.ColorOrderIndex = 1;
          plot(obj.velAvgAxes, saccadeTimes, app.velAvg(:, app.numOffsets / 2 + 1:app.numOffsets), '-');
          hold(obj.velAvgAxes, 'off');
          title(obj.velAvgAxes, sprintf('Average velocity traces (n\x2265%d)', app.blocksDone), ...
            'fontSize', 12, 'fontWeight','Bold')
          ylabel(obj.velAvgAxes,'Analog Input (dV/dt)', 'FontSize', 14);
          xlabel(obj.velAvgAxes,'Time (ms)','FontSize', 14);
          % put both plots on the same y scale
          yLim = max([max(abs(ylim(obj.velAxes))), max(abs(ylim(obj.velAvgAxes)))]);
          axis(obj.velAxes, [-inf inf -yLim yLim]);
          axis(obj.velAvgAxes, [-inf inf -yLim yLim]);
          % averages are always aligned on onset, so draw a vertical line at that point
          hold(obj.velAvgAxes, 'on');
          plot(obj.velAvgAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
          hold(obj.velAvgAxes, 'off');
        end
      end
      % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
      if saccades.degPerV > 0
        maxSpeedDPS = ceil((yLim * saccades.degPerSPerV) / 100.0) * 100;
        increment = 100;
        while maxSpeedDPS / increment > 5
          increment = increment * 2;
        end
        yTicks = (-maxSpeedDPS:increment:maxSpeedDPS) / saccades.degPerSPerV;
        yLabels = cell(length(yTicks), 1);
        for i = 1:length(yTicks)
          yLabels{i} = num2str(yTicks(i) * saccades.degPerSPerV, '%.0f');
        end
        set(obj.velAxes, 'YTick', yTicks);
        set(obj.velAxes, 'YTickLabel', yLabels);
        ylabel(obj.velAxes,'Avg Eye Speed (deg/s)','FontSize',14);
        if mustPlot
          set(obj.velAvgAxes, 'YTick', yTicks);
          set(obj.velAvgAxes, 'YTickLabel', yLabels);
          ylabel(obj.velAvgAxes, 'Avg Eye Speed (deg/s)', 'FontSize', 14);
        end
      end
      yLim = ylim(obj.velAxes);
      % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
      hold(obj.velAxes, 'on');
      plot(obj.velAxes, [app.stimTimeS * 1000.0, app.stimTimeS * 1000.0], yLim, 'k-.');
      if (startIndex > 0)
        plot(obj.velAxes, [startIndex, startIndex] * timestepMS, yLim, 'color', ...
          colors(app.absStepIndex,:), 'linestyle', ':');
        if (endIndex > 0)
          plot(obj.velAxes, [endIndex, endIndex] * timestepMS, yLim, 'color', ...
            colors(app.absStepIndex,:), 'linestyle', ':');
        end
      end
      hold(obj.velAxes, 'off');
    end
  end
end
