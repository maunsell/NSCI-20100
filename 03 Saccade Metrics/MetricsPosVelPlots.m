classdef MetricsPosVelPlots < handle
  % saccades
  %   Support for processing eye traces and detecting saccades
  
  properties
  end
  
  methods
    function obj = MetricsPosVelPlots(~)
      % Object Initialization
      obj = obj@handle();                                            % object initialization
      
      % Post Initialization
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
      %plotPosVel Update all plots for EOG
      mustPlot = mustPlot || (mod(sum(app.numSummed), app.numOffsets) == 0);
      posPlots(obj, app, startIndex, endIndex, mustPlot);
      velPlots(obj, app, startIndex, endIndex, mustPlot);
    end
    
    %% posPlots: do the trial and average position plots
    function posPlots(~, app, startIndex, endIndex, mustPlot)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;                 % time interval of samples
      trialTimes = (0:1:size(app.posTrace, 1) - 1) * timestepMS;	% make array of trial time points
      colors = get(app.posAxes, 'ColorOrder');
      % current trial position trace
      plot(app.posAxes, trialTimes, app.posTrace, 'color', colors(app.absStepIndex,:));
      saccades = app.saccades;
      if saccades.degPerV > 0                                     % plot saccade threshold
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Position')
          thresholdV = saccades.thresholdDeg / saccades.degPerV * app.stepSign;
          hold(app.posAxes, 'on');
          plot(app.posAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], ':r');
          hold(app.posAxes, 'off');
        end        
        ylabel(app.posAxes, 'Eye Position (deg)', 'FontSize', 14);
      else
        ylabel(app.posAxes, 'Analog Input (V)', 'FontSize', 14); 
      end
      title(app.posAxes, 'Most recent position trace', 'FontSize', 12,'FontWeight','Bold')
      
      % average position traces every complete block
      if mustPlot
        if sum(app.numSummed) == 0
          cla(app.avgPosAxes, 'reset');       % must plot with no steps -- just clear
        else
          saccadeTimes = (-(size(app.posAvg, 1) / 2):1:(size(app.posAvg, 1) / 2) - 1) * timestepMS;
          plot(app.avgPosAxes, saccadeTimes, app.posAvg(:, 1:app.numOffsets / 2), '-');
          hold(app.avgPosAxes, 'on');
          app.avgPosAxes.ColorOrderIndex = 1;
          plot(app.avgPosAxes, saccadeTimes, app.posAvg(:, app.numOffsets / 2 + 1:app.numOffsets), '-');
          hold(app.avgPosAxes, 'off');
          title(app.avgPosAxes, sprintf('Average position traces (n\x2265%d)', app.blocksDone), ...
            'FontSize',12,'FontWeight','Bold')
          % set both plots to the y scaling range, using the maximum y value from the average plot
          yLim = max(abs(ylim(app.avgPosAxes)));
          set(app.avgPosAxes, ['X' 'Lim'], [saccadeTimes(1), saccadeTimes(end) + 1]);
          set(app.avgPosAxes, ['Y' 'Lim'], [-yLim, yLim]);
          hold(app.avgPosAxes, 'on');
          plot(app.avgPosAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':'); % saccade start, t = 0
          for i = 1:length(app.medians)          % draw saccade median for each average trace
            if app.numSummed(i) > 0
              yEnd = yLim - floor((i - 1) / (app.numOffsets / 2)) * 2 * yLim;
              plot(app.avgPosAxes, [app.medians(i), app.medians(i)], ...
                [0, yEnd], ':', 'color', colors(mod(i - 1, app.numOffsets / 2) + 1, :));
            end
          end
          hold(app.avgPosAxes, 'off');
          % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
          if saccades.degPerV > 0
            yTicks = [fliplr(-app.offsetsDeg(1:app.numOffsets/2)), 0, ...
              app.offsetsDeg(1:app.numOffsets/2)] / saccades.degPerV;
            yLabels = cell(length(yTicks), 1);
            for i = 1:length(yTicks)
              yLabels{i} = num2str(yTicks(i) * saccades.degPerV, '%.0f');
            end
            set(app.avgPosAxes, 'YTick', yTicks);
            set(app.avgPosAxes, 'YTickLabel', yLabels);
            ylabel(app.avgPosAxes, 'Avg Eye Position (deg)', 'FontSize', 14);
          end
        end
      end
      if sum(app.numSummed) > app.numOffsets
        yLim = max(abs(ylim(app.avgPosAxes)));
        set(app.posAxes, ['Y' 'Lim'], [-yLim, yLim]);
      end
      yLim = ylim(app.posAxes);
      % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
      hold(app.posAxes, 'on');
      plot(app.posAxes, [app.stimTimeS, app.stimTimeS] * 1000.0, yLim, 'k-.');
      plot(app.posAxes, [0, trialTimes(end)], [0, 0], 'linewidth', 0.025, 'linestyle', '-.', 'color', 'k');
      if (startIndex > 0)
        plot(app.posAxes, [startIndex, startIndex] * timestepMS, yLim, 'color', ...
          colors(app.absStepIndex,:), 'linestyle', ':');
        if (endIndex > 0)
          plot(app.posAxes, [endIndex, endIndex] * timestepMS, yLim, 'color', ...
            colors(app.absStepIndex,:), 'linestyle', ':');
        end
      end
      hold(app.posAxes, 'off');
    end
    
    %% velPlots: do the trial and average velocity plots
    function velPlots(obj, app, startIndex, endIndex, mustPlot)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;                       	% time interval of samples
      trialTimes = (0:1:size(app.posTrace, 1) - 1) * timestepMS;     % make array of trial time points
      saccadeTimes = (-(size(app.posAvg, 1) / 2):1:(size(app.posAvg,1) / 2) - 1) * timestepMS;
      colors = get(app.velAxes, 'ColorOrder');
      % plot the trial velocity trace
      plot(app.velAxes, trialTimes, app.velTrace, 'color', colors(app.absStepIndex,:));
      yLim = max(abs(ylim(app.velAxes)));
      set(app.velAxes, ['Y' 'Lim'], [-yLim, yLim]);
      title(app.velAxes, 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold');
      ylabel(app.velAxes,'Analog Input (dV/dt)','FontSize',14);
      xlabel(app.velAxes,'Time (ms)','FontSize',14);
      saccades = app.saccades;
      % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
      if saccades.degPerSPerV > 0
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Speed')
          thresholdV = saccades.thresholdDPS / saccades.degPerSPerV * app.stepSign;
          hold(app.avgVelAxes, 'on');
          plot(app.velAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], 'r:');
          hold(app.avgVelAxes, 'off');
        end
        calibratedLabels(obj, app.velAxes, app.saccades.degPerSPerV, 100)
        ylabel(app.velAxes, 'Eye Speed (deg/s)', 'FontSize', 14);
      else
        ylabel(app.velAxes,'Analog Input (dV/dt)','FontSize',14);
      end
      % plot the average velocity traces every time a set of step sizes is completed
      if mustPlot
        if sum(app.numSummed) == 0                    % mustPlot with no steps -- just clear
          cla(app.avgVelAxes, 'reset');
        else
          plot(app.avgVelAxes, saccadeTimes, app.velAvg(:, 1:app.numOffsets / 2), '-');
          hold(app.avgVelAxes, 'on');
          app.avgVelAxes.ColorOrderIndex = 1;
          plot(app.avgVelAxes, saccadeTimes, app.velAvg(:, app.numOffsets / 2 + 1:app.numOffsets), '-');
          hold(app.avgVelAxes, 'off');
          title(app.avgVelAxes, sprintf('Average velocity traces (n\x2265%d)', app.blocksDone), ...
            'fontSize', 12, 'fontWeight','Bold')
          ylabel(app.avgVelAxes,'Analog Input (dV/dt)', 'FontSize', 14);
          xlabel(app.avgVelAxes,'Time (ms)','FontSize', 14);
          % put both plots on the same y scale
          yLim = max([max(abs(ylim(app.velAxes))), max(abs(ylim(app.avgVelAxes)))]);
          set(app.velAxes, ['Y' 'Lim'], [-yLim, yLim]);
          set(app.avgVelAxes, ['Y' 'Lim'], [-yLim, yLim]);
          set(app.avgVelAxes, ['X' 'Lim'], [saccadeTimes(1), saccadeTimes(end) + 1]);
          % averages are always aligned on onset, so draw a vertical line at that point
          hold(app.avgVelAxes, 'on');
          plot(app.avgVelAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
          hold(app.avgVelAxes, 'off');
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
        set(app.velAxes, 'YTick', yTicks);
        set(app.velAxes, 'YTickLabel', yLabels);
        ylabel(app.velAxes, 'Eye Speed (deg/s)', 'FontSize',14);
        if mustPlot
          set(app.avgVelAxes, 'YTick', yTicks);
          set(app.avgVelAxes, 'YTickLabel', yLabels);
          ylabel(app.avgVelAxes, 'Avg Eye Speed (deg/s)', 'FontSize', 14);
        end
      end
      yLim = ylim(app.velAxes);
      % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
      hold(app.velAxes, 'on');
      plot(app.velAxes, [app.stimTimeS * 1000.0, app.stimTimeS * 1000.0], yLim, 'k-.');
      plot(app.velAxes, [0, trialTimes(end)], [0, 0], 'linewidth', 0.25, 'linestyle', '-.', 'color', 'k');
      if (startIndex > 0)
        plot(app.velAxes, [startIndex, startIndex] * timestepMS, yLim, 'color', ...
          colors(app.absStepIndex,:), 'linestyle', ':');
        if (endIndex > 0)
          plot(app.velAxes, [endIndex, endIndex] * timestepMS, yLim, 'color', ...
            colors(app.absStepIndex,:), 'linestyle', ':');
        end
      end
      hold(app.velAxes, 'off');
   end
  end
end
