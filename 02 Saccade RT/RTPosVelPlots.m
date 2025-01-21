classdef RTPosVelPlots < handle
  %   Support for processing eye traces and detecting saccades
  methods
    function obj = RTPosVelPlots(app)
      %% Object Initialization %%
      obj = obj@handle();                                            % object initialization
      
      %% Post Initialization %%
      cla(app.posAxes, 'reset');
      cla(app.velAxes, 'reset');
      title(app.posAxes, 'Single position trace', 'fontSize', 12, 'fontWeight', 'bold')
      title(app.velAxes, 'Single velocity trace', 'fontSize', 12, 'fontWeight', 'bold')
    end
    
    %%
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
    
    %%
    function doPlots(obj, app, startIndex, endIndex)
      % RTPlots Updata all plots for RT
      posPlots(obj, app, startIndex, endIndex);
      velPlots(obj, app, startIndex, endIndex);
    end
    
    %% posPlots: do the trial and average position plots
    function posPlots(obj, app, startIndex, endIndex)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;                 % time interval of samples
      xLimit = (size(app.posTrace, 1) - 1) * timestepMS;
      trialTimes = 0:timestepMS:xLimit;                           % make array of trial time points
      % current trial position trace
      cla(app.posAxes, 'reset');
      plot(app.posAxes, [0, xLimit], [0, 0], 'k');
      hold(app.posAxes, 'on'); 
      plot(app.posAxes, trialTimes, app.posTrace, 'b');
      yLimit = max(abs(ylim(app.posAxes)));
      ylim(app.posAxes, [-yLimit, yLimit]);
      saccades = app.saccades;
      if saccades.degPerV > 0                                     % plot saccade threshold
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Position')
          thresholdV = saccades.thresholdDeg / saccades.degPerV * app.stepSign;
          plot(app.posAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], 'r:');
        end
        calibratedLabels(obj, app.posAxes, saccades.degPerV, 2)
        ylabel(app.posAxes,'Eye Position (deg)','FontSize',14);
      else
        ylabel(app.posAxes,'Analog Input (V)','FontSize',14);
      end
      title(app.posAxes, 'Most recent position trace', 'fontSize', 12, 'fontWeight', 'bold')
      yLimits = get(app.posAxes, ['Y' 'Lim']);       % axis() can be very slow sometimes
      plot(app.posAxes, [app.targetTimeS, app.targetTimeS] * 1000, yLimits, 'k-.');
      if (app.fixOffTimeS ~= app.targetTimeS)
        plot(app.posAxes, [app.fixOffTimeS, app.fixOffTimeS] * 1000, yLimits, 'r-.');
      end
      if (startIndex > 0)                                 % mark the saccade start and end
        plot(app.posAxes, [startIndex, startIndex] * timestepMS, yLimits, 'b:');
        if (endIndex > 0)
          plot(app.posAxes, [endIndex, endIndex] * timestepMS, yLimits, 'b:');
        end
      end
      hold(app.posAxes, 'off');
    end
    
    %% velPlots: do the trial velocity plot
    function velPlots(obj, app, startIndex, endIndex)
      timestepMS = 1000.0 / app.lbj.SampleRateHz;                     % time interval of samples
      xLimit = (size(app.posTrace, 1) - 1) * timestepMS;
      trialTimes = 0:timestepMS:xLimit;                               % make array of trial time points
      % plot the trial velocity trace
      cla(app.velAxes, 'reset');                                      % we need 'reset' to clear axis scaling
      plot(app.velAxes, [0, xLimit], [0, 0], 'k', trialTimes, app.velTrace, 'b');
      yLimit = max(abs(ylim(app.velAxes)));
      ylim(app.velAxes, [-yLimit, yLimit]);
      xlabel(app.velAxes,'Time (ms)','FontSize',14);
      hold(app.velAxes, 'on');                                    % mark fixOff and targetOn
      saccades = app.saccades;
      % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
      if saccades.degPerSPerV > 0
        if strcmp(app.ThresholdType.SelectedObject.Text, 'Speed')
          thresholdV = saccades.thresholdDPS / saccades.degPerSPerV * app.stepSign;
          plot(app.velAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], 'r:');
        end
        calibratedLabels(obj, app.velAxes, app.saccades.degPerSPerV, 100)
        ylabel(app.velAxes, 'Eye Speed (deg/s)', 'FontSize', 14);
      else
        ylabel(app.velAxes, 'Analog Input (dV/dt)', 'FontSize', 14);
      end
      % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
      yLimits = get(app.velAxes, ['Y' 'Lim']);       % axis() can be very slow sometimes
      hold(app.velAxes, 'on');
      title(app.velAxes, 'Most recent velocity trace', 'fontSize', 12, 'fontWeight', 'bold')
      plot(app.velAxes, [app.targetTimeS, app.targetTimeS] * 1000, yLimits, 'k-.');
      if (app.fixOffTimeS ~= app.targetTimeS)
        plot(app.velAxes, [app.fixOffTimeS, app.fixOffTimeS] * 1000, yLimits, 'r-.');
      end
      if (startIndex > 0)                                         % plot the saccade start and end
        plot(app.velAxes, [startIndex, startIndex] * timestepMS, yLimits, 'b:');
        if (endIndex > 0)
          plot(app.velAxes, [endIndex, endIndex] * timestepMS, yLimits, 'b:');
        end
      end
      hold(app.velAxes, 'off');
    end
  end
end
