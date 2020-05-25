classdef RTPosVelPlots < handle
    %   Support for processing eye traces and detecting saccades
    
    properties
        posAxes
        velAxes
    end
    
    methods
        function obj = RTPosVelPlots(handles)
             %% Object Initialization %%
             obj = obj@handle();                                            % object initialization

             %% Post Initialization %%
            obj.posAxes = handles.posAxes;
            obj.velAxes = handles.velAxes;
            cla(obj.posAxes);
            cla(obj.velAxes);
            title(obj.posAxes, 'Most recent position trace', 'fontSize', 12, 'fontWeight', 'bold')
            title(obj.velAxes, 'Most recent velocity trace', 'fontSize', 12, 'fontWeight', 'bold')
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
        function doPlots(obj, app, handles, startIndex, endIndex)
        % RTPlots Updata all plots for RT
            posPlots(obj, app, handles, startIndex, endIndex);
            velPlots(obj, app, handles, startIndex, endIndex);
        end

        %% posPlots: do the trial and average position plots
        function posPlots(obj, app, handles, startIndex, endIndex)
            data = handles.data;
            saccades = handles.saccades;
            timestepMS = 1000.0 / app.lbj.SampleRateHz;                 % time interval of samples
            xLimit = (size(app.posTrace, 1) - 1) * timestepMS;
            trialTimes = 0:timestepMS:xLimit;                           % make array of trial time points
            % current trial position trace

%             cla(obj.posAxes);
%             title(obj.posAxes, 'Most recent position trace', 'FontSize',12,'FontWeight','Bold')
%             a1 = axis(obj.posAxes);                             % label the pos plot "1"
%             text(trialTimes(1) + 0.05 * (trialTimes(end) - trialTimes(1)), ...
%                 a1(3) + 0.9 * (a1(4) - a1(3)), '1', 'parent', obj.posAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            plot(obj.posAxes, [0, xLimit], [0, 0], 'k', trialTimes, app.posTrace, 'b');
            a = axis(obj.posAxes);                                              % center vel plot vertically
            yLim = max(abs(a(3)), abs(a(4)));
            axis(obj.posAxes, [-inf inf -yLim yLim]);
            if saccades.degPerV > 0                                     % plot saccade threshold
                hold(obj.posAxes, 'on');
                thresholdV = saccades.thresholdDeg / saccades.degPerV * data.stepDirection;
                plot(obj.posAxes, [trialTimes(1) trialTimes(end)], [thresholdV, thresholdV], 'b:');
                calibratedLabels(obj, obj.posAxes, saccades.degPerV, 2)
                ylabel(obj.posAxes,'Eye Position (deg)','FontSize',14);
            else
                ylabel(obj.posAxes,'Analog Input (V)','FontSize',14);
            end
            hold(obj.posAxes, 'on');                            % mark fixOff and targetOn
            title(obj.posAxes, 'Most recent position trace', 'fontSize', 12, 'fontWeight', 'bold')
            a1 = axis(obj.posAxes);
            plot(obj.posAxes, [data.targetTimeS, data.targetTimeS] * 1000, [a1(3), a1(4)], 'k-.');
            if (app.fixOffTimeS ~= data.targetTimeS)
                plot(obj.posAxes, [app.fixOffTimeS, app.fixOffTimeS] * 1000, [a1(3), a1(4)], 'r-.');
            end
            if (startIndex > 0)                                 % mark the saccade start and end
                plot(obj.posAxes, [startIndex, startIndex] * timestepMS, [a1(3), a1(4)], 'b:');
                if (endIndex > 0)
                    plot(obj.posAxes, [endIndex, endIndex] * timestepMS, [a1(3), a1(4)], 'b:');
                end
            end
            hold(obj.posAxes, 'off');
       end

        %% velPlots: do the trial velocity plot
        function velPlots(obj, app, handles, startIndex, endIndex)
            data = handles.data;
            saccades = handles.saccades;
            timestepMS = 1000.0 / app.lbj.SampleRateHz;                     % time interval of samples
            xLimit = (size(app.posTrace, 1) - 1) * timestepMS;
            trialTimes = 0:timestepMS:xLimit;                               % make array of trial time points
            % plot the trial velocity trace
%             cla(obj.velAxes);
%             title(obj.velAxes, 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold');
%             text(trialTimes(1) + 0.05 * (trialTimes(end) - trialTimes(1)), ...
%                 a1(3) + 0.9 * (a1(4) - a1(3)), '2', 'parent', obj.velAxes, 'FontSize', 24, 'FontWeight', 'Bold');
            plot(obj.velAxes, [0, xLimit], [0, 0], 'k', trialTimes, app.velTrace, 'b');
            a = axis(obj.velAxes);                                              % center vel plot vertically
            yLim = max(abs(a(3)), abs(a(4)));
            axis(obj.velAxes, [-inf inf -yLim yLim]);
            xlabel(obj.velAxes,'Time (ms)','FontSize',14);
            % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
            if saccades.degPerV > 0
                calibratedLabels(obj, obj.velAxes, saccades.degPerSPerV, 100)
                ylabel(obj.velAxes,'Eye Speed (deg/s)','FontSize',14);
            else
                ylabel(obj.velAxes,'Analog Input (dV/dt)','FontSize',14);
            end
            a1 = axis(obj.velAxes);
            % Once the y-axis scaling is set, we can draw vertical marks for stimOn and saccades
            hold(obj.velAxes, 'on');
            title(obj.velAxes, 'Most recent velocity trace', 'fontSize', 12, 'fontWeight', 'bold')
            plot(obj.velAxes, [data.targetTimeS, data.targetTimeS] * 1000, [a1(3), a1(4)], 'k-.');
            if (app.fixOffTimeS ~= data.targetTimeS)
                plot(obj.velAxes, [app.fixOffTimeS, app.fixOffTimeS] * 1000, [a1(3), a1(4)], 'r-.');
            end
            if (startIndex > 0)                                         % plot the saccade start and end
                plot(obj.velAxes, [startIndex, startIndex] * timestepMS, [a1(3), a1(4)], 'b:');
                if (endIndex > 0)
                    plot(obj.velAxes, [endIndex, endIndex] * timestepMS, [a1(3), a1(4)], 'b:');
                end
            end
            hold(obj.velAxes, 'off');
        end
    end
end
