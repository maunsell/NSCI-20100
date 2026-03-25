classdef OPlots < handle
    % OPlots
    % Support for plotting of spike waveforms in Oscilloscope
    
    properties
      contThresholdLine
      lastThresholdV = NaN    % last threshold value displayed
      samplesPlotted
      singleSpike
      singleSpikeDisplayed
      triggerDivisions
      triggerFraction
      triggerSamples
      triggerThresholdLine
      triggerTraceDurS
      vContAxes
      vTrigAxes
    end
    
    methods
         %% Object Initialization %%
        function obj = OPlots(app)
            obj = obj@handle();                                            % object initialization
            % continuous plot
            obj.samplesPlotted = 0;
            obj.vContAxes = app.axes1;
            obj.vContAxes.XGrid = 'on';
            obj.vContAxes.YGrid = 'on';
            clearContPlot(obj, app);
            % triggered plot
            obj.vTrigAxes = app.axes2;
            obj.vTrigAxes.XGrid = 'on';
            obj.vTrigAxes.YGrid = 'on';
            obj.singleSpike = false;
            obj.singleSpikeDisplayed = false;
            obj.triggerDivisions = 10;
            obj.triggerFraction = 0.20;
            obj.triggerTraceDurS = 0.020;
            obj.triggerSamples = floor(obj.triggerTraceDurS * app.lbj.SampleRateHz);
            
            clearTriggerPlot(obj, app);
        end
        
        %% clearAll -- clear all plots 
        function clearAll(obj, app)
            clearContPlot(obj, app);
            clearTriggerPlot(obj, app);
        end
        
        %% clearContPlot -- clear the continuous trace plot
        function clearContPlot(obj, app)
            obj.samplesPlotted = 0;
            maxV = app.vPerDiv * app.vDivs / 2;
            vLimit = app.vDivs / 2 * app.vPerDiv;
            yTickLabels = cell(app.vDivs, 1);
            for t = 1:app.vDivs + 1
                yTickLabels{t} = sprintf('%.1f', (t - app.vDivs/2 - 1) * app.vPerDiv);
            end
            hold(obj.vContAxes, 'off');
            cla(obj.vContAxes);
            axis(obj.vContAxes, [0, app.contSamples, -maxV, maxV]);
            % x axis setup
            samplePerDiv = app.contMSPerDiv / 1000.0 * app.sampleRateHz;
            xticks(obj.vContAxes, 0:samplePerDiv:app.contTimeDivs * samplePerDiv);
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
            xticklabels(obj.vContAxes, xTickLabels);
            if app.contMSPerDiv <= 50
                xlabel(obj.vContAxes, 'Time (ms)', 'FontSize', 14,'FontWeight','Bold');
            else
                xlabel(obj.vContAxes, 'Time (s)' ,'FontSize', 14,'FontWeight','Bold');
            end
            % y axis
            yticks(obj.vContAxes, -vLimit:app.vPerDiv:vLimit);
            yticklabels(obj.vContAxes, yTickLabels);
            ylabel(obj.vContAxes, 'Analog Input (V)','FontSize', 14, 'FontWeight','Bold');

            % Create (or recreate) the threshold line spanning the whole sweep
            obj.contThresholdLine = plot(obj.vContAxes, [1, app.contSamples], app.thresholdV * [1 1], 'r');
            hold(obj.vContAxes, 'on');
        end
                
        %% clearTriggerPlot -- clear the continuous trace plot
        function clearTriggerPlot(obj, app)
            theAxes = obj.vTrigAxes;
            % set up the triggered spike plot
            triggerMSPerDiv = obj.triggerTraceDurS * 1000.0 / obj.triggerDivisions;
            samplesPerDiv = triggerMSPerDiv / 1000.0 * app.sampleRateHz;
            triggerSample = obj.triggerSamples * obj.triggerFraction + 1;
            triggerSampleOffset = mod(triggerSample - 1, samplesPerDiv);
            negTriggerDivisions = floor(obj.triggerDivisions * obj.triggerFraction) + 1;
            cla(theAxes);
            hold(theAxes, 'off');
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
            obj.triggerThresholdLine = plot(obj.vTrigAxes, [1 obj.triggerSamples], app.thresholdV * [1 1], 'r');      
            hold(theAxes, 'on');
            axis(theAxes, [1, floor(obj.triggerSamples / 2) * 2 + 1, -maxV, maxV]);
            plot(theAxes, [triggerSample, triggerSample], [-maxV, maxV], 'k:');
            obj.singleSpikeDisplayed = false;
        end
  
        %% plot the continuous and triggered spike waveforms
        function doPlots(obj, app)
            % continuous trace
            startIndex = max(1, obj.samplesPlotted + 1);  	% start from previous plotted point
            endIndex = min(length(app.rawData), app.samplesRead);
            plot(obj.vContAxes, startIndex:endIndex, app.filteredTrace(startIndex:endIndex), 'b');
            obj.samplesPlotted = endIndex;
            if obj.singleSpike && obj.singleSpikeDisplayed        % in single spike mode and already displayed?
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
                    obj.singleSpikeDisplayed = true;
                end
                plot(obj.vTrigAxes, 1:obj.triggerSamples, app.filteredTrace(startIndex:endIndex), 'b');
                if obj.singleSpike
                    app.spikeIndices = [];                 % single spike, throw out any remaining
                else
                    app.spikeIndices(1) = [];              % delete this spike time
                end
            end
            drawnow limitrate nocallbacks;             	% don't plot too often, or notify callbacks
        end

        %% update the threshold voltage line if it has changed
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
