classdef SRISIPlot < handle
  % SRISIPlot Handle isi data and plotting for StretchReceptor
  % Maintain a histogram
  % change the number of bins as needed
  % plot as needed
  % Re-Configure the axes based on selections from the isiMaxS menu
  % clear values on demand
  
  properties
    %         fHandles;       % pointer to handles
    %         isiAxes;        % Matlab axes on which to plot
    isiBins;        % number of isi bins
    isiHist;        % the isi histogram we maintain
    isiLastPlotTime;% time of the last ISI plot
    isiMaxMS;       % maximum ISI included in the plot
    isiMaxY;        % maximum of the count axis
    isiMeanIsiMS    % mean isi
    isiMedianIsiMS  % median isi
    isiMS;          % array of all isi in ms
    isiN;           % number of entries in isiSumMS
    isiNum;         % number of isi in the isi buffer
    isiPCIsiMS;     % percentiles of ISIs
    isiSDIsiMS;     % SD of ISIs
    isiStartMaxY;   % initial y scaling
    isiSumMS;       % sum of spike ISI into current multi-spike ISI
    isiXTicks       % number of ticks on x axis
    meanSpikeRate   % mean rate in spikes/s from ISIs
  end
  
  methods
    %% SRISIPlot Initialization %%
    function obj = SRISIPlot(app)
      obj = obj@handle();
      obj.isiStartMaxY = 10;
      obj.isiLastPlotTime = clock;
      obj.isiMS = zeros(1000, 1);
      obj.isiMaxMS = 0;                   % force rescaling
      obj.isiSDIsiMS = 0;
      obj.isiBins = 25;
      obj.isiXTicks = 10;
      clearCounters(obj, app);
      setISIMaxS(obj, app);
    end
    
    %% addISI -- add a new isi to the list of isi
    function addISI(obj, app, newIsiMS)

      if obj.isiNum >= length(obj.isiMS)                            % need to lengthen isi buffer?
        obj.isiMS = [obj.isiMS; zeros(1000, 1)];
      end
      obj.isiSumMS = obj.isiSumMS + newIsiMS;
      obj.isiN = obj.isiN + 1;
      if obj.isiN >= app.spikesPerISI
        obj.isiNum = obj.isiNum + 1;                                % increment ISI count
        obj.isiMS(obj.isiNum) = obj.isiSumMS;                       % add summed ISI to list
        if obj.isiSumMS < obj.isiMaxMS                              % if ISI is on scale, add it to histogram
          bin = ceil(obj.isiBins * obj.isiSumMS / obj.isiMaxMS);
          obj.isiHist(bin) = obj.isiHist(bin) + 1;
          if obj.isiHist(bin) > 0.95 * obj.isiMaxY                  % rescale y axis on overflow
            obj.isiMaxY = obj.isiMaxY * 1.5;                        % double the y axis maximum
            axis(app.isiAxes, [0, obj.isiBins, 0, obj.isiMaxY]);    % set axis scale
            makeHistogram(obj, app);
          end
        end
        obj.isiN = 0;
        obj.isiSumMS = 0;
      end
      if etime(clock, obj.isiLastPlotTime) > 2.0                      % refresh once a second
        obj.isiMeanIsiMS = mean(obj.isiMS(1:obj.isiNum));
        obj.isiMedianIsiMS = median(obj.isiMS(1:obj.isiNum));
        obj.isiSDIsiMS = std(obj.isiMS(1:obj.isiNum));
        obj.isiPCIsiMS = prctile(obj.isiMS(1:obj.isiNum), [5, 95]);
        obj.meanSpikeRate = app.spikesPerISI * obj.isiNum / (sum(obj.isiMS(1:obj.isiNum)) / 1000.0);
        cla(app.isiAxes);
        plotISI(obj, app);
        obj.isiLastPlotTime = clock;                                % time reference for next plot
      end
    end
    
    %% clearAll -- clear all values
    function clearAll(obj, app)
      clearCounters(obj, app)
      hold(app.isiAxes, 'off');
      cla(app.isiAxes);
      a = axis(app.isiAxes);
      axis(app.isiAxes, [a(1), a(2), 0, obj.isiMaxY]);
      makeHistogram(obj, app);
      rescalePlot(obj, app);
    end

    %% clearCounters
    function clearCounters(obj, ~)
      obj.isiN = 0;
      obj.isiNum = 0;
      obj.isiMeanIsiMS = 0;
      obj.isiMedianIsiMS = 0;
      obj.meanSpikeRate = 0;
      obj.isiSumMS = 0;
      obj.isiMaxY = obj.isiStartMaxY;
    end

    %% makeHistogram
    % recompile a histogram based on the current bin width
    function makeHistogram(obj, app)
      obj.isiHist = zeros(obj.isiBins, 1);
      for i = 1:obj.isiNum
        if obj.isiMS(i) <= obj.isiMaxMS
          bin = ceil(obj.isiBins * obj.isiMS(i) / obj.isiMaxMS);
          obj.isiHist(bin) = obj.isiHist(bin) + 1;
        end
      end
      maxBin = max(obj.isiHist);
      if maxBin > 0 && (maxBin > 0.95 * obj.isiMaxY || maxBin < obj.isiMaxY / 1.5)
        obj.isiMaxY = 1.5 * maxBin;
        rescalePlot(obj, app);
        plotISI(obj, app);
      end
    end
    
    %% plotISI
    % plot the ISI histogram
    function plotISI(obj, app)
      histogram(app.isiAxes, 'binedges', 0:obj.isiBins, 'bincounts', obj.isiHist, 'facecolor', 'blue');
      if obj.isiMedianIsiMS > 0 && obj.isiNum > 0
        numOffScale = sum(obj.isiMS(1:obj.isiNum) > obj.isiMaxMS);
        if numOffScale > 0
          offScaleText = sprintf('(%d ISIs off scale)', numOffScale);
        else
          offScaleText = '';
        end
        if app.spikesPerISI > 1
          spikeString = 'spikes/ISI';
        else
          spikeString = 'spike/ISI';
        end
        theText = sprintf('%d %s\n%d ISIs\nISI Median %.0f ms\n95%% CI %.0f-%.0f ms\nMean Rate %.1f spk/s\n%s\n', ...
          app.spikesPerISI, spikeString, obj.isiNum, obj.isiMedianIsiMS, obj.isiPCIsiMS, obj.meanSpikeRate, ...
          offScaleText);
        a = axis(app.isiAxes);
        text(app.isiAxes, a(2) * 0.57, a(4) * 0.95, theText, 'fontsize', 12, 'verticalalignment', 'top');
      end
      drawnow limitrate nocallbacks;             	% don't plot too often, or notify callbacks
    end
    
    %% rescalePlot -- change the axis scaling and labeling after a change
    function rescalePlot(obj, app)
      hold(app.isiAxes, 'off');
      cla(app.isiAxes);
      axis(app.isiAxes, [0, obj.isiBins, 0, obj.isiMaxY]);
      xticks(app.isiAxes, 0:obj.isiBins / obj.isiXTicks:obj.isiBins);
      xTickLabels = cell(obj.isiXTicks, 1);
      app.isiAxes.YGrid = 'on';
      for t = 1:obj.isiXTicks + 1
        if mod(t, 2)
          xTickLabels{t} = sprintf('%.0f', (t-1) * obj.isiMaxMS / obj.isiXTicks);
        end
      end
      xticklabels(app.isiAxes, xTickLabels);
      xlabel(app.isiAxes, 'Inter-spike Interval (ms)', 'fontsize', 14, 'fontWeight', 'bold');
      hold(app.isiAxes, 'on');
      plotISI(obj, app);
    end

    %% saveStats -- write current statistics to an Excel spreadsheet
    function saveStats(obj, app, folderPath)
      if ~isfolder(folderPath)                      % folder exist?
        mkdir(folderPath);
      end
      timeString = string(datetime('now', 'Format', 'MMM-dd-HH:mm:ss'));
      dateString = string(datetime('now', 'Format', 'MMM-dd'));
      fileName = sprintf('SR-%s.xlsx', dateString);
      if isfile([folderPath fileName])
        system(sprintf('cp %s%s %stemp.xlsx', folderPath, fileName, folderPath));
        t = readtable([folderPath fileName], 'variableNamingRule', 'preserve');
        t = [t; {{timeString}, app.spikesPerISI, obj.isiNum, obj.isiMedianIsiMS, obj.isiPCIsiMS(1), ...
          obj.isiPCIsiMS(2), obj.meanSpikeRate}];
        writetable(t, [folderPath fileName]);
        system(sprintf('rm %stemp.xlsx', folderPath));
      else
        t = table({timeString}, app.spikesPerISI, obj.isiNum, obj.isiMedianIsiMS, obj.isiPCIsiMS(1), ...
          obj.isiPCIsiMS(2), obj.meanSpikeRate, 'variableNames', {'Time', 'Spikes Per ISI', 'Number of ISIs', ...
          'Median ISI (ms)', '5th Percentile ISI (ms)', '95th Percentile ISI (ms)', 'Mean Rate (spk/s)'});
        writetable(t, [folderPath fileName]);
      end
    end

    %% setMaxISI -- set the maximum isi in seconds
    % update based on the content of the GUI menu
    function setISIMaxS(obj, app)
      newIsiMaxMS = str2double(app.maxISIMenu.Value) * 1000.0;
      if newIsiMaxMS ~= obj.isiMaxMS
        obj.isiMaxMS = newIsiMaxMS;
        makeHistogram(obj, app);
        rescalePlot(obj, app);
      end
    end
  end
end

