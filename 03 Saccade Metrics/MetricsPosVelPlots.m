classdef MetricsPosVelPlots < handle
  % Support for processing eye traces and detecting saccades
  % Refactored to create graphics objects once and update them thereafter.

  properties
    % Current-trial position axis handles
    posTraceLine
    posZeroLine
    posThreshLine
    posStimLine
    posStartLine
    posEndLine

    % Current-trial velocity axis handles
    velTraceLine
    velZeroLine
    velThreshLine
    velStimLine
    velStartLine
    velEndLine

    % Average position axis handles
    avgPosZeroTimeLine
    avgPosTraceLines
    avgPosMedianLines

    % Average velocity axis handles
    avgVelZeroTimeLine
    avgVelTraceLines

    % Cached configuration
    numOffsets = 0
    halfOffsets = 0
  end

  methods
    function obj = MetricsPosVelPlots(app)
      obj = obj@handle();

      assert(mod(app.numOffsets, 2) == 0, 'numOffsets must be even.');

      obj.numOffsets  = app.numOffsets;
      obj.halfOffsets = app.numOffsets / 2;

      initializeAxesAndLines(obj, app);
      updateTitles(obj, app);
    end

    %%
    function plotPosVel(obj, app, startIndex, endIndex, mustPlot)
      mustPlot = mustPlot || (mod(sum(app.numSummed), app.numOffsets) == 0);

      posPlots(obj, app, startIndex, endIndex, mustPlot);
      velPlots(obj, app, startIndex, endIndex, mustPlot);
      updateTitles(obj, app);
    end

    %%
    function updateTitles(~, app)
      title(app.posAxes, 'Eye Position', 'FontSize', 12, 'FontWeight', 'bold');
      title(app.velAxes, 'Eye Speed', 'FontSize', 12, 'FontWeight', 'bold');
      title(app.avgPosAxes, sprintf('Average Positions (n≥%d)', app.blocksDone), ...
        'FontSize', 12, 'FontWeight', 'bold');
      title(app.avgVelAxes, sprintf('Average Speeds (n≥%d)', app.blocksDone), ...
        'FontSize', 12, 'FontWeight', 'bold');
    end

    %%
    function initializeAxesAndLines(obj, app)
      cla(app.posAxes, 'reset');
      cla(app.velAxes, 'reset');
      cla(app.avgPosAxes, 'reset');
      cla(app.avgVelAxes, 'reset');

      % Position trial axes
      xlabel(app.posAxes, 'Time (ms)', 'FontSize', 14);
      ylabel(app.posAxes, 'Analog Input (V)', 'FontSize', 14);
      hold(app.posAxes, 'on');
      obj.posTraceLine  = plot(app.posAxes, nan, nan, '-');
      obj.posZeroLine   = plot(app.posAxes, [0 1], [0 0], 'k-.', 'LineWidth', 0.25);
      obj.posThreshLine = plot(app.posAxes, nan, nan, 'r:');
      obj.posStimLine   = plot(app.posAxes, nan, nan, 'k-.');
      obj.posStartLine  = plot(app.posAxes, nan, nan, ':');
      obj.posEndLine    = plot(app.posAxes, nan, nan, ':');
      hold(app.posAxes, 'off');

      % Velocity trial axes
      xlabel(app.velAxes, 'Time (ms)', 'FontSize', 14);
      ylabel(app.velAxes, 'Analog Input (dV/dt)', 'FontSize', 14);
      hold(app.velAxes, 'on');
      obj.velTraceLine  = plot(app.velAxes, nan, nan, '-');
      obj.velZeroLine   = plot(app.velAxes, [0 1], [0 0], 'k-.', 'LineWidth', 0.25);
      obj.velThreshLine = plot(app.velAxes, nan, nan, 'r:');
      obj.velStimLine   = plot(app.velAxes, nan, nan, 'k-.');
      obj.velStartLine  = plot(app.velAxes, nan, nan, ':');
      obj.velEndLine    = plot(app.velAxes, nan, nan, ':');
      hold(app.velAxes, 'off');

      % Average position axes
      xlabel(app.avgPosAxes, 'Time (ms)', 'FontSize', 14);
      ylabel(app.avgPosAxes, 'Analog Input (V)', 'FontSize', 14);
      hold(app.avgPosAxes, 'on');
      obj.avgPosTraceLines = gobjects(1, obj.numOffsets);
      for i = 1:obj.numOffsets
        obj.avgPosTraceLines(i) = plot(app.avgPosAxes, nan, nan, '-');
      end
      obj.avgPosZeroTimeLine = plot(app.avgPosAxes, nan, nan, 'k:');
      obj.avgPosMedianLines = gobjects(1, obj.numOffsets);
      for i = 1:obj.numOffsets
        obj.avgPosMedianLines(i) = plot(app.avgPosAxes, nan, nan, ':');
      end
      hold(app.avgPosAxes, 'off');

      % Average velocity axes
      xlabel(app.avgVelAxes, 'Time (ms)', 'FontSize', 14);
      ylabel(app.avgVelAxes, 'Analog Input (dV/dt)', 'FontSize', 14);
      hold(app.avgVelAxes, 'on');
      obj.avgVelTraceLines = gobjects(1, obj.numOffsets);
      for i = 1:obj.numOffsets
        obj.avgVelTraceLines(i) = plot(app.avgVelAxes, nan, nan, '-');
      end
      obj.avgVelZeroTimeLine = plot(app.avgVelAxes, nan, nan, 'k:');
      hold(app.avgVelAxes, 'off');

      set([obj.posThreshLine obj.posStartLine obj.posEndLine ...
           obj.velThreshLine obj.velStartLine obj.velEndLine ...
           obj.avgPosZeroTimeLine obj.avgVelZeroTimeLine], 'Visible', 'off');

      hideLineBank(obj, obj.avgPosMedianLines);
      hideLineBank(obj, obj.avgPosTraceLines);
      hideLineBank(obj, obj.avgVelTraceLines);
    end

    %% Position plots
    function posPlots(obj, app, startIndex, endIndex, mustPlot)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;
      trialTimes = (0:size(app.posTrace,1)-1) * timestepMS;
      colors = get(app.posAxes, 'ColorOrder');
      traceColor = colors(app.absStepIndex, :);
      saccades = app.saccades;

      set(obj.posTraceLine, ...
        'XData', trialTimes, ...
        'YData', app.posTrace, ...
        'Color', traceColor);

      yLimTrial = obj.safeMaxAbs(app.posTrace);

      if saccades.degPerV > 0 && strcmp(app.ThresholdType.SelectedObject.Text, 'Position')
        thresholdV = saccades.thresholdDeg / saccades.degPerV * app.stepSign;
        yLimTrial = max(yLimTrial, abs(thresholdV));
        updateHorizontalLine(obj, obj.posThreshLine, trialTimes, thresholdV, true);
      else
        set(obj.posThreshLine, 'Visible', 'off');
      end

      yLimAvg = [];
      if mustPlot
        if sum(app.numSummed) == 0
          hideLineBank(obj, obj.avgPosTraceLines);
          hideLineBank(obj, obj.avgPosMedianLines);
          set(obj.avgPosZeroTimeLine, 'Visible', 'off');
          xlim(app.avgPosAxes, [-1 1]);
          ylim(app.avgPosAxes, [-1 1]);
        else
          saccadeTimes = (-(size(app.posAvg,1)/2):((size(app.posAvg,1)/2)-1)) * timestepMS;

          updateAverageTraceBank(obj, obj.avgPosTraceLines, saccadeTimes, app.posAvg, colors, obj.halfOffsets);

          yLimAvg = obj.safeMaxAbs(app.posAvg);
          xlim(app.avgPosAxes, [saccadeTimes(1), saccadeTimes(end) + 1]);
          ylim(app.avgPosAxes, [-yLimAvg, yLimAvg]);

          set(obj.avgPosZeroTimeLine, ...
            'XData', [0 0], ...
            'YData', [-yLimAvg yLimAvg], ...
            'Visible', 'on');

          updateMedianLines(obj, obj.avgPosMedianLines, app.medians, app.numSummed, yLimAvg, colors, obj.halfOffsets);

          if saccades.degPerV > 0
            yTicks = [fliplr(-app.offsetsDeg(1:obj.halfOffsets)), 0, app.offsetsDeg(1:obj.halfOffsets)] / saccades.degPerV;
            yLabels = arrayfun(@(x) num2str(x * saccades.degPerV, '%.0f'), yTicks, 'UniformOutput', false);
            set(app.avgPosAxes, 'YTick', yTicks, 'YTickLabel', yLabels);
            ylabel(app.avgPosAxes, 'Avg Eye Position (deg)', 'FontSize', 14);
          else
            set(app.avgPosAxes, 'YTickMode', 'auto', 'YTickLabelMode', 'auto');
            ylabel(app.avgPosAxes, 'Analog Input (V)', 'FontSize', 14);
          end
        end
      end

      if sum(app.numSummed) > app.numOffsets && ~isempty(yLimAvg)
        yLimFinal = yLimAvg;
      else
        yLimFinal = yLimTrial;
      end

      xlim(app.posAxes, [0 trialTimes(end)]);
      ylim(app.posAxes, [-yLimFinal yLimFinal]);

      if saccades.degPerV > 0
        calibratedLabels(obj, app.posAxes, saccades.degPerV, 2);
        ylabel(app.posAxes, 'Eye Position (deg)', 'FontSize', 14);
      else
        set(app.posAxes, 'YTickMode', 'auto', 'YTickLabelMode', 'auto');
        ylabel(app.posAxes, 'Analog Input (V)', 'FontSize', 14);
      end

      yL = ylim(app.posAxes);

      set(obj.posZeroLine, 'XData', [0 trialTimes(end)], 'YData', [0 0]);
      updateVerticalLine(obj, obj.posStimLine,  app.stimTimeS * 1000.0, yL, true);
      updateVerticalLine(obj, obj.posStartLine, startIndex * timestepMS, yL, startIndex > 0, traceColor);
      updateVerticalLine(obj, obj.posEndLine,   endIndex * timestepMS,   yL, endIndex > 0, traceColor);
    end

    %% Velocity plots
    function velPlots(obj, app, startIndex, endIndex, mustPlot)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;
      trialTimes = (0:size(app.posTrace,1)-1) * timestepMS;
      saccadeTimes = (-(size(app.posAvg,1)/2):((size(app.posAvg,1)/2)-1)) * timestepMS;
      colors = get(app.velAxes, 'ColorOrder');
      traceColor = colors(app.absStepIndex, :);
      saccades = app.saccades;

      set(obj.velTraceLine, ...
        'XData', trialTimes, ...
        'YData', app.velTrace, ...
        'Color', traceColor);

      yLimTrial = obj.safeMaxAbs(app.velTrace);

      if saccades.degPerSPerV > 0 && strcmp(app.ThresholdType.SelectedObject.Text, 'Speed')
        thresholdV = saccades.thresholdDPS / saccades.degPerSPerV * app.stepSign;
        yLimTrial = max(yLimTrial, abs(thresholdV));
        updateHorizontalLine(obj, obj.velThreshLine, trialTimes, thresholdV, true);
      else
        set(obj.velThreshLine, 'Visible', 'off');
      end

      yLimAvg = [];
      if mustPlot
        if sum(app.numSummed) == 0
          hideLineBank(obj, obj.avgVelTraceLines);
          set(obj.avgVelZeroTimeLine, 'Visible', 'off');
          xlim(app.avgVelAxes, [-1 1]);
          ylim(app.avgVelAxes, [-1 1]);
        else
          updateAverageTraceBank(obj, obj.avgVelTraceLines, saccadeTimes, app.velAvg, colors, obj.halfOffsets);

          yLimAvg = obj.safeMaxAbs(app.velAvg);
          xlim(app.avgVelAxes, [saccadeTimes(1), saccadeTimes(end) + 1]);
          ylim(app.avgVelAxes, [-yLimAvg yLimAvg]);

          set(obj.avgVelZeroTimeLine, ...
            'XData', [0 0], ...
            'YData', [-yLimAvg yLimAvg], ...
            'Visible', 'on');
        end
      end

      if mustPlot && sum(app.numSummed) > 0 && ~isempty(yLimAvg)
        yLimFinal = max(yLimTrial, yLimAvg);
      else
        yLimFinal = yLimTrial;
      end

      xlim(app.velAxes, [0 trialTimes(end)]);
      ylim(app.velAxes, [-yLimFinal yLimFinal]);

      if mustPlot && sum(app.numSummed) > 0 && ~isempty(yLimAvg)
        ylim(app.avgVelAxes, [-yLimFinal yLimFinal]);
        set(obj.avgVelZeroTimeLine, ...
          'XData', [0 0], ...
          'YData', [-yLimFinal yLimFinal], ...
          'Visible', 'on');
      end

      if saccades.degPerSPerV > 0
        calibratedLabels(obj, app.velAxes, saccades.degPerSPerV, 100);
        ylabel(app.velAxes, 'Eye Speed (deg/s)', 'FontSize', 14);

        if mustPlot && sum(app.numSummed) > 0
          calibratedLabels(obj, app.avgVelAxes, saccades.degPerSPerV, 100);
          ylabel(app.avgVelAxes, 'Avg Eye Speed (deg/s)', 'FontSize', 14);
        end
      else
        set(app.velAxes, 'YTickMode', 'auto', 'YTickLabelMode', 'auto');
        ylabel(app.velAxes, 'Analog Input (dV/dt)', 'FontSize', 14);

        if mustPlot
          set(app.avgVelAxes, 'YTickMode', 'auto', 'YTickLabelMode', 'auto');
          ylabel(app.avgVelAxes, 'Analog Input (dV/dt)', 'FontSize', 14);
        end
      end

      yL = ylim(app.velAxes);

      set(obj.velZeroLine, 'XData', [0 trialTimes(end)], 'YData', [0 0]);
      updateVerticalLine(obj, obj.velStimLine,  app.stimTimeS * 1000.0, yL, true);
      updateVerticalLine(obj, obj.velStartLine, startIndex * timestepMS, yL, startIndex > 0, traceColor);
      updateVerticalLine(obj, obj.velEndLine,   endIndex * timestepMS,   yL, endIndex > 0, traceColor);
    end

    %% Helper methods
    function calibratedLabels(~, theAxes, conversion, unit)
      yLim = max(abs(ylim(theAxes)));
      maxCalValue = ceil((yLim * conversion) / unit) * unit;
      increment = unit;
      while maxCalValue / increment > 5
        increment = increment * 2;
      end
      yTicks = (-maxCalValue:increment:maxCalValue) / conversion;
      yLabels = arrayfun(@(x) num2str(x * conversion, '%.0f'), yTicks, 'UniformOutput', false);
      set(theAxes, 'YTick', yTicks, 'YTickLabel', yLabels);
    end

    function m = safeMaxAbs(~, x)
      m = max(abs(x(:)));
      if isempty(m) || ~isfinite(m) || m <= 0
        m = 1;
      end
    end

    function updateHorizontalLine(~, hLine, xVals, yVal, isVisible)
      if isVisible
        set(hLine, ...
          'XData', [xVals(1) xVals(end)], ...
          'YData', [yVal yVal], ...
          'Visible', 'on');
      else
        set(hLine, 'Visible', 'off');
      end
    end

    function updateVerticalLine(~, hLine, xVal, yLimits, isVisible, varargin)
      if isVisible
        set(hLine, ...
          'XData', [xVal xVal], ...
          'YData', yLimits, ...
          'Visible', 'on');
        if ~isempty(varargin)
          set(hLine, 'Color', varargin{1});
        end
      else
        set(hLine, 'Visible', 'off');
      end
    end

    function hideLineBank(~, hLines)
      if ~isempty(hLines)
        set(hLines, 'XData', nan, 'YData', nan, 'Visible', 'off');
      end
    end

    function updateAverageTraceBank(~, hLines, xVals, yMat, colors, halfOffsets)
      nLines = numel(hLines);
      for i = 1:nLines
        set(hLines(i), ...
          'XData', xVals, ...
          'YData', yMat(:,i), ...
          'Color', colors(mod(i-1, halfOffsets) + 1, :), ...
          'Visible', 'on');
      end
    end

    function updateMedianLines(~, hLines, medians, numSummed, yLimAvg, colors, halfOffsets)
      nLines = numel(hLines);
      for i = 1:nLines
        if numSummed(i) > 0
          yEnd = yLimAvg - floor((i - 1) / halfOffsets) * 2 * yLimAvg;
          set(hLines(i), ...
            'XData', [medians(i) medians(i)], ...
            'YData', [0 yEnd], ...
            'Color', colors(mod(i - 1, halfOffsets) + 1, :), ...
            'Visible', 'on');
        else
          set(hLines(i), 'Visible', 'off');
        end
      end
    end
  end
end