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
            cla(obj.fHandle);                                    % clear the figures
            if obj.n == 0
                rescale = 0;
                return
            end
            colors = get(obj.fHandle, 'ColorOrder');
            [counts, x] = hist(obj.fHandle, obj.reactTimesMS(1:obj.n));
            bar(obj.fHandle, x, counts, 1.0, 'facecolor', colors(obj.index,:));
            hold(obj.fHandle, 'on');
            title(obj.fHandle, sprintf('5° saccades'), 'fontSize',12,'fontWeight','bold');
            if (obj.index == 1)                                 % label the topmost plot
                xlabel(obj.fHandle, 'Reaction Time (ms)', 'fontSize', 14);
            end
            a = axis(obj.fHandle);
            a(1) = 0;
            if a(2) > obj.maxRT
                rescale = a(2);
            else
                a(2) = obj.maxRT;
                rescale = 0;
            end
            a(4) = 1.2 * a(4);
            axis(obj.fHandle, a);
            meanRT = mean(obj.reactTimesMS(1:obj.n));
            plot(obj.fHandle, [meanRT meanRT], [a(3) a(4)], ':');
            text(0.05 * a(2), 0.925 * a(4), sprintf('Mean %.0f ms', meanRT), 'parent', obj.fHandle);
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

