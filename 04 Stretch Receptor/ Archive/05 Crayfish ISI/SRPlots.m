classdef SRPlots < handle
  % SRPlots
  % Support for plotting of spike waveforms in StretchReceptor
  
  properties
    lastThresholdXPlotted
    samplesPlotted
    singleSpikeDisplayed
    triggerDivisions
    triggerFraction
    triggerSamples
    triggerTraceDurS
  end
  
  methods
    %% Object Initialization %%
    function obj = SRPlots(app)
      obj = obj@handle();                                            % object initialization
      obj.samplesPlotted = 0;
      obj.lastThresholdXPlotted = 0;
%       obj.singleSpike = false;
      obj.singleSpikeDisplayed = false;
      obj.triggerDivisions = 10;
      obj.triggerFraction = 0.20;
      obj.triggerTraceDurS = 0.020;
      obj.triggerSamples = floor(obj.triggerTraceDurS * app.lbj.SampleRateHz);
      clearAll(obj, app);
    end
    
    %% clearAll -- clear all plots
    function clearAll(obj, app)
      clearContPlot(obj, app);
      clearTriggerPlot(obj, app);
    end
    
    %% clearContPlot -- clear the continuous trace plot
    function clearContPlot(obj, app)
      obj.samplesPlotted = 0;
      obj.lastThresholdXPlotted = 0;
      maxV = app.vPerDiv * app.vDivs / 2;
      vLimit = app.vDivs / 2 * app.vPerDiv;
      yTickLabels = cell(app.vDivs, 1);
      for t = 1:app.vDivs + 1
        yTickLabels{t} = sprintf('%.1f', (t - app.vDivs/2 - 1) * app.vPerDiv);
      end
      hold(app.vContAxes, 'off');
      cla(app.vContAxes);
      axis(app.vContAxes, [0, app.contSamples, -maxV, maxV]);
      % x axis setup
      samplePerDiv = app.contMSPerDiv / 1000.0 * app.lbj.SampleRateHz;
      xticks(app.vContAxes, 0:samplePerDiv:app.contTimeDivs * samplePerDiv);
      xTickLabels = cell(app.contTimeDivs, 1);
      for t = 1:app.contTimeDivs + 1
        if mod(t, 2)
          if app.contMSPerDiv <= 50
            xTickLabels{t} = sprintf('%.0f', (t-1) * app.contMSPerDiv);
          else
            xTickLabels{t} = sprintf('%.1f', (t-1) * app.contMSPerDiv / 1000.0);
          end
        end
      end
      xticklabels(app.vContAxes, xTickLabels);
      if app.contMSPerDiv <= 50
        xlabel(app.vContAxes, 'Time (ms)', 'FontSize', 14,'FontWeight','Bold');
      else
        xlabel(app.vContAxes, 'Time (s)' ,'FontSize', 14,'FontWeight','Bold');
      end
      % y axis
      yticks(app.vContAxes, -vLimit:app.vPerDiv:vLimit);
      yticklabels(app.vContAxes, yTickLabels);
      ylabel(app.vContAxes, 'Analog Input (V)','FontSize', 14, 'FontWeight','Bold');
      hold(app.vContAxes, 'on');
    end
    
    %% clearTriggerPlot -- clear the continuous trace plot
    function clearTriggerPlot(obj, app)
      fprintf('clearTriggerPlot\n');
      theAxes = app.vTrigAxes;
      % set up the triggered spike plot
      triggerMSPerDiv = obj.triggerTraceDurS * 1000.0 / obj.triggerDivisions;
      samplesPerDiv = triggerMSPerDiv / 1000.0 * app.lbj.SampleRateHz;
      triggerSample = obj.triggerSamples * obj.triggerFraction + 1;
      triggerSampleOffset = mod(triggerSample - 1, samplesPerDiv);
      negTriggerDivisions = floor(obj.triggerDivisions * obj.triggerFraction) + 1;
      cla(theAxes);
      xticks(theAxes, 1:samplesPerDiv:floor(obj.triggerSamples / 2) * 2 + 1 + triggerSampleOffset);
      theAxes.XGrid = 'on';
      xTickLabels = cell(obj.triggerDivisions, 1);
      for t = 1:obj.triggerDivisions + 1
        if mod(t, 2)
          xTickLabels{t} = sprintf('%.0f', (t - negTriggerDivisions) * triggerMSPerDiv);
        end
      end
      xticklabels(theAxes, xTickLabels);
      xlabel(theAxes, 'Time (ms)', 'fontsize', 14, 'fontWeight', 'bold');
      % y axis
      maxV = app.vPerDiv * app.vDivs / 2;
      vLimit = app.vDivs / 2 * app.vPerDiv;
      yTickLabels = cell(app.vDivs, 1);
      for t = 1:app.vDivs + 1
        yTickLabels{t} = sprintf('%.1f', (t - app.vDivs/2 - 1) * app.vPerDiv);
      end
      yticks(theAxes, -vLimit:app.vPerDiv:vLimit);
      yticklabels(theAxes, yTickLabels);
      theAxes.YGrid = 'on';
      ylabel(theAxes, 'Analog Input (V)', 'fontSize', 14, 'fontWeight', 'bold');
      hold(theAxes, 'on');
      axis(theAxes, [1, floor(obj.triggerSamples / 2) * 2 + 1, -maxV, maxV]);
      plot(theAxes, [triggerSample, triggerSample], [-maxV, maxV], 'k:');
      obj.singleSpikeDisplayed = false;
    end
    
    %% plot the continuous and triggered spike waveforms
    function doPlot(obj, app)
      dirty = false;
      % continuous trace
      startIndex = max(1, obj.samplesPlotted + 1);  	% start from previous plotted point
      endIndex = min(length(app.rawTrace), app.samplesRead);
      % save some CPU time by not plotting the treshold line every time
      if endIndex >= app.contSamples || endIndex - obj.lastThresholdXPlotted > app.lbj.SampleRateHz / 10
        plot(app.vContAxes, [obj.lastThresholdXPlotted, endIndex], [app.thresholdV, app.thresholdV], ...
          'color', [1.0, 0.25, 0.25]);
        obj.lastThresholdXPlotted = endIndex;
        plot(app.vContAxes, startIndex:endIndex, app.filteredTrace(startIndex:endIndex), 'b');
        obj.samplesPlotted = endIndex;
        dirty = true;
      end
      % triggered spikes
      if app.singleSpikeCheckbox.Value && obj.singleSpikeDisplayed	% in single spike mode and already displayed?
        app.spikeIndices = [];                             %   then don't plot the spikes
        return;
      end
      while ~isempty(app.spikeIndices)
        spikeIndex = app.spikeIndices(1);
        startIndex = floor(spikeIndex - obj.triggerSamples * obj.triggerFraction);
        endIndex = startIndex + obj.triggerSamples - 1;
        if startIndex < 1 || endIndex > app.contSamples  % spike too close to sweep ends, skip it
          app.spikeIndices(1) = [];
          continue;
        end
        if endIndex > app.samplesRead              % haven't read all the samples yet, wait for next pass
          break;
        end
        if ~obj.singleSpikeDisplayed
          plot(app.vTrigAxes, [1, obj.triggerSamples], [app.thresholdV, app.thresholdV], 'color', ...
            [1.0, 0.25, 0.25]);
          obj.singleSpikeDisplayed = true;
        end
        plot(app.vTrigAxes, 1:obj.triggerSamples, app.filteredTrace(startIndex:endIndex), 'b');
        dirty = true;
        if app.singleSpikeCheckbox.Value
          app.spikeIndices = [];                 % single spike, throw out any remaining
        else
          app.spikeIndices(1) = [];              % delete this spike time
        end
      end
      if dirty
        drawnow limitrate nocallbacks;             	% don't plot too often, or notify callbacks
      end
    end
    
  end
  
end
