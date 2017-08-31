classdef EOGRTDist < handle
    %EOGAmpDur Handle saccade-duration data for EOG
    %   Accumulates the data and handles the plot
    
    properties
        ampLabel
        fHandle
        index;
        maxRT;
        n
        offsetDeg;
        reactTimesMS
    end
        
    methods
        
        function obj = EOGRTDist(i, offset, axes)

             %% Pre Initialization %%
             % Any code not using output argument (obj)
             if nargin == 0
                offset = 10;
             end

             %% Object Initialization %%
             % Call superclass constructor before accessing object
             % You cannot conditionalize this statement
    %          obj = obj@handle(args{:});
             obj = obj@handle();

             %% Post Initialization %%
             obj.index = i;
             obj.fHandle = axes;
             obj.offsetDeg = offset;
             obj.ampLabel = sprintf('%.0f', offset);
             obj.reactTimesMS = zeros(1, 10000);                  % preallocate a generous buffer
             obj.n = 0;
             obj.maxRT = 0;
        end
    
        %% addRT
        function addRT(obj, rtMS)
            obj.n = obj.n + 1;
            obj.reactTimesMS(obj.n) = rtMS;
        end

        %% clearAll
        function clearAll(obj)
            obj.n = 0;
            obj.maxRT = 0;
            cla(obj.fHandle);
        end

        %% plotAmpDur
        function rescale = plot(obj)
            cla(obj.fHandle);
            if obj.n == 0 
                return
            end
            hist(obj.fHandle, obj.reactTimesMS(1:obj.n));
            hold(obj.fHandle, 'on');
            title(obj.fHandle, sprintf('%0.f degree saccades', obj.offsetDeg), 'FontSize',12,'FontWeight','Bold');
            if (obj.index == 4)
                xlabel(obj.fHandle, 'Reaction Time (ms)', 'FontSize',14);
            end
            a = axis(obj.fHandle);
            a(1) = 0;
            if a(2) > obj.maxRT
                rescale = a(2);
            else
                a(2) = obj.maxRT;
                rescale = 0;
            end
            axis(obj.fHandle, a);
%             text(obj.fHandle, 0.1 * a(2), 0.9 * a(4), 'Mean 123 ms');
            hold(obj.fHandle, 'off');
       end

        %% rescale
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

