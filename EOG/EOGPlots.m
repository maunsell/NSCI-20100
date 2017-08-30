function EOGPlots(lbj, taskData, daqaxes, startIndex, endIndex, saccades)
%EOGPlots Updata all plots for EOG

    posPlots(lbj, taskData, daqaxes, startIndex, endIndex, saccades)
    velPlots(lbj, taskData, daqaxes, startIndex, endIndex, saccades)
    drawnow;

end

%% posPlots: do the trial and average position plots
function posPlots(lbj, taskData, daqaxes, startIndex, endIndex, saccades)
    
    timestepS = 1 / lbj.SampleRateHz;                                       % time interval of samples
    trialTimes = (0:1:size(taskData.posTrace, 1) - 1) * timestepS;          % make array of trial time points
    saccadeTimes = (-(size(taskData.posAvg, 1) / 2):1:(size(taskData.posAvg,1) / 2) - 1) * timestepS;              
    colors = get(daqaxes(1), 'ColorOrder');

    % trial position trace
    plot(daqaxes(1), trialTimes, taskData.posTrace, 'color', colors(taskData.offsetIndex,:));
    title(daqaxes(1), 'Most recent position trace', 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(1),'Analog Input (V)','FontSize',14);
    
    % average position traces
    plot(daqaxes(2), saccadeTimes, taskData.posAvg, '-');
    title(daqaxes(2), ['Average position traces (left/right combined; ' sprintf('n>=%d)', taskData.blocksDone)], ...
                  'FontSize',12,'FontWeight','Bold')

    % set both plots to the same y scale
    a1 = axis(daqaxes(1));
    a2 = axis(daqaxes(2));
    yLim = max([abs(a1(3)), abs(a1(4)), abs(a2(3)), abs(a2(4))]);
    axis(daqaxes(1), [-inf inf -yLim yLim]);
    axis(daqaxes(2), [-inf inf -yLim yLim]);
   
    % if a saccade was detected, mark its start (and end, if end was detected
    if (startIndex > 0)
        hold(daqaxes(1), 'on');
        plot(daqaxes(1), [startIndex, startIndex] * timestepS, [-yLim yLim], 'color', colors(taskData.offsetIndex,:),...
            'linestyle', ':');
        if (endIndex > 0)
            plot(daqaxes(1), [endIndex, endIndex] * timestepS, [-yLim yLim], 'color', colors(taskData.offsetIndex,:),...
            'linestyle', ':');
        end
        hold(daqaxes(1), 'off');
    end
    
    % averages are always aligned on onset, so draw a vertical line at that point
    hold(daqaxes(2), 'on');
    plot(daqaxes(2), [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
    hold(daqaxes(2), 'off');
 
    % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
    if saccades.degPerV > 0
        yTicks = [fliplr(-taskData.offsetsDeg), 0, taskData.offsetsDeg] / saccades.degPerV;
        for i = 1:length(yTicks)
            yLabels{i} = num2str(yTicks(i) * saccades.degPerV, '%.0f');
        end
        set(daqaxes(2), 'YTick', yTicks);
        set(daqaxes(2), 'YTickLabel', yLabels);
        ylabel(daqaxes(2),'Average Eye Position (absolute deg.)','FontSize',14);
    end
end


%% velPlots: do the trial and average velocity plots
function velPlots(lbj, taskData, daqaxes, startIndex, endIndex, saccades)
    
    timestepS = 1 / lbj.SampleRateHz;                                       % time interval of samples
    trialTimes = (0:1:size(taskData.posTrace, 1) - 1) * timestepS;          % make array of trial time points
    saccadeTimes = (-(size(taskData.posAvg, 1) / 2):1:(size(taskData.posAvg,1) / 2) - 1) * timestepS;              
    colors = get(daqaxes(1), 'ColorOrder');
   
    % plot the trial velocity trace
    plot(daqaxes(3), trialTimes, taskData.velTrace, 'color', colors(taskData.offsetIndex,:));
    a = axis(daqaxes(3));
    yLim = max(abs(a(3)), abs(a(4)));
    axis(daqaxes(3), [-inf inf -yLim yLim]);
    title(daqaxes(3), 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold');
    ylabel(daqaxes(3),'Analog Input (dV/dt)','FontSize',14);
    xlabel(daqaxes(3),'Time (s)','FontSize',14);

    % plot the average velcotiy traces
    plot(daqaxes(4), saccadeTimes, taskData.velAvg, '-');
    title(daqaxes(4), 'Average velocity traces (left/right combined)', 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(4),'Analog Input (V)','FontSize',14);
    xlabel(daqaxes(4),'Time (s)','FontSize',14);

    % put both plots on the same y scale
    a1 = axis(daqaxes(3));
    a2 = axis(daqaxes(4));
    yLim = max([abs(a1(3)), abs(a1(4)), abs(a2(3)), abs(a2(4))]);
    axis(daqaxes(3), [-inf inf -yLim yLim]);
    axis(daqaxes(4), [-inf inf -yLim yLim]);
    
    % if a saccade was detected, mark its start (and end, if end was detected
    if (startIndex > 0)
        hold(daqaxes(3), 'on');
        plot(daqaxes(3), [startIndex, startIndex] * timestepS, [-yLim yLim], 'color', colors(taskData.offsetIndex,:),...
                                                                                             'linestyle', ':');
        if (endIndex > 0)
            plot(daqaxes(3), [endIndex, endIndex] * timestepS, [-yLim yLim], 'color', colors(taskData.offsetIndex,:),...
            'linestyle', ':');
        end
        hold(daqaxes(3), 'off');
    end
    
    % averages are always aligned on onset, so draw a vertical line at that point
    hold(daqaxes(4), 'on');
    plot(daqaxes(4), [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
    hold(daqaxes(4), 'off');

    % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
    if saccades.degPerSPerV > 0
        maxSpeedDPS = ceil((yLim * saccades.degPerSPerV) / 100.0) * 100;
        yTicks = (-maxSpeedDPS:100:maxSpeedDPS) / saccades.degPerSPerV;
        for i = 1:length(yTicks)
            yLabels{i} = num2str(yTicks(i) * saccades.degPerSPerV, '%.0f');
        end
        hold(daqaxes(3), 'on');
        
        %draw horizontal lines at +/-threshold for the trial velocity
        plot(daqaxes(3), [a(1) a(2)], [saccades.thresholdDPS saccades.thresholdDPS] ./ saccades.degPerSPerV,...
               	'color', colors(taskData.offsetIndex,:),'linestyle', ':');
        plot(daqaxes(3), [a(1) a(2)], -[saccades.thresholdDPS saccades.thresholdDPS] ./ saccades.degPerSPerV,...
               	'color', colors(taskData.offsetIndex,:),'linestyle', ':');
    	hold(daqaxes(3), 'off');
        set(daqaxes(3), 'YTick', yTicks);
        set(daqaxes(3), 'YTickLabel', yLabels);
        ylabel(daqaxes(3),'Average Eye Speed (degrees/s)','FontSize',14);
        set(daqaxes(4), 'YTick', yTicks);
        set(daqaxes(4), 'YTickLabel', yLabels);
        ylabel(daqaxes(4),'Average Eye Speed (degrees/s)','FontSize',14);
        
        % draw lines sowing the duration of the above-threshold part of the average traces.
        midX = length(saccadeTimes) / 2;
        hold(daqaxes(4), 'on');
        for i = 1:taskData.numOffsets
            plot(daqaxes(4), [0, saccadeTimes(length(saccadeTimes) / 2 + taskData.saccDur(i))],...
                                                -[yLim, yLim] / 5 * i, 'color', colors(i,:));
        end
        hold(daqaxes(4), 'off');
    end
end


