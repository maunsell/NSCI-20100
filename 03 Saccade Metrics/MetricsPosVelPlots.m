classdef MetricsPosVelPlots < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
        posAvgAxes
        posAxes
        velAvgAxes
        velAxes
    end
    
    methods
        function obj = MetricsPosVelPlots(app)
             %% Object Initialization %%
             obj = obj@handle();                                            % object initialization

             %% Post Initialization %%
            obj.posAvgAxes = app.avgPosAxes;
            obj.posAxes = app.posAxes;
            obj.velAvgAxes = app.avgVelAxes;
            obj.velAxes = app.velAxes;            
        end
            
        function plotPosVel(obj, handles, app, startIndex, endIndex, mustPlot)
        %doPlot Updata all plots for EOG
            mustPlot = mustPlot || (mod(sum(handles.data.numSummed), handles.data.numOffsets) == 0);
            posPlots(obj, handles, app, startIndex, endIndex, mustPlot);
            velPlots(obj, handles, app, startIndex, endIndex, mustPlot);
%             drawnow;
        end

        %% posPlots: do the trial and average position plots
        function posPlots(obj, handles, app, startIndex, endIndex, mustPlot)
            data = handles.data;
            saccades = handles.saccades;
            timestepMS = 1000.0 / data.sampleRateHz;                   	% time interval of samples
            trialTimes = (0:1:size(data.posTrace, 1) - 1) * timestepMS;	% make array of trial time points
            saccadeTimes = (-(size(data.posAvg, 1) / 2):1:(size(data.posAvg,1) / 2) - 1) * timestepMS;             
            colors = get(obj.posAxes, 'ColorOrder');
            % current trial position trace
            cla(obj.posAxes);
            plot(obj.posAxes, trialTimes, data.posTrace, 'color', colors(app.absStepIndex,:));
            if saccades.degPerV > 0                                     % plot saccade threshold
                hold(obj.posAxes, 'on');
                thresholdV = saccades.thresholdDeg / saccades.degPerV * data.stepSign;
                plot(obj.posAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], ...
                    ':', 'color', colors(app.absStepIndex,:));
                hold(obj.posAxes, 'off');
            end
            title(obj.posAxes, 'Most recent position trace', 'FontSize',12,'FontWeight','Bold')
            ylabel(obj.posAxes,'Analog Input (V)','FontSize',14);
            % average position traces every complete block
            if mustPlot
                cla(obj.posAvgAxes);
                if sum(data.numSummed) > 0
                    plot(obj.posAvgAxes, saccadeTimes, data.posAvg(:, 1:data.numOffsets / 2), '-');
                    hold(obj.posAvgAxes, 'on');
                    obj.posAvgAxes.ColorOrderIndex = 1;
                    plot(obj.posAvgAxes, saccadeTimes, data.posAvg(:, data.numOffsets / 2 + 1:data.numOffsets), '-');
                    hold(obj.posAvgAxes, 'off');
                    title(obj.posAvgAxes, sprintf('Average position traces (n\x2265%d)', app.blocksDone), ...
                        'FontSize',12,'FontWeight','Bold')
                    % set both plots to the same y scale
                    a3 = axis(obj.posAvgAxes);
                    yLim = max(abs(a3(3:4)));
%                     text(-112, 0.8 * yLim, '2', 'parent', obj.posAvgAxes, 'FontSize', 24, 'FontWeight', 'Bold');
                    axis(obj.posAvgAxes, [-inf inf -yLim yLim]);
                    hold(obj.posAvgAxes, 'on');
                    % averages are always aligned on onset, so draw a vertical line at that point
                    plot(obj.posAvgAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
                    for i = 1:length(data.saccadeDurS)          % draw saccade durations for average traces
                        plot(obj.posAvgAxes, [data.saccadeDurS(i) * 1000.0, data.saccadeDurS(i) * 1000.0], ...
                            [-yLim, yLim], ':', 'color', colors(mod(i - 1, data.numOffsets / 2) + 1, :));
                    end
                    hold(obj.posAvgAxes, 'off');
                    % if eye position has been calibrated, change the y scaling on the average to degrees 
                    % rather than volts
                    if saccades.degPerV > 0
                        yTicks = [fliplr(-data.offsetsDeg(1:data.numOffsets/2)), 0, ...
                                        data.offsetsDeg(1:data.numOffsets/2)] / saccades.degPerV;
                        yLabels = cell(length(yTicks), 1);
                        for i = 1:length(yTicks)
                            yLabels{i} = num2str(yTicks(i) * saccades.degPerV, '%.0f');
                        end
                        set(obj.posAvgAxes, 'YTick', yTicks);
                        set(obj.posAvgAxes, 'YTickLabel', yLabels);
                        ylabel(obj.posAvgAxes,'Avg Eye Position (deg)','FontSize',14);
                    end
                end
            end
            if sum(data.numSummed) > data.numOffsets
                a3 = axis(obj.posAvgAxes);                      % we don't plot the average on every pass
                yLim = max(abs(a3(3:4)));                       %   so pick up the scaling here
                axis(obj.posAxes, [-inf inf -yLim yLim]);       % scale pos plot to avgPos plot y-axis
            end
            a1 = axis(obj.posAxes);                             % label the pos plot "1"
%             text(trialTimes(1) + 0.05 * (trialTimes(end) - trialTimes(1)), ...
%                 a1(3) + 0.9 * (a1(4) - a1(3)), '1', 'parent', obj.posAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
            hold(obj.posAxes, 'on');
            plot(obj.posAxes, [data.stimTimeS * 1000.0, data.stimTimeS * 1000.0], [a1(3), a1(4)], 'k-.');
            if (startIndex > 0)
                plot(obj.posAxes, [startIndex, startIndex] * timestepMS, [a1(3), a1(4)], 'color', ...
                    colors(app.absStepIndex,:), 'linestyle', ':');
                if (endIndex > 0)
                    plot(obj.posAxes, [endIndex, endIndex] * timestepMS, [a1(3), a1(4)], 'color', ...
                    colors(app.absStepIndex,:), 'linestyle', ':');
                end
            end
            hold(obj.posAxes, 'off');
       end

        %% velPlots: do the trial and average velocity plots
        function velPlots(obj, handles, app, startIndex, endIndex, mustPlot)
            data = handles.data;
            saccades = handles.saccades;
            timestepMS = 1000.0 / data.sampleRateHz;                       	% time interval of samples
            trialTimes = (0:1:size(data.posTrace, 1) - 1) * timestepMS;     % make array of trial time points
            saccadeTimes = (-(size(data.posAvg, 1) / 2):1:(size(data.posAvg,1) / 2) - 1) * timestepMS;              
            colors = get(obj.velAxes, 'ColorOrder');
            % plot the trial velocity trace
            cla(obj.velAxes);
            plot(obj.velAxes, trialTimes, data.velTrace, 'color', colors(app.absStepIndex,:));
            a = axis(obj.velAxes);                                              % center vel plot vertically
            yLim = max(abs(a(3)), abs(a(4)));
            axis(obj.velAxes, [-inf inf -yLim yLim]);
            title(obj.velAxes, 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold');
            ylabel(obj.velAxes,'Analog Input (dV/dt)','FontSize',14);
            xlabel(obj.velAxes,'Time (ms)','FontSize',14);
            % plot the average velocity traces every time a set of step sizes is completed
            if mustPlot
                cla(obj.velAvgAxes);
                if sum(data.numSummed) > 0                  % make sure there is at least one set of steps
                    plot(obj.velAvgAxes, saccadeTimes, data.velAvg(:, 1:data.numOffsets / 2), '-');
                    hold(obj.velAvgAxes, 'on');
                    obj.velAvgAxes.ColorOrderIndex = 1;
                    plot(obj.velAvgAxes, saccadeTimes, data.velAvg(:, data.numOffsets / 2 + 1:data.numOffsets), '-');
                    hold(obj.velAvgAxes, 'off');
                    title(obj.velAvgAxes, sprintf('Average velocity traces (n\x2265%d)', app.blocksDone), ...
                            'fontSize', 12, 'fontWeight','Bold')
                    ylabel(obj.velAvgAxes,'Analog Input (dV/dt)', 'FontSize', 14);
                    xlabel(obj.velAvgAxes,'Time (ms)','FontSize', 14);
                    % put both plots on the same y scale
                    a1 = axis(obj.velAxes);
                    a2 = axis(obj.velAvgAxes);
                    yLim = max([abs(a1(3)), abs(a1(4)), abs(a2(3)), abs(a2(4))]);
%                     text(-112, 0.8 * yLim, '4', 'parent', obj.velAvgAxes, 'FontSize', 24, 'FontWeight', 'Bold');
                    axis(obj.velAxes, [-inf inf -yLim yLim]);
                    axis(obj.velAvgAxes, [-inf inf -yLim yLim]);
                    % averages are always aligned on onset, so draw a vertical line at that point
                    hold(obj.velAvgAxes, 'on');
                    plot(obj.velAvgAxes, [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
                    hold(obj.velAvgAxes, 'off');
               end
            end
            % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
            if saccades.degPerV > 0
                maxSpeedDPS = ceil((yLim * saccades.degPerSPerV) / 100.0) * 100;
                increment = 100;
                while maxSpeedDPS / increment > 5
                    increment = increment * 2;
                end
                yTicks = (-maxSpeedDPS:increment:maxSpeedDPS) / saccades.degPerSPerV;
                yLabels = cell(length(yTicks), 1);
                for i = 1:length(yTicks)
                    yLabels{i} = num2str(yTicks(i) * saccades.degPerSPerV, '%.0f');
                end
                set(obj.velAxes, 'YTick', yTicks);
                set(obj.velAxes, 'YTickLabel', yLabels);
                ylabel(obj.velAxes,'Avg Eye Speed (deg/s)','FontSize',14);
                if mustPlot
                    set(obj.velAvgAxes, 'YTick', yTicks);
                    set(obj.velAvgAxes, 'YTickLabel', yLabels);
                    ylabel(obj.velAvgAxes, 'Avg Eye Speed (deg/s)', 'FontSize', 14);
                end
            end
            a1 = axis(obj.velAxes);
%             text(trialTimes(1) + 0.05 * (trialTimes(end) - trialTimes(1)), ...
%                 a1(3) + 0.9 * (a1(4) - a1(3)), '3', 'parent', obj.velAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
            hold(obj.velAxes, 'on');
            plot(obj.velAxes, [data.stimTimeS * 1000.0, data.stimTimeS * 1000.0], [a1(3), a1(4)], 'k-.');
            if (startIndex > 0)
                plot(obj.velAxes, [startIndex, startIndex] * timestepMS, [a1(3), a1(4)], 'color', ...
                    colors(app.absStepIndex,:), 'linestyle', ':');
                if (endIndex > 0)
                    plot(obj.velAxes, [endIndex, endIndex] * timestepMS, [a1(3), a1(4)], 'color', ...
                    colors(app.absStepIndex,:), 'linestyle', ':');
                end
            end
            hold(obj.velAxes, 'off');
        end
    end
end
