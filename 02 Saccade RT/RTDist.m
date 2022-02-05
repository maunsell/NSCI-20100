classdef RTDist < handle
  % RTDist -- Handle saccade-duration data for RT
  %   Accumulates the data and handles plotting RT panels in the GUI for
  %   one condition (Step or Gap)
  properties
    ampLabel
    fHandle
    index
    maxRT
    n
    pValue
    reactTimesMS
    stepN                     % N transferred from step condition (for t-test)
    stepReactMS                 % RTs transferred from step condition (for t-test)
  end
  properties (Constant)
    titles = {'Gap', 'Step'};
  end

  methods
    %% Initialization
    function obj = RTDist(app, i, axes)
      obj = obj@handle();                                % object initiatlization
      obj.index = i;                                     % post initialization
      obj.fHandle = axes;
      obj.ampLabel = sprintf('%.0f', 25.3);
      obj.reactTimesMS = zeros(1, 10000);             	 % preallocate a generous buffer
      obj.stepReactMS = zeros(1, 10000);                 % preallocate a generous buffer
      clearAll(obj, app);
    end

    %% addRT -- add a RT value to the distributioin
    function addRT(obj, rtMS)
      obj.n = obj.n + 1;
      obj.reactTimesMS(obj.n) = max(rtMS, 0);
    end

    %% clearAll -- clear all the buffers
    function clearAll(obj, ~)
      obj.n = 0;
      obj.stepN = 0;
      obj.maxRT = 0;
      cla(obj.fHandle, 'reset');                        % clear the figures
      setupPlot(obj);
    end

    %% doOneInterval -- plot the length of one confidence interval, and update the text to display
    function [displayText, plotY] = doOneInterval(obj, meanRT, value, valueStr, displayText, plotY)
      precision = value < 2.0;
      a = axis(obj.fHandle);
      colors = get(obj.fHandle, 'colorOrder');            % get the colors for the different plots
      displayText{length(displayText) + 1} = sprintf('%s %.*f-%.*f ms', valueStr, precision, meanRT - value, ...
        precision, meanRT + value);
      plot(obj.fHandle, [-value, value] + meanRT, [1, 1] * plotY * a(4), 'color', colors(obj.index, :), ...
        'lineWidth', 3);
      plotY = plotY - 0.03;
    end

    %% stepTimesMS -- accept the RT values for the step distribution
    function loadStepTimesMS(obj, reactMS, n)
      obj.stepReactMS(1:n) = reactMS(1:n);
      obj.stepN = n;
    end

    %% plot -- plot all the distributions
    function rescale = doPlots(obj)
      rescale = 0;
      if obj.n == 0                                       % nothing to plot
        return
      end
      colors = get(obj.fHandle, 'colorOrder');            % get the colors for the different plots
      cla(obj.fHandle, 'reset');
      h = histogram(obj.fHandle, obj.reactTimesMS(1:obj.n), 'facecolor', colors(obj.index,:));
      set(obj.fHandle, 'tickDir', 'out');
      hold(obj.fHandle, 'on');
      setupPlot(obj);
      a = axis(obj.fHandle);                              % set scale, flag whether we're rescaling
      a(1) = 0;
      if a(2) > obj.maxRT                                 % new x limit, announce new limit
        obj.maxRT = a(2);
        rescale = a(2);
      else                                                % otherwise, force plot to current maxRT
        a(2) = obj.maxRT;
      end
      a(4) = 1.2 * max(h.Values);                       	% leave some headroom about the histogram
      axis(obj.fHandle, a);
      meanRT = mean(obj.reactTimesMS(1:obj.n));           % mean RT
      stdRT = std(obj.reactTimesMS(1:obj.n));             % std for RT
      displayText = {sprintf('n = %.0f, mean = %.0f', obj.n, meanRT)};
      if obj.n <= 10
        displayText{length(displayText) + 1} = sprintf('SD = %.0f', stdRT);
      else
        sem = stdRT / sqrt(obj.n);
        displayText{length(displayText) + 1} = sprintf('SD = %.0f, SEM = %0.*f', stdRT, ...
          displayPrecision(obj, sem), sem);
%         ci = sem * 1.96;
%         plotY = 0.95;
%         [displayText, plotY] = doOneInterval(obj, meanRT, stdRT, '±1 SD:', displayText, plotY);
%         [displayText, plotY] = doOneInterval(obj, meanRT, sem, '±1 SEM:', displayText, plotY);
%         [displayText, ~] = doOneInterval(obj, meanRT, ci, '95% CI:', displayText, plotY);
        if obj.stepN > 10
          [~, obj.pValue] = ttest2(obj.stepReactMS(1:obj.stepN), obj.reactTimesMS(1:obj.n), 'tail', 'right');
          displayText{length(displayText) + 1} = sprintf('t-test: p=%.3g\n', obj.pValue);
        end
      end
      plot(obj.fHandle, [meanRT meanRT], [a(3) a(4)], 'k:');
      text(0.6 * a(2), 0.98 * a(4), displayText, 'verticalAlignment', 'top', 'parent', obj.fHandle);
      hold(obj.fHandle, 'off');
    end
    
    %% precision -- find the correct display precision for a value
    function p = displayPrecision(~, value)
      if value < 20
        p = 2 - ceil(log10(value / 2));
      else
        p = 0;
      end
    end

    %% rescale -- rescale the plots
    function rescale(obj, newMaxRT)
      a = axis(obj.fHandle);
      if a(2) ~= newMaxRT                                 % new x limit, announce new limit
        obj.maxRT = newMaxRT;
        hold(obj.fHandle, 'on');
        a(2) = newMaxRT;
        axis(obj.fHandle, a);
        hold(obj.fHandle, 'off');
      end
    end

    %% setupPlot -- prepare a blank plot
    function setupPlot(obj)
      title(obj.fHandle, sprintf('%s Condition', obj.titles{obj.index}), 'fontSize', 12, 'fontWeight', 'bold');
      if (obj.index == 2)                                 % label the bottom plot
        xlabel(obj.fHandle, 'Reaction Time (ms)', 'fontSize', 14);
      end
    end
  end
end

