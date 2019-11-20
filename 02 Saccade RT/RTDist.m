classdef RTDist < handle
    % RTAmpDur -- Handle saccade-duration data for RT
    %   Accumulates the data and handles plotting RT panels in the GUI
    
    properties
        ampLabel
        fHandle
        index;
        maxRT;
        n
        reactTimesMS
    end
    properties (Constant)
        titles = {'Gap', 'Step', 'Overlap'};
    end
        
    methods
        %% Initialization
        function obj = RTDist(i, axes)
             obj = obj@handle();                                % object initiatlization
             obj.index = i;                                     % post initialization
             obj.fHandle = axes;
             obj.ampLabel = sprintf('%.0f', 25.3);
             obj.reactTimesMS = zeros(1, 10000);             	% preallocate a generous buffer
             obj.n = 0;
             obj.maxRT = 0;
        end
    
        %% addRT -- add a RT value to the distributioin
        function addRT(obj, rtMS)
            obj.n = obj.n + 1;
            obj.reactTimesMS(obj.n) = max(rtMS, 0);
        end

        %% clearAll -- clear all the buffers
        function clearAll(obj)
            obj.n = 0;
            obj.maxRT = 0;
            cla(obj.fHandle);
        end

        %% plot -- plot all the distributions
        function rescale = plot(obj)
            cla(obj.fHandle);                                   % clear the figures
            if obj.n == 0                                       % nothing to plot
                rescale = 0;
                return
            end
            colors = get(obj.fHandle, 'colorOrder');            % get the colors for the different plots
            [counts, x] = hist(obj.fHandle, obj.reactTimesMS(1:obj.n));
            bar(obj.fHandle, x, counts, 1.0, 'facecolor', colors(obj.index,:));
            hold(obj.fHandle, 'on');
            title(obj.fHandle, sprintf('%s Condition', obj.titles{obj.index}), 'fontSize', 12, 'fontWeight', 'bold');
            if (obj.index == 3)                                 % label the bottom plot
                xlabel(obj.fHandle, 'Reaction Time (ms)', 'fontSize', 14);
            end
            a = axis(obj.fHandle);                              % set scale, flag whether we're rescaling
            a(1) = 0;
            if a(2) > obj.maxRT                                 % new x limit, rescale
                rescale = a(2);
            else
                a(2) = obj.maxRT;                               % no new x limit, plot on the current limit
                rescale = 0;
            end
            a(4) = 1.2 * a(4);                                  % leave some headroom about the histogram
            axis(obj.fHandle, a);
            meanRT = mean(obj.reactTimesMS(1:obj.n));           % mean RT
            stdRT = std(obj.reactTimesMS(1:obj.n));             % std for RT
            plot(obj.fHandle, [meanRT meanRT], [a(3) a(4)], ':');
            text(a(1) + 0.05 * (a(2) - a(1)), 0.9 * a(4), sprintf('%.0f', obj.index + 2), 'parent', obj.fHandle, ...
                'fontSize', 24, 'fontWeight', 'bold');
            displayText = {sprintf('n = %.0f', obj.n), sprintf('Mean = %.0f', meanRT)};
            if obj.n > 10
                sem = stdRT / sqrt(obj.n);
                ci = sem * 1.96;
                plot(obj.fHandle, [-ci, ci] + meanRT, [1, 1] * 0.92 * a(4), 'color', colors(obj.index,:), ...
                    'lineWidth', 3);
                plot(obj.fHandle, [-sem, sem] + meanRT, [1, 1] * 0.95 * a(4), 'color', colors(obj.index,:), ...
                    'lineWidth', 3);
                semPrecision = sem < 2.0;
                displayText{length(displayText) + 1} = sprintf('SEM %.*f-%.*f ms', semPrecision, meanRT - sem, ...
                    semPrecision, meanRT + sem);
                ciPrecision = ci < 2.0;
                displayText{length(displayText) + 1} = sprintf('95%% CI %.*f-%.*f ms', ciPrecision, meanRT - ci, ...
                    ciPrecision, meanRT + ci);
            end
            text(0.05 * a(2), 0.80 * a(4), displayText, 'verticalAlignment', 'top', 'parent', obj.fHandle);
            hold(obj.fHandle, 'off');
       end

        %% rescale -- rescale the plots
        function rescale(obj, newMaxRT)
            obj.maxRT = newMaxRT;
            hold(obj.fHandle, 'on');
            a = axis(obj.fHandle);
            a(2) = obj.maxRT;
            axis(obj.fHandle, a);
            hold(obj.fHandle, 'off');
        end    
    
    end
end

