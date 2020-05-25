classdef RTDist < handle
  % RTAmpDur -- Handle saccade-duration data for RT
  %   Accumulates the data and handles plotting RT panels in the GUI

  properties
    ampLabel
    fHandle
    index;
    maxRT;
    n
    reactTimesMS
  end
  properties (Constant)
    titles = {'Gap', 'Step', 'Overlap'};
  end

  methods
    %% Initialization
    function obj = RTDist(app, i, axes)
      obj = obj@handle();                                % object initiatlization
      obj.index = i;                                     % post initialization
      obj.fHandle = axes;
      obj.ampLabel = sprintf('%.0f', 25.3);
      obj.reactTimesMS = zeros(1, 10000);             	 % preallocate a generous buffer
      clearAll(obj, app);
    end

    %% addRT -- add a RT value to the distributioin
    function addRT(obj, rtMS)
      obj.n = obj.n + 1;
      obj.reactTimesMS(obj.n) = max(rtMS, 0);
    end

    %% clearAll -- clear all the buffers
    function clearAll(obj, app)
      obj.n = 0;
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

    %% plot -- plot all the distributions
    function rescale = doPlots(obj)
      rescale = 0;
      if obj.n == 0                                       % nothing to plot
        return
      end
      colors = get(obj.fHandle, 'colorOrder');            % get the colors for the different plots
%       hold(obj.fHandle, 'off');
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
      displayText = {sprintf('n = %.0f', obj.n), sprintf('Mean = %.0f', meanRT), sprintf('SD = %.0f', stdRT)};
      if obj.n > 10
        sem = stdRT / sqrt(obj.n);
        ci = sem * 1.96;
        plotY = 0.95;
        [displayText, plotY] = doOneInterval(obj, meanRT, stdRT, '±1 SD:', displayText, plotY);
        [displayText, plotY] = doOneInterval(obj, meanRT, sem, '±1 SEM:', displayText, plotY);
        [displayText, ~] = doOneInterval(obj, meanRT, ci, '95% CI:', displayText, plotY);
      end
      plot(obj.fHandle, [meanRT meanRT], [a(3) a(4)], 'k:');
      text(0.05 * a(2), 0.95 * a(4), displayText, 'verticalAlignment', 'top', 'parent', obj.fHandle);
      hold(obj.fHandle, 'off');
    end

    %% rescale -- rescale the plots
    function rescale(obj, newMaxRT)
      a = axis(obj.fHandle);
      if a(2) ~= newMaxRT                                 % new x limit, announce new limit
        obj.maxRT = newMaxRT;
        hold(obj.fHandle, 'on');
        fprintf(' rescale max %f; %f %f %f %f\n', newMaxRT, a(1), a(2), a(3), a(4));
        a(2) = newMaxRT;
        fprintf(' rescale max %f; %f %f %f %f\n', newMaxRT, a(1), a(2), a(3), a(4));
        axis(obj.fHandle, a);
        hold(obj.fHandle, 'off');
      end
    end
      
    %% setupPlot -- prepare a blank plot
    function setupPlot(obj)
      title(obj.fHandle, sprintf('%s Condition', obj.titles{obj.index}), 'fontSize', 12, 'fontWeight', 'bold');
      if (obj.index == 3)                                 % label the bottom plot
        xlabel(obj.fHandle, 'Reaction Time (ms)', 'fontSize', 14);
      end
    end
  end
end

