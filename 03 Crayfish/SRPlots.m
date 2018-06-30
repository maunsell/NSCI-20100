classdef SRPlots < handle
    % SRPlots
    %   Support for plotting in StretchReceptor
    
    properties
        lastThresholdXPlotted
        vContAxes
        vTrigAxes
    end
    
    methods
         %% Object Initialization %%
        function obj = SRPlots(handles)
            obj = obj@handle();                                            % object initialization
            % continuous plot
            obj.vContAxes = handles.axes1;
            obj.vContAxes.XGrid = 'on';
            obj.vContAxes.YGrid = 'on';
            clearContPlot(obj, handles);
            % triggered plot
            obj.vTrigAxes = handles.axes2;
            obj.vTrigAxes.XGrid = 'on';
            obj.vTrigAxes.YGrid = 'on';
            obj.lastThresholdXPlotted = 0;
            clearSpikePlot(obj, handles);
        end
        
        %% clearAll -- clear all plots 
        function clearAll(obj, handles)
            clearContPlot(obj, handles);
            clearSpikePlot(obj, handles);
        end
        
        %% clearContPlot -- clear the continuous trace plot
        function clearContPlot(obj, handles)
            data = handles.data;
            data.samplesPlotted = 0;
            obj.lastThresholdXPlotted = 0;
            maxV = data.vPerDiv * data.vDivs / 2;
            vLimit = data.vDivs / 2 * data.vPerDiv;
            yTickLabels = cell(data.vDivs, 1);
            for t = 1:data.vDivs + 1
                yTickLabels{t} = sprintf('%.1f', (t - data.vDivs/2 - 1) * data.vPerDiv);
            end
            hold(obj.vContAxes, 'off');
            cla(obj.vContAxes);
            axis(obj.vContAxes, [0, data.contSamples, -maxV, maxV]);
            % x axis setup
            samplePerDiv = data.contMSPerDiv / 1000.0 * data.sampleRateHz;
            xticks(obj.vContAxes, 0:samplePerDiv:data.contTimeDivs * samplePerDiv);
            xTickLabels = cell(data.contTimeDivs, 1);
            for t = 1:data.contTimeDivs + 1
                if mod(t, 2)
                    if data.contMSPerDiv <= 50
                        xTickLabels{t} = sprintf('%.0f', (t-1) * data.contMSPerDiv);
                    else
                        xTickLabels{t} = sprintf('%.1f', (t-1) * data.contMSPerDiv / 1000.0);
                    end
                end
            end
            xticklabels(obj.vContAxes, xTickLabels);
            if data.contMSPerDiv <= 50
                xlabel(obj.vContAxes, 'Time (ms)', 'FontSize', 14,'FontWeight','Bold');
            else
                xlabel(obj.vContAxes, 'Time (s)' ,'FontSize', 14,'FontWeight','Bold');
            end
            % y axis
            yticks(obj.vContAxes, -vLimit:data.vPerDiv:vLimit);
            yticklabels(obj.vContAxes, yTickLabels);
%             obj.vContAxes.YGrid = 'on';
            ylabel(obj.vContAxes, 'Analog Input (V)','FontSize', 14, 'FontWeight','Bold');
            hold(obj.vContAxes, 'on');
        end
                
        %% clearSpikePlot -- clear the continuous trace plot
        function clearSpikePlot(obj, handles)
            data = handles.data;
            maxV = data.vPerDiv * data.vDivs / 2;
            vLimit = data.vDivs / 2 * data.vPerDiv;
            yTickLabels = cell(data.vDivs, 1);
            for t = 1:data.vDivs + 1
                yTickLabels{t} = sprintf('%.1f', (t - data.vDivs/2 - 1) * data.vPerDiv);
            end
            % set up the triggered spike plot
            spikeMSPerDiv = data.spikeTraceDurS * 1000.0 / data.spikeDivisions;
            samplesPerDiv = spikeMSPerDiv / 1000.0 * data.sampleRateHz;
            hold(obj.vTrigAxes, 'off');
            cla(obj.vTrigAxes);
            xticks(obj.vTrigAxes, 1:samplesPerDiv:floor(data.spikeSamples / 2) * 2 + 1);
            obj.vTrigAxes.XGrid = 'on';
            xTickLabels = cell(data.spikeDivisions, 1);
            for t = 1:data.spikeDivisions + 1
                if mod(t, 2)
                    xTickLabels{t} = sprintf('%.0f', (t-1) * spikeMSPerDiv);
                end
            end
            xticklabels(obj.vTrigAxes, xTickLabels);
            xlabel(obj.vTrigAxes, 'Time (ms)', 'fontsize', 14, 'fontWeight', 'bold');
            % y axis
            yticks(obj.vTrigAxes, -vLimit:data.vPerDiv:vLimit);
            yticklabels(obj.vTrigAxes, yTickLabels);
            obj.vTrigAxes.YGrid = 'on';
            ylabel(obj.vTrigAxes, 'Analog Input (V)','FontSize', 14, 'FontWeight','Bold');            
            hold(obj.vTrigAxes, 'on');
            axis(obj.vTrigAxes, [1, floor(data.spikeSamples / 2) * 2 + 1, -maxV, maxV]);
            a = axis(obj.vTrigAxes);
            plot(obj.vTrigAxes, [data.spikeSamples / 4, data.spikeSamples / 4], [a(3), a(4)], 'k:');
            handles.data.singleSpikeDisplayed = false;
        end
  
        %% plot the oscilloscope trace and individual spikes
        function plot(obj, handles)
            dirty = false;
            data = handles.data;
            % continuous trace
            startIndex = max(1, data.samplesPlotted + 1);  	% start from previous plotted point
            endIndex = min(length(data.rawTrace), data.samplesRead);
            % save some CPU time by not plotting the treshold line every time
            if endIndex >= data.contSamples || endIndex - obj.lastThresholdXPlotted > data.sampleRateHz / 10
                plot(obj.vContAxes, [obj.lastThresholdXPlotted, endIndex], [data.thresholdV, data.thresholdV], ...
                    'color', [0.75, 0.75, 0.75]);
                obj.lastThresholdXPlotted = endIndex;
                plot(obj.vContAxes, startIndex:endIndex, data.filteredTrace(startIndex:endIndex), 'b');
                data.samplesPlotted = endIndex;
                dirty = true;
            end
%             plot(obj.vContAxes, startIndex:endIndex, data.rawTrace(startIndex:endIndex), 'r');
            % triggered spikes
            if data.singleSpike && data.singleSpikeDisplayed % in single spike mode and already displayed?
                data.spikeIndices = [];
                return;
            end
            while ~isempty(data.spikeIndices)
                spikeIndex = data.spikeIndices(1);
                startIndex = floor(spikeIndex - data.spikeSamples / 4);
                endIndex = startIndex + data.spikeSamples - 1;
                if startIndex < 1 || endIndex > data.contSamples  % spike too close to sweep ends, skip it
                    data.spikeIndices(1) = [];
                    continue;
                end
                if endIndex > data.samplesRead              % haven't read all the samples yet, wait for next pass
                    break;
                end
                if ~data.singleSpikeDisplayed
                    plot(obj.vTrigAxes, [1, data.spikeSamples], [data.thresholdV, data.thresholdV], ...
                        'color', [0.75, 0.75, 0.75]);
                    data.singleSpikeDisplayed = true;
                end
                plot(obj.vTrigAxes, 1:data.spikeSamples, data.filteredTrace(startIndex:endIndex), 'b');
                dirty = true;
                if data.singleSpike
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
