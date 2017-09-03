classdef EOGAmpDur < handle
    %EOGAmpDur Handle saccade-duration data for EOG
    %   Accumulates the data and handles the plot
    
    properties
        ampLabels
        offsetsDeg
        numOffsets
        fHandle
        n
        reactTimesMS
        sampleRateHz
    end
    
    methods
        
        function obj = EOGAmpDur(fH, offsetList, sampleRate)

             %% Pre Initialization %%
             % Any code not using output argument (obj)
             if nargin == 0
                offsetList = 10;
             end

             %% Object Initialization %%
             % Call superclass constructor before accessing object
             % You cannot conditionalize this statement
    %          obj = obj@handle(args{:});
             obj = obj@handle();

             %% Post Initialization %%
             obj.fHandle = fH;
             obj.sampleRateHz = sampleRate;
             obj.offsetsDeg = offsetList;
             obj.numOffsets = length(offsetList);
             obj.reactTimesMS = zeros(10000, obj.numOffsets);                  % preallocate a generous buffer
             obj.n = zeros(1, obj.numOffsets);

             obj.ampLabels = cell(1, obj.numOffsets);
             for i = 1:obj.numOffsets
                 obj.ampLabels{i} = sprintf('%.0f', obj.offsetsDeg(i));
             end
        end

        %% addAmpDur
        function addAmpDur(obj, offsetIndex, sIndex, eIndex)
            if sIndex > 0 && eIndex > 0
                obj.n(offsetIndex) = obj.n(offsetIndex) + 1;
                obj.reactTimesMS(obj.n(offsetIndex), offsetIndex) = (eIndex - sIndex) / obj.sampleRateHz * 1000.0;
            end
        end

        %% clearAll
        function clearAll(obj)
            obj.n = zeros(1, obj.numOffsets);
            cla(obj.fHandle);
        end

        %% confidenceInterval
        % return the 95% confidence interval

        function [yMean, sem] = stats(~, y)

            yMean = mean(y);
            num = length(y);
            if num > 5
                sem = std(y) / sqrt(num);
            else
                sem = 0;
            end
        end

        %% plotAmpDur
        function plotAmpDur(obj)
            if sum(obj.n) < obj.numOffsets
                cla(obj.fHandle);
                axis(obj.fHandle, [0 1 0 1]);
                text(0.05, 0.9, '5', 'parent', obj.fHandle, 'FontSize', 24, 'FontWeight', 'Bold');
                return;
            end
            cla(obj.fHandle);
            for i = 1:obj.numOffsets
                [yMean, sem] = stats(obj, obj.reactTimesMS(1:obj.n(i), i)');
                errorbar(obj.fHandle, obj.offsetsDeg(i), yMean, sem, -sem, 'o');
                hold(obj.fHandle, 'on');
           end
            title(obj.fHandle, 'Duration v. Amplitude', 'FontSize',12,'FontWeight','Bold');
            xlabel(obj.fHandle, 'Saccade Amplitude (deg)','FontSize',14);
            ylabel(obj.fHandle, 'Saccade Duration (ms)','FontSize',14);
            yLim = ylim(obj.fHandle);
            axis(obj.fHandle, [0 obj.offsetsDeg(end) + obj.offsetsDeg(1) 0 1.15 * yLim(2)]);
            a = axis(obj.fHandle);
            text(0.05 * a(2), 0.9 * a(4), '5', 'parent', obj.fHandle, 'FontSize', 24, 'FontWeight', 'Bold');
            hold(obj.fHandle, 'off');
        end
    

    end
    
end

