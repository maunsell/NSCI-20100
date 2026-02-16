classdef SRSpikePlots < handle
  % SRPlots
  % Support for plotting of spike waveforms in StretchReceptor
  
  properties
    clearingTrig
    contThresholdLine
    contSnippets
    lastThresholdV = NaN    % last threshold value displayed
    samplesPlotted          % number of samples plotted in the continuous plot
    singleSpikeDisplayed
    triggerDivisions        % number of horizontal division in the triggered plot
    triggerFraction
    triggerSamples          % number of samples displayed in the triggered plot
    triggerSnippets
    triggerSpikeCount       % number of trigger spikes displayed
    triggerSpikeCountText   % text handle inside vTrigAxes
    triggerThresholdLine
    triggerTraceDurS
  end
  
  methods
    % Object Initialization %%
    function obj = SRSpikePlots(app)
      obj = obj@handle();                                            % object initialization
      obj.clearingTrig = false;
      obj.samplesPlotted = 0;
      obj.singleSpikeDisplayed = false;
      obj.triggerDivisions = 10;
      obj.triggerFraction = 0.20;
      obj.triggerTraceDurS = 0.020;
      obj.triggerSpikeCount = 0;
      obj.triggerSpikeCountText = gobjects(1);
      obj.triggerSamples = floor(obj.triggerTraceDurS * app.lbj.SampleRateHz);
      app.vTrigAxes.XGrid = 'on';
      app.vTrigAxes.YGrid = 'on';
      obj.contSnippets = plotSnippets(app, app.vContAxes, 'b');
      obj.triggerSnippets = plotSnippets(app, app.vTrigAxes, 'b');
      clearAll(obj, app);
    end
    
    % clearAll -- clear all plots
    function clearAll(obj, app)
      clearContPlot(obj, app);
      clearTriggerPlot(obj, app);
    end
    
    % clearContPlot -- clear the continuous trace plot
    function clearContPlot(obj, app)
      obj.samplesPlotted = 0;
      maxV = app.vPerDiv * app.vDivs / 2;
      vLimit = app.vDivs / 2 * app.vPerDiv;
      yTickLabels = cell(app.vDivs, 1);
      for t = 1:app.vDivs + 1
        yTickLabels{t} = sprintf('%.1f', (t - app.vDivs/2 - 1) * app.vPerDiv);
      end
      cla(app.vContAxes);
      hold(app.vContAxes, 'off');
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
      ylabel(app.vContAxes, 'Voltage (V)','FontSize', 14, 'FontWeight','Bold');
      hold(app.vContAxes, 'on');
      % Create (or recreate) the threshold line spanning the whole sweep
      obj.contThresholdLine = plot(app.vContAxes, [1, app.contSamples], app.thresholdV*[1 1], 'r');

      % We must remake new snippets every time we clear because the old
      % ones get deleted.  They must be made after we set hold on
      makeSnippets(obj.contSnippets, app, 100);
    end
    
    % clearTriggerPlot -- clear the continuous trace plot
    function clearTriggerPlot(obj, app)
      if obj.clearingTrig               % can't access handles during clear
        return;
      end
      obj.clearingTrig = true;
      theAxes = app.vTrigAxes;
      % set up the triggered spike plot
      triggerMSPerDiv = obj.triggerTraceDurS * 1000.0 / obj.triggerDivisions;
      samplesPerDiv = triggerMSPerDiv / 1000.0 * app.lbj.SampleRateHz;
      triggerSample = obj.triggerSamples * obj.triggerFraction + 1;
      triggerSampleOffset = mod(triggerSample - 1, samplesPerDiv);
      negTriggerDivisions = floor(obj.triggerDivisions * obj.triggerFraction) + 1;
      cla(theAxes);
      hold(theAxes, 'off');
      xticks(theAxes, 1:samplesPerDiv:floor(obj.triggerSamples / 2) * 2 + 1 + triggerSampleOffset);
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
      ylabel(theAxes, 'Voltage (V)', 'fontSize', 14, 'fontWeight', 'bold');
      hold(theAxes, 'on');
      axis(theAxes, [1, floor(obj.triggerSamples / 2) * 2 + 1, -maxV, maxV]);
      plot(theAxes, [triggerSample, triggerSample], [-maxV, maxV], 'k:');
      makeSnippets(obj.triggerSnippets, app, 100);
      obj.triggerSpikeCount = 0;            % reset spike count for this sweep
      % Create on-axes text for spike count (cla deletes it, so recreate once per sweep)
      obj.triggerSpikeCountText = text(theAxes, 0.975, 0.025, '0 spikes superimposed', ...
          'Units','normalized', 'HorizontalAlignment','right', 'VerticalAlignment','bottom', ...
          'FontSize', 12, 'FontWeight','bold', 'Color',[0 0 0], 'BackgroundColor',[1 1 1], 'Margin', 2, ...
          'Interpreter','none', 'HitTest','off', 'PickableParts','none', 'Clipping','off');
      obj.triggerThresholdLine = plot(app.vTrigAxes, [1 obj.triggerSamples], app.thresholdV * [1 1], 'r');      
      obj.singleSpikeDisplayed = false;
      obj.clearingTrig = false;
    end

    % plot the continuous spike waveforms
    function doContPlot(obj, app, overRun)
      if overRun <= 0                               % no overrun, set end of plotting
        endIndex = app.samplesRead;
      else
        if ~app.stopAtTraceEnd                      % no request to stop, clear snippets for next plot
          clearSnippets(obj.contSnippets, app);
          clearSnippets(obj.triggerSnippets, app);
          obj.samplesPlotted = 0;
          obj.triggerSpikeCount = 0;
          obj.triggerSpikeCountText.String = "";
          return;
        else                                        % request to stop, plot out to end of trace
          endIndex = app.contSamples;
        end
      end
      startIndex = max(1, obj.samplesPlotted + 1);  	% start from previous plotted point
      if startIndex >= endIndex
        return;
      end
      set(nextSnippet(obj.contSnippets, app), 'XData', startIndex:endIndex, ...
                'YData', app.filteredTrace(startIndex:endIndex));
      obj.samplesPlotted = endIndex;
    end

    % plot the triggered spike waveforms
    function doTriggerPlot(obj, app)
      if obj.clearingTrig               % can't access handles during clear
        return;
      end
      if app.singleSpikeCheckbox.Value && obj.singleSpikeDisplayed	% in single spike mode and already displayed?
        app.spikeIndices = [];                                      %   then don't plot the spikes
        return;
      end
      newSpikesAdded = 0;
      while ~isempty(app.spikeIndices)
        spikeIndex = app.spikeIndices(1);
        startIndex = floor(spikeIndex - obj.triggerSamples * obj.triggerFraction);
        endIndex = startIndex + obj.triggerSamples - 1;
        if startIndex < 1 || endIndex > app.contSamples             % spike too close to sweep ends, skip it
          app.spikeIndices(1) = [];
          continue;
        end
        if endIndex > app.samplesRead                               % haven't read all the samples yet
          break;
        end
        if ~obj.singleSpikeDisplayed
          % set(obj.triggerThresholdLine, 'XData', [1, obj.triggerSamples], 'YData', app.thresholdV * [1, 1]);
          obj.singleSpikeDisplayed = true;
        end
        set(nextSnippet(obj.triggerSnippets, app), 'XData', 1:obj.triggerSamples, ...
                'YData', app.filteredTrace(startIndex:endIndex));
        newSpikesAdded = newSpikesAdded + 1;
        if app.singleSpikeCheckbox.Value
          app.spikeIndices = [];                                    % single spike, throw out any remaining
        else
          app.spikeIndices(1) = [];                                 % delete this spike time
        end
      end
      if newSpikesAdded > 0
          obj.triggerSpikeCount = obj.triggerSpikeCount + newSpikesAdded;
          if isgraphics(obj.triggerSpikeCountText)
              obj.triggerSpikeCountText.String = ...
                  sprintf('%3.d spikes superimposed', obj.triggerSpikeCount);
          end
      end
    end

    function updateThresholdIfNeeded(obj, app)
      thr = app.thresholdV;
      if isequal(thr, obj.lastThresholdV)           % Only draw if the value changed (or we've never drawn it)
        return;
      end
      obj.lastThresholdV = thr;
      if isgraphics(obj.contThresholdLine)          % Continuous plot (full-width line)
        obj.contThresholdLine.YData = thr * [1 1];
      end
      if isgraphics(obj.triggerThresholdLine)       % Trigger plot (line across trigger samples)
        obj.triggerThresholdLine.YData = thr * [1 1];
      end
    end
  end 
end
