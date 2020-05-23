classdef OPlots < handle
    % OPlots
    % Support for plotting of spike waveforms in Oscilloscope
    
    properties
        lastThresholdXPlotted
        samplesPlotted
        singleSpike
        singleSpikeDisplayed
        triggerDivisions
        triggerFraction
        triggerSamples
        triggerTraceDurS
        vContAxes
        vTrigAxes
    end
    
    methods
         %% Object Initialization %%
        function obj = OPlots(handles, app)
            obj = obj@handle();                                            % object initialization
            % continuous plot
            obj.samplesPlotted = 0;
            obj.vContAxes = handles.axes1;
            obj.vContAxes.XGrid = 'on';
            obj.vContAxes.YGrid = 'on';
            clearContPlot(obj, app, handles);
            % triggered plot
            obj.vTrigAxes = handles.axes2;
            obj.vTrigAxes.XGrid = 'on';
            obj.vTrigAxes.YGrid = 'on';
            obj.lastThresholdXPlotted = 0;
            obj.singleSpike = false;
            obj.singleSpikeDisplayed = false;
            obj.triggerDivisions = 10;
            obj.triggerFraction = 0.20;
            obj.triggerTraceDurS = 0.020;
            obj.triggerSamples = floor(obj.triggerTraceDurS * handles.lbj.SampleRateHz);
            
            clearTriggerPlot(obj, app, handles);
        end
        
        %% clearAll -- clear all plots 
        function clearAll(obj, app, handles)
            clearContPlot(obj, app, handles);
            clearTriggerPlot(obj, app, handles);
        end
        
        %% clearContPlot -- clear the continuous trace plot
        function clearContPlot(obj, app, handles)
            data = handles.data;
            obj.samplesPlotted = 0;
            obj.lastThresholdXPlotted = 0;
            maxV = data.vPerDiv * data.vDivs / 2;
            vLimit = data.vDivs / 2 * data.vPerDiv;
            yTickLabels = cell(data.vDivs, 1);
            for t = 1:data.vDivs + 1
                yTickLabels{t} = sprintf('%.1f', (t - data.vDivs/2 - 1) * data.vPerDiv);
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
            yticks(obj.vContAxes, -vLimit:data.vPerDiv:vLimit);
            yticklabels(obj.vContAxes, yTickLabels);
            ylabel(obj.vContAxes, 'Analog Input (V)','FontSize', 14, 'FontWeight','Bold');
            hold(obj.vContAxes, 'on');
        end
                
        %% clearTriggerPlot -- clear the continuous trace plot
        function clearTriggerPlot(obj, app, handles)
            data = handles.data;
            theAxes = obj.vTrigAxes;
            % set up the triggered spike plot
            triggerMSPerDiv = obj.triggerTraceDurS * 1000.0 / obj.triggerDivisions;
            samplesPerDiv = triggerMSPerDiv / 1000.0 * app.sampleRateHz;
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
            maxV = data.vPerDiv * data.vDivs / 2;
            vLimit = data.vDivs / 2 * data.vPerDiv;
            yTickLabels = cell(data.vDivs, 1);
            for t = 1:data.vDivs + 1
                yTickLabels{t} = sprintf('%.1f', (t - data.vDivs/2 - 1) * data.vPerDiv);
            end
            yticks(theAxes, -vLimit:data.vPerDiv:vLimit);
            yticklabels(theAxes, yTickLabels);
            theAxes.YGrid = 'on';
            ylabel(theAxes, 'Analog Input (V)', 'fontSize', 14, 'fontWeight', 'bold');            
            hold(theAxes, 'on');
            axis(theAxes, [1, floor(obj.triggerSamples / 2) * 2 + 1, -maxV, maxV]);
            plot(theAxes, [triggerSample, triggerSample], [-maxV, maxV], 'k:');
            obj.singleSpikeDisplayed = false;
        end
  
        %% plot the continuous and triggered spike waveforms
        function plot(obj, app, handles)
            dirty = false;
            data = handles.data;
            % continuous trace
            startIndex = max(1, obj.samplesPlotted + 1);  	% start from previous plotted point
            endIndex = min(length(data.rawTrace), app.samplesRead);
            % save some CPU time by not plotting the treshold line every time
            if endIndex >= app.contSamples || endIndex - obj.lastThresholdXPlotted > app.sampleRateHz / 10
                plot(obj.vContAxes, [obj.lastThresholdXPlotted, endIndex], [data.thresholdV, data.thresholdV], ...
                    'color', [1.0, 0.25, 0.25]);
                obj.lastThresholdXPlotted = endIndex;
                plot(obj.vContAxes, startIndex:endIndex, data.filteredTrace(startIndex:endIndex), 'b');
                obj.samplesPlotted = endIndex;
                dirty = true;
            end
            % triggered spikes
            if obj.singleSpike && obj.singleSpikeDisplayed        % in single spike mode and already displayed?
                data.spikeIndices = [];                             %   then don't plot the spikes
                return;
            end
            while ~isempty(data.spikeIndices)
                spikeIndex = data.spikeIndices(1);
                startIndex = floor(spikeIndex - obj.triggerSamples * obj.triggerFraction);
                endIndex = startIndex + obj.triggerSamples - 1;
                if startIndex < 1 || endIndex > app.contSamples  % spike too close to sweep ends, skip it
                    data.spikeIndices(1) = [];
                    continue;
                end
                if endIndex > app.samplesRead              % haven't read all the samples yet, wait for next pass
                    break;
                end
                if ~obj.singleSpikeDisplayed
                    plot(obj.vTrigAxes, [1, obj.triggerSamples], [data.thresholdV, data.thresholdV], 'color', ...
                        [1.0, 0.25, 0.25]);
                    obj.singleSpikeDisplayed = true;
                end
                plot(obj.vTrigAxes, 1:obj.triggerSamples, data.filteredTrace(startIndex:endIndex), 'b');
                dirty = true;
                if obj.singleSpike
                    data.spikeIndices = [];                 % single spike, throw out any remaining
                else
                    data.spikeIndices(1) = [];              % delete this spike time
                end
            end
            if dirty
                drawnow limitrate nocallbacks;             	% don't plot too often, or notify callbacks
            end
        end
        
    end
    
end
