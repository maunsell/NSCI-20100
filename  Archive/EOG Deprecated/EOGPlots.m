function EOGPlots(handles, startIndex, endIndex)
%EOGPlots Updata all plots for EOG

    posPlots(handles, startIndex, endIndex)
    velPlots(handles, startIndex, endIndex)
    drawnow;

end

%% posPlots: do the trial and average position plots
function posPlots(handles, startIndex, endIndex)
    
    daqaxes = [handles.axes1 handles.axes2];
    data = handles.data;
    saccades = handles.saccades;

    timestepS = 1 / data.sampleRateHz;                                       % time interval of samples
    trialTimes = (0:1:size(data.posTrace, 1) - 1) * timestepS;          % make array of trial time points
    saccadeTimes = (-(size(data.posAvg, 1) / 2):1:(size(data.posAvg,1) / 2) - 1) * timestepS;             
    colors = get(daqaxes(1), 'ColorOrder');

    % trial position trace
    cla(daqaxes(1));
    plot(daqaxes(1), trialTimes, data.posTrace, 'color', colors(data.offsetIndex,:));
    title(daqaxes(1), 'Most recent position trace', 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(1),'Analog Input (V)','FontSize',14);

    % average position traces
    cla(daqaxes(2));
    plot(daqaxes(2), saccadeTimes, data.posAvg, '-');
    title(daqaxes(2), ['Average position traces (left/right combined; ' sprintf('n>=%d)', data.blocksDone)], ...
                  'FontSize',12,'FontWeight','Bold')

    % set both plots to the same y scale
    a1 = axis(daqaxes(1));
    a3 = axis(daqaxes(2));
    yLim = max([abs(a1(3)), abs(a1(4)), abs(a3(3)), abs(a3(4))]);
    text(0.05 * a1(2), 0.8 * yLim, '1', 'parent', daqaxes(1), 'FontSize', 24, 'FontWeight', 'Bold');
    text(-0.112, 0.8 * yLim, '2', 'parent', daqaxes(2), 'FontSize', 24, 'FontWeight', 'Bold');
    axis(daqaxes(1), [-inf inf -yLim yLim]);
    axis(daqaxes(2), [-inf inf -yLim yLim]);
  
    % if a saccade was detected, mark its start (and end, if end was detected
    if (startIndex > 0)
        hold(daqaxes(1), 'on');
        plot(daqaxes(1), [startIndex, startIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
            'linestyle', ':');
        if (endIndex > 0)
            plot(daqaxes(1), [endIndex, endIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
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
        yTicks = [fliplr(-data.offsetsDeg), 0, data.offsetsDeg] / saccades.degPerV;
        for i = 1:length(yTicks)
            yLabels{i} = num2str(yTicks(i) * saccades.degPerV, '%.0f');
        end
        set(daqaxes(2), 'YTick', yTicks);
        set(daqaxes(2), 'YTickLabel', yLabels);
        ylabel(daqaxes(2),'Average Eye Position (absolute deg.)','FontSize',14);
    end
end


%% velPlots: do the trial and average velocity plots
function velPlots(handles, startIndex, endIndex)
    
    daqaxes = [handles.axes3 handles.axes4];
    data = handles.data;
    saccades = handles.saccades;

    timestepS = 1 / data.sampleRateHz;                                       % time interval of samples
    trialTimes = (0:1:size(data.posTrace, 1) - 1) * timestepS;          % make array of trial time points
    saccadeTimes = (-(size(data.posAvg, 1) / 2):1:(size(data.posAvg,1) / 2) - 1) * timestepS;              
    colors = get(daqaxes(1), 'ColorOrder');
   
    % plot the trial velocity trace
    cla(daqaxes(1));
    plot(daqaxes(1), trialTimes, data.velTrace, 'color', colors(data.offsetIndex,:));
    a = axis(daqaxes(1));
    yLim = max(abs(a(3)), abs(a(4)));
    axis(daqaxes(1), [-inf inf -yLim yLim]);
    title(daqaxes(1), 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold');
    ylabel(daqaxes(1),'Analog Input (dV/dt)','FontSize',14);
    xlabel(daqaxes(1),'Time (s)','FontSize',14);

    % plot the average velcotiy traces
    cla(daqaxes(2));
    plot(daqaxes(2), saccadeTimes, data.velAvg, '-');
    title(daqaxes(2), 'Average velocity traces (left/right combined)', 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(2),'Analog Input (V)','FontSize',14);
    xlabel(daqaxes(2),'Time (s)','FontSize',14);

    % put both plots on the same y scale
    a1 = axis(daqaxes(1));
    a2 = axis(daqaxes(2));
    yLim = max([abs(a1(3)), abs(a1(4)), abs(a2(3)), abs(a2(4))]);
    text(0.025, 0.8 * yLim, '3', 'parent', daqaxes(1), 'FontSize', 24, 'FontWeight', 'Bold');
    text(-0.112, 0.8 * yLim, '4', 'parent', daqaxes(2), 'FontSize', 24, 'FontWeight', 'Bold');
    axis(daqaxes(1), [-inf inf -yLim yLim]);
    axis(daqaxes(2), [-inf inf -yLim yLim]);
    
    % if a saccade was detected, mark its start (and end, if end was detected
    if (startIndex > 0)
        hold(daqaxes(1), 'on');
        plot(daqaxes(1), [startIndex, startIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
                                                                                             'linestyle', ':');
        if (endIndex > 0)
            plot(daqaxes(1), [endIndex, endIndex] * timestepS, [-yLim yLim], 'color', colors(data.offsetIndex,:),...
            'linestyle', ':');
        end
        hold(daqaxes(1), 'off');
    end
    
    % averages are always aligned on onset, so draw a vertical line at that point
    hold(daqaxes(2), 'on');
    plot(daqaxes(2), [0 0], [-yLim yLim], 'color', 'k', 'linestyle', ':');
    hold(daqaxes(2), 'off');

    % if eye position has been calibrated, change the y scaling on the average to degrees rather than volts
    if saccades.degPerSPerV > 0
        maxSpeedDPS = ceil((yLim * saccades.degPerSPerV) / 100.0) * 100;
        yTicks = (-maxSpeedDPS:100:maxSpeedDPS) / saccades.degPerSPerV;
        for i = 1:length(yTicks)
            yLabels{i} = num2str(yTicks(i) * saccades.degPerSPerV, '%.0f');
        end
        hold(daqaxes(1), 'on');
        
        %draw horizontal lines at +/-threshold for the trial velocity
        plot(daqaxes(1), [a(1) a(2)], [saccades.thresholdDPS saccades.thresholdDPS] ./ saccades.degPerSPerV,...
               	'color', colors(data.offsetIndex,:),'linestyle', ':');
        plot(daqaxes(1), [a(1) a(2)], -[saccades.thresholdDPS saccades.thresholdDPS] ./ saccades.degPerSPerV,...
               	'color', colors(data.offsetIndex,:),'linestyle', ':');
    	hold(daqaxes(1), 'off');
        set(daqaxes(1), 'YTick', yTicks);
        set(daqaxes(1), 'YTickLabel', yLabels);
        ylabel(daqaxes(1),'Average Eye Speed (degrees/s)','FontSize',14);
        set(daqaxes(2), 'YTick', yTicks);
        set(daqaxes(2), 'YTickLabel', yLabels);
        ylabel(daqaxes(2),'Average Eye Speed (degrees/s)','FontSize',14);
        
        % draw lines sowing the duration of the above-threshold part of the average traces.
        hold(daqaxes(2), 'on');
        for i = 1:data.numOffsets
            plot(daqaxes(2), [0, saccadeTimes(length(saccadeTimes) / 2 + data.saccadeDurS(i))],...
                                                -[yLim, yLim] / 5 * i, 'color', colors(i,:));
        end
        hold(daqaxes(2), 'off');
    end
end

