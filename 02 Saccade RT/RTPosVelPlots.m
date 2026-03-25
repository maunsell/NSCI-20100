classdef RTPosVelPlots < handle
  % Support for processing eye traces and detecting saccades
  %
  % Rewritten to follow the "create graphics objects once, then update
  % properties" pattern for more efficient plotting.

  properties
    % Position axis graphics handles
    posZeroLine
    posTraceLine
    posThreshLine
    posTargetLine
    posFixOffLine
    posStartLine
    posEndLine

    % Velocity axis graphics handles
    velZeroLine
    velTraceLine
    velThreshLine
    velTargetLine
    velFixOffLine
    velStartLine
    velEndLine
  end

  methods
    function obj = RTPosVelPlots(app)
      %% Object Initialization %%
      obj = obj@handle();

      %% Initialize axes and graphics objects once %%
      initializeAxesAndLines(obj, app);
    end

    %%
    function calibratedLabels(~, theAxes, conversion, unit)
      yLim = max(abs(ylim(theAxes)));
      maxCalValue = ceil((yLim * conversion) / unit) * unit;   % rounded up to nearest unit
      increment = unit;
      while maxCalValue / increment > 5
        increment = increment * 2;
      end

      yTicks = (-maxCalValue:increment:maxCalValue) / conversion;
      yLabels = cell(length(yTicks), 1);
      for i = 1:length(yTicks)
        yLabels{i} = num2str(yTicks(i) * conversion, '%.0f');
      end
      set(theAxes, 'YTick', yTicks, 'YTickLabel', yLabels);
    end

    %%
    function doPlots(obj, app, startIndex, endIndex)
      % Update all plots for RT
      posPlots(obj, app, startIndex, endIndex);
      velPlots(obj, app, startIndex, endIndex);
    end

    %%
    function initializeAxesAndLines(obj, app)
      % Reset axes once at startup
      cla(app.posAxes, 'reset');
      cla(app.velAxes, 'reset');

      % ---- Position axes ----
      title(app.posAxes, 'Eye Position', 'FontSize', 14, 'FontWeight', 'bold');
      xlabel(app.posAxes, 'Time (ms)', 'FontSize', 14, 'FontWeight', 'bold');
      ylabel(app.posAxes, 'Analog Input (V)', 'FontSize', 14, 'FontWeight', 'bold');

      hold(app.posAxes, 'on');
      obj.posZeroLine   = plot(app.posAxes, [0 1], [0 0], 'k');
      obj.posTraceLine  = plot(app.posAxes, nan, nan, 'b');
      obj.posThreshLine = plot(app.posAxes, nan, nan, 'r:');
      obj.posTargetLine = plot(app.posAxes, nan, nan, 'k-.');
      obj.posFixOffLine = plot(app.posAxes, nan, nan, 'r-.');
      obj.posStartLine  = plot(app.posAxes, nan, nan, 'b:');
      obj.posEndLine    = plot(app.posAxes, nan, nan, 'b:');
      hold(app.posAxes, 'off');

      % ---- Velocity axes ----
      title(app.velAxes, 'Eye Speed', 'FontSize', 14, 'FontWeight', 'bold');
      xlabel(app.velAxes, 'Time (ms)', 'FontSize', 14, 'FontWeight', 'bold');
      ylabel(app.velAxes, 'Analog Input (dV/dt)', 'FontSize', 14, 'FontWeight', 'bold');

      hold(app.velAxes, 'on');
      obj.velZeroLine   = plot(app.velAxes, [0 1], [0 0], 'k');
      obj.velTraceLine  = plot(app.velAxes, nan, nan, 'b');
      obj.velThreshLine = plot(app.velAxes, nan, nan, 'r:');
      obj.velTargetLine = plot(app.velAxes, nan, nan, 'k-.');
      obj.velFixOffLine = plot(app.velAxes, nan, nan, 'r-.');
      obj.velStartLine  = plot(app.velAxes, nan, nan, 'b:');
      obj.velEndLine    = plot(app.velAxes, nan, nan, 'b:');
      hold(app.velAxes, 'off');

      % Start with optional lines hidden
      set([obj.posThreshLine obj.posFixOffLine obj.posStartLine obj.posEndLine ...
           obj.velThreshLine obj.velFixOffLine obj.velStartLine obj.velEndLine], ...
           'Visible', 'off');
    end

    %% posPlots: do the trial position plot
    function posPlots(obj, app, startIndex, endIndex)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;          % sample interval
      xLimit = (size(app.posTrace, 1) - 1) * timestepMS;
      trialTimes = 0:timestepMS:xLimit;

      % Update basic trace lines
      set(obj.posZeroLine,  'XData', [0, xLimit], 'YData', [0, 0]);
      set(obj.posTraceLine, 'XData', trialTimes,  'YData', app.posTrace);

      % Establish symmetric y-limits from trace and optional threshold
      yLimit = max(abs(app.posTrace(:)));
      if isempty(yLimit) || ~isfinite(yLimit) || yLimit <= 0
        yLimit = 1;
      end

      saccades = app.saccades;
      showThresh = false;
      thresholdV = 0;

      if saccades.degPerV > 0
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Position')
          thresholdV = saccades.thresholdDeg / saccades.degPerV * app.stepSign;
          yLimit = max(yLimit, abs(thresholdV));
          showThresh = true;
        end
      end

      ylim(app.posAxes, [-yLimit, yLimit]);
      xlim(app.posAxes, [0, xLimit]);

      % Threshold line
      if showThresh
        set(obj.posThreshLine, ...
          'XData', [trialTimes(1) trialTimes(end)], ...
          'YData', [thresholdV thresholdV], ...
          'Visible', 'on');
      else
        set(obj.posThreshLine, 'Visible', 'off');
      end

      % Labels and calibrated ticks
      if saccades.degPerV > 0
        calibratedLabels(obj, app.posAxes, saccades.degPerV, 2);
        ylabel(app.posAxes, 'Eye Position (deg)', 'FontSize', 14, 'FontWeight', 'bold');
      else
        set(app.posAxes, 'YTickMode', 'auto', 'YTickLabelMode', 'auto');
        ylabel(app.posAxes, 'Analog Input (V)', 'FontSize', 14, 'FontWeight', 'bold');
      end

      % Vertical event markers
      yLimits = ylim(app.posAxes);

      set(obj.posTargetLine, ...
        'XData', [app.targetTimeS app.targetTimeS] * 1000, ...
        'YData', yLimits, ...
        'Visible', 'on');

      if app.fixOffTimeS ~= app.targetTimeS
        set(obj.posFixOffLine, ...
          'XData', [app.fixOffTimeS app.fixOffTimeS] * 1000, ...
          'YData', yLimits, ...
          'Visible', 'on');
      else
        set(obj.posFixOffLine, 'Visible', 'off');
      end

      if startIndex > 0
        set(obj.posStartLine, ...
          'XData', [startIndex startIndex] * timestepMS, ...
          'YData', yLimits, ...
          'Visible', 'on');
      else
        set(obj.posStartLine, 'Visible', 'off');
      end

      if endIndex > 0
        set(obj.posEndLine, ...
          'XData', [endIndex endIndex] * timestepMS, ...
          'YData', yLimits, ...
          'Visible', 'on');
      else
        set(obj.posEndLine, 'Visible', 'off');
      end
    end

    %% velPlots: do the trial velocity plot
    function velPlots(obj, app, startIndex, endIndex)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;          % sample interval
      xLimit = (size(app.posTrace, 1) - 1) * timestepMS;
      trialTimes = 0:timestepMS:xLimit;

      % Update basic trace lines
      set(obj.velZeroLine,  'XData', [0, xLimit], 'YData', [0, 0]);
      set(obj.velTraceLine, 'XData', trialTimes,  'YData', app.velTrace);

      % Establish symmetric y-limits from trace and optional threshold
      yLimit = max(abs(app.velTrace(:)));
      if isempty(yLimit) || ~isfinite(yLimit) || yLimit <= 0
        yLimit = 1;
      end

      saccades = app.saccades;
      showThresh = false;
      thresholdV = 0;

      if saccades.degPerSPerV > 0
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Speed')
          thresholdV = saccades.thresholdDPS / saccades.degPerSPerV * app.stepSign;
          yLimit = max(yLimit, abs(thresholdV));
          showThresh = true;
        end
      end

      ylim(app.velAxes, [-yLimit, yLimit]);
      xlim(app.velAxes, [0, xLimit]);

      % Threshold line
      if showThresh
        set(obj.velThreshLine, ...
          'XData', [trialTimes(1) trialTimes(end)], ...
          'YData', [thresholdV thresholdV], ...
          'Visible', 'on');
      else
        set(obj.velThreshLine, 'Visible', 'off');
      end

      % Labels and calibrated ticks
      if saccades.degPerSPerV > 0
        calibratedLabels(obj, app.velAxes, saccades.degPerSPerV, 100);
        ylabel(app.velAxes, 'Eye Speed (deg/s)', 'FontSize', 14, 'FontWeight', 'bold');
      else
        set(app.velAxes, 'YTickMode', 'auto', 'YTickLabelMode', 'auto');
        ylabel(app.velAxes, 'Analog Input (dV/dt)', 'FontSize', 14, 'FontWeight', 'bold');
      end

      % Vertical event markers
      yLimits = ylim(app.velAxes);

      set(obj.velTargetLine, ...
        'XData', [app.targetTimeS app.targetTimeS] * 1000, ...
        'YData', yLimits, ...
        'Visible', 'on');

      if app.fixOffTimeS ~= app.targetTimeS
        set(obj.velFixOffLine, ...
          'XData', [app.fixOffTimeS app.fixOffTimeS] * 1000, ...
          'YData', yLimits, ...
          'Visible', 'on');
      else
        set(obj.velFixOffLine, 'Visible', 'off');
      end

      if startIndex > 0
        set(obj.velStartLine, ...
          'XData', [startIndex startIndex] * timestepMS, ...
          'YData', yLimits, ...
          'Visible', 'on');
      else
        set(obj.velStartLine, 'Visible', 'off');
      end

      if endIndex > 0
        set(obj.velEndLine, ...
          'XData', [endIndex endIndex] * timestepMS, ...
          'YData', yLimits, ...
          'Visible', 'on');
      else
        set(obj.velEndLine, 'Visible', 'off');
      end
    end
  end
end