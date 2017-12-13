classdef EOGPosVelPlots < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
        posAvgAxes
        posAxes
        velAvgAxes
        velAxes
    end
    
    methods
        function obj = EOGPosVelPlots(handles)
             %% Object Initialization %%
             obj = obj@handle();                                            % object initialization

             %% Post Initialization %%
            obj.posAvgAxes = handles.axes2;
            obj.posAxes = handles.axes1;
            obj.velAvgAxes = handles.axes4;
            obj.velAxes = handles.axes3;            
        end
            
        function plot(obj, handles, startIndex, endIndex)
        %EOGPlots Updata all plots for EOG
            posPlots(obj, handles, startIndex, endIndex)
            velPlots(obj, handles, startIndex, endIndex)
            drawnow;
        end

        %% posPlots: do the trial and average position plots
        function posPlots(obj, handles, startIndex, endIndex)

            data = handles.data;
            saccades = handles.saccades;

            timestepS = 1 / data.sampleRateHz;                            % time interval of samples
            trialTimes = (0:1:size(data.posTrace, 1) - 1) * timestepS;    % make array of trial time points
            saccadeTimes = (-(size(data.posAvg, 1) / 2):1:(size(data.posAvg,1) / 2) - 1) * timestepS;             
            colors = get(obj.posAxes, 'ColorOrder');

            % trial position trace
            cla(obj.posAxes);
            plot(obj.posAxes, trialTimes, data.posTrace, 'color', colors(data.offsetIndex,:));
            title(obj.posAxes, 'Most recent position trace', 'FontSize',12,'FontWeight','Bold')
            ylabel(obj.posAxes,'Analog Input (V)','FontSize',14);

            % average position traces
            cla(obj.posAvgAxes);
            plot(obj.posAvgAxes, saccadeTimes, data.posAvg, '-');
            title(obj.posAvgAxes, ['Average position traces (left/right combined; ' sprintf('n>=%d)', data.blocksDone)], ...
                          'FontSize',12,'FontWeight','Bold')

            % set both plots to the same y scale
            a1 = axis(obj.posAxes);
            a3 = axis(obj.posAvgAxes);
            yLim = max([abs(a1(3)), abs(a1(4)), abs(a3(3)), abs(a3(4))]);
            text(0.05 * a1(2), 0.8 * yLim, '1', 'parent', obj.posAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            text(-0.112, 0.8 * yLim, '2', 'parent', obj.posAvgAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            axis(obj.posAxes, [-inf inf -yLim yLim]);
            axis(obj.posAvgAxes, [-inf inf -yLim yLim]);

            % if a saccade was detected, mark its start (and end, if end was detected
            if (startIndex > 0)
                hold(obj.posAxes, 'on');
                plot(obj.posAxes, [startIndex, startIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
                    'linestyle', ':');
                if (endIndex > 0)
                    plot(obj.posAxes, [endIndex, endIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
                    'linestyle', ':');
                end
                hold(obj.posAxes, 'off');
            end

            % averages are always aligned on onset, so draw a vertical line at that point
            hold(obj.posAvgAxes, 'on');
            plot(obj.posAvgAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
            hold(obj.posAvgAxes, 'off');

            % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
            if saccades.degPerV > 0
                yTicks = [fliplr(-data.offsetsDeg), 0, data.offsetsDeg] / saccades.degPerV;
                for i = 1:length(yTicks)
                    yLabels{i} = num2str(yTicks(i) * saccades.degPerV, '%.0f');
                end
                set(obj.posAvgAxes, 'YTick', yTicks);
                set(obj.posAvgAxes, 'YTickLabel', yLabels);
                ylabel(obj.posAvgAxes,'Average Eye Position (absolute deg.)','FontSize',14);
            end
        end


        %% velPlots: do the trial and average velocity plots
        function velPlots(obj, handles, startIndex, endIndex)

            data = handles.data;
            saccades = handles.saccades;

            timestepS = 1 / data.sampleRateHz;                                       % time interval of samples
            trialTimes = (0:1:size(data.posTrace, 1) - 1) * timestepS;          % make array of trial time points
            saccadeTimes = (-(size(data.posAvg, 1) / 2):1:(size(data.posAvg,1) / 2) - 1) * timestepS;              
            colors = get(obj.velAxes, 'ColorOrder');

            % plot the trial velocity trace
            cla(obj.velAxes);
            plot(obj.velAxes, trialTimes, data.velTrace, 'color', colors(data.offsetIndex,:));
            a = axis(obj.velAxes);
            yLim = max(abs(a(3)), abs(a(4)));
            axis(obj.velAxes, [-inf inf -yLim yLim]);
            title(obj.velAxes, 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold');
            ylabel(obj.velAxes,'Analog Input (dV/dt)','FontSize',14);
            xlabel(obj.velAxes,'Time (s)','FontSize',14);

            % plot the average velcotiy traces
            cla(obj.velAvgAxes);
            plot(obj.velAvgAxes, saccadeTimes, data.velAvg, '-');
            title(obj.velAvgAxes, 'Average velocity traces (left/right combined)', 'FontSize',12,'FontWeight','Bold')
            ylabel(obj.velAvgAxes,'Analog Input (V)','FontSize',14);
            xlabel(obj.velAvgAxes,'Time (s)','FontSize',14);

            % put both plots on the same y scale
            a1 = axis(obj.velAxes);
            a2 = axis(obj.velAvgAxes);
            yLim = max([abs(a1(3)), abs(a1(4)), abs(a2(3)), abs(a2(4))]);
            text(0.025, 0.8 * yLim, '3', 'parent', obj.velAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            text(-0.112, 0.8 * yLim, '4', 'parent', obj.velAvgAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            axis(obj.velAxes, [-inf inf -yLim yLim]);
            axis(obj.velAvgAxes, [-inf inf -yLim yLim]);

            % if a saccade was detected, mark its start (and end, if end was detected
            if (startIndex > 0)
                hold(obj.velAxes, 'on');
                plot(obj.velAxes, [startIndex, startIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
                                                                                                     'linestyle', ':');
                if (endIndex > 0)
                    plot(obj.velAxes, [endIndex, endIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
                    'linestyle', ':');
                end
                hold(obj.velAxes, 'off');
            end

            % averages are always aligned on onset, so draw a vertical line at that point
            hold(obj.velAvgAxes, 'on');
            plot(obj.velAvgAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
            hold(obj.velAvgAxes, 'off');

            % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
            if saccades.degPerSPerV > 0
                maxSpeedDPS = ceil((yLim * saccades.degPerSPerV) / 100.0) * 100;
                yTicks = (-maxSpeedDPS:100:maxSpeedDPS) / saccades.degPerSPerV;
                for i = 1:length(yTicks)
                    yLabels{i} = num2str(yTicks(i) * saccades.degPerSPerV, '%.0f');
                end
                hold(obj.velAxes, 'on');

                %draw horizontal lines at +/-threshold for the trial velocity
                plot(obj.velAxes, [a(1) a(2)], [saccades.thresholdDPS saccades.thresholdDPS] ./ saccades.degPerSPerV,...
                        'color', colors(data.offsetIndex,:),'linestyle', ':');
                plot(obj.velAxes, [a(1) a(2)], -[saccades.thresholdDPS saccades.thresholdDPS] ./ saccades.degPerSPerV,...
                        'color', colors(data.offsetIndex,:),'linestyle', ':');
               hold(obj.velAxes, 'off');
                set(obj.velAxes, 'YTick', yTicks);
                set(obj.velAxes, 'YTickLabel', yLabels);
                ylabel(obj.velAxes,'Average Eye Speed (degrees/s)','FontSize',14);
                set(obj.velAvgAxes, 'YTick', yTicks);
                set(obj.velAvgAxes, 'YTickLabel', yLabels);
                ylabel(obj.velAvgAxes, 'Average Eye Speed (degrees/s)', 'FontSize', 14);

                % draw lines sowing the duration of the above-threshold part of the average traces.
                hold(obj.velAvgAxes, 'on');
                for i = 1:data.numOffsets
                    limitIndex = min(length(saccadeTimes), length(saccadeTimes) / 2 + data.saccadeDurS(i));
                    plot(obj.velAvgAxes, [0, saccadeTimes(limitIndex)], -[yLim, yLim] / 5 * i, 'color', colors(i,:));
                end
                hold(obj.velAvgAxes, 'off');
            end
        end
    end
end
