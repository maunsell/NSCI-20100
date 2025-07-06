classdef RTDist < handle
  % RTDist -- Handle saccade-duration data for RT
  %   Accumulates the data and handles plotting RT panels in the GUI for
  %   one condition (Step or Gap)
  properties
    ampLabel
    fHandle
    index
    nativeXAxisMax;
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
      obj.nativeXAxisMax = 1;
      cla(obj.fHandle, 'reset');                        % clear the figures
      plotLabels(obj);
    end

    %% displayPrecision -- find the correct display precision for a value
    function p = displayPrecision(~, value)
      if value < 20
        p = 2 - ceil(log10(value / 2));
      else
        p = 0;
      end
    end

    %% doOneInterval -- plot the length of one confidence interval, and update the text to display
    function [displayText, plotY] = doOneInterval(obj, meanRT, value, valueStr, displayText, plotY)
      precision = value < 2.0;
      % a = axis(obj.fHandle);
      yLimits = get(obj.fHandle, ['Y' 'Lim']);       % axis() can be very slow sometimes
      colors = get(obj.fHandle, 'colorOrder');            % get the colors for the different plots
      displayText{length(displayText) + 1} = sprintf('%s %.*f-%.*f ms', valueStr, precision, meanRT - value, ...
        precision, meanRT + value);
      plot(obj.fHandle, [-value, value] + meanRT, [1, 1] * plotY * yLimits(2), 'color', colors(obj.index, :), ...
        'lineWidth', 3);
      plotY = plotY - 0.03;
    end

    %% loadStepTimesMS -- accept the RT values for the step distribution
    function loadStepTimesMS(obj, reactMS, n)
      obj.stepReactMS(1:n) = reactMS(1:n);
      obj.stepN = n;
    end

    %% doPlots -- plot all the distributions
    function xAxisMax = doPlots(obj)
      if obj.n == 0                                       % nothing to plot
        xAxisMax = 1;
        return
      end
      colors = get(obj.fHandle, 'colorOrder');            % get the colors for the different plots
      cla(obj.fHandle, 'reset');
      h = histogram(obj.fHandle, obj.reactTimesMS(1:obj.n), 'facecolor', colors(obj.index,:));
      hold(obj.fHandle, 'on');
      set(obj.fHandle, 'tickDir', 'out');
      plotLabels(obj);
      meanRT = mean(obj.reactTimesMS(1:obj.n));           % mean RT
      stdRT = std(obj.reactTimesMS(1:obj.n));             % std for RT
      displayText = {sprintf('n = %.0f, mean = %.0f', obj.n, meanRT)};
      if obj.n <= 10
        displayText{length(displayText) + 1} = sprintf('SD = %.0f', stdRT);
      else
        sem = stdRT / sqrt(obj.n);
        displayText{length(displayText) + 1} = sprintf('SD = %.0f, SEM = %0.*f', stdRT, ...
          displayPrecision(obj, sem), sem);
        if obj.stepN > 10
          [~, obj.pValue] = ttest2(obj.stepReactMS(1:obj.stepN), obj.reactTimesMS(1:obj.n), 'tail', 'right');
          displayText{length(displayText) + 1} = sprintf('t-test: p=%.3g\n', obj.pValue);
        end
      end
      a = axis(obj.fHandle);                              % set scale, flag whether we're rescaling
      a(1) = 0;                                           % always start from origin
      obj.nativeXAxisMax = a(2);                          % report our x axis maximum
      a(4) = 1.2 * max(h.Values);                       	% leave some headroom about the histogram
      axis(obj.fHandle, a);
      plot(obj.fHandle, [meanRT meanRT], [a(3) a(4)], 'k:');
      text(0.6, 0.98, displayText, 'Units', 'normalized', 'verticalAlignment', 'top', 'parent', obj.fHandle);
      hold(obj.fHandle, 'off');
      xAxisMax = obj.nativeXAxisMax;                      % return our native axis
    end
    
    %% rescale -- rescale the plots
    function rescale(obj, newMaxRT)
      xLimits = get(obj.fHandle, ['X' 'Lim']);                  % axis() can be very slow sometimes
      if xLimits(2) ~= newMaxRT                                 % new x limit, announce new limit
        obj.nativeXAxisMax = xLimits(2);                        % save our natural x axis max
        hold(obj.fHandle, 'on');
        xLimits(2) = newMaxRT;
        set(obj.fHandle, ['X' 'Lim'], xLimits);
        hold(obj.fHandle, 'off');
      end
    end

    %% plotLabels -- prepare a blank plot
    function plotLabels(obj)
      title(obj.fHandle, sprintf('%s Condition', obj.titles{obj.index}), 'fontSize', 12, 'fontWeight', 'bold');
      xlabel(obj.fHandle, 'Reaction Time (ms)', 'fontSize', 14);
      ylabel(obj.fHandle, 'Saccade Count', 'fontSize', 14);
    end
     
    %% setXAxisMax -- set the maximum x axis value 
    function setXAxisMax(obj, newXMax)
      xLimits = get(obj.fHandle, ['X' 'Lim']);                  % axis() can be very slow sometimes
      hold(obj.fHandle, 'on');
      xLimits(2) = newXMax;
      set(obj.fHandle, ['X' 'Lim'], xLimits);
      hold(obj.fHandle, 'off');
    end
       
    %% xAxisMax -- return the xAxisMax we would use if unadjusted 
    function xMax = xAxisMax(obj)
      xMax = obj.nativeXAxisMax;
      % xLimits = get(obj.fHandle, ['X' 'Lim']);                  % axis() can be very slow sometimes
      % xMax = xLimits(2);
    end

  end
end

