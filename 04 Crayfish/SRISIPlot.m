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
    isiMeanRate     % mean rate in spikes/s from ISIs
    isiMeanIsiMS    % mean isi
    isiMedianIsiMS  % median isi
    isiMS;          % array of all isi in ms
    isiNum;         % number of isi in the isi buffer
    isiQuartIsiMS;  % quartiles of ISIs
    isiSDIsiMS;     % SD of ISIs
    isiStartMaxY;   % initial y scaling
    isiXTicks       % number of ticks on x axis
  end
  
  methods
    %% SRISIPlot Initialization %%
    function obj = SRISIPlot(app)
      obj = obj@handle();
      % Post instantiation
      %             obj.fHandles = fH;
      %             app.isiAxes = fH.adxes3;
      obj.isiStartMaxY = 10;
      obj.isiLastPlotTime = clock;
      obj.isiNum = 0;
      obj.isiMS = zeros(1000, 1);
      obj.isiMaxMS = 0;                   % force rescaling
      obj.isiMeanRate = 0;
      obj.isiMeanIsiMS = 0;
      obj.isiMedianIsiMS = 0;
      obj.isiSDIsiMS = 0;
      obj.isiMaxY = obj.isiStartMaxY;
      obj.isiBins = 25;
      obj.isiXTicks = 10;
      setISIMaxS(obj, app);
    end
    
    %% addISI -- add a new isi to the list of isi
    function addISI(obj, app, newIsiMS)
      if obj.isiNum >= length(obj.isiMS)                              % need to lengthen isi buffer?
        obj.isiMS = [obj.isiMS; zeros(1000, 1)];
      end
      obj.isiNum = obj.isiNum + 1;
      obj.isiMS(obj.isiNum) = newIsiMS;
      if newIsiMS < obj.isiMaxMS
        bin = ceil(obj.isiBins * newIsiMS / obj.isiMaxMS);
        obj.isiHist(bin) = obj.isiHist(bin) + 1;
        if obj.isiHist(bin) > 0.95 * obj.isiMaxY                    % rescale y axis on overflow
          obj.isiMaxY = obj.isiMaxY * 1.5;                        % double the y axis maximum
          axis(app.isiAxes, [0, obj.isiBins, 0, obj.isiMaxY]);    % set axis scale
          makeHistogram(obj, app);
        end
      end
      if etime(clock, obj.isiLastPlotTime) > 2.0                      % refresh once a second
        obj.isiMeanIsiMS = mean(obj.isiMS(1:obj.isiNum));
        obj.isiMedianIsiMS = median(obj.isiMS(1:obj.isiNum));
        obj.isiSDIsiMS = std(obj.isiMS(1:obj.isiNum));
        obj.isiQuartIsiMS = prctile(obj.isiMS(1:obj.isiNum), [25, 75]);
        obj.isiMeanRate = obj.isiNum / (sum(obj.isiMS(1:obj.isiNum)) / 1000.0);
        cla(app.isiAxes);
        plotISI(obj, app);
        obj.isiLastPlotTime = clock;                                % time reference for next plot
      end
    end
    
    %% clearAll -- clear all values
    function clearAll(obj, app)
      obj.isiNum = 0;
      obj.isiMeanIsiMS = 0;
      obj.isiMedianIsiMS = 0;
      obj.isiMeanRate = 0;
      obj.isiMaxY = obj.isiStartMaxY;
      hold(app.isiAxes, 'off');
      cla(app.isiAxes);
      a = axis(app.isiAxes);
      axis(app.isiAxes, [a(1), a(2), 0, obj.isiMaxY]);
      makeHistogram(obj, app);
      rescalePlot(obj, app);
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
      if obj.isiMedianIsiMS > 0 && obj.isiMeanRate > 0
        if obj.isiSDIsiMS < 30
          precisionSD = 1;
        else
          precisionSD = 0;
        end
        rateText = sprintf(['%d spikes\nISI Mean %.0f ms\nISI SD %.*f ms\nISI Med. %.0f ms\n',...
          'ISI Quart. %.0f/%.0f ms\nRate Mean %.1f spk/s\n'], ...
          obj.isiNum, obj.isiMeanIsiMS, precisionSD, obj.isiSDIsiMS, obj.isiMedianIsiMS, ...
          obj.isiQuartIsiMS(1),  obj.isiQuartIsiMS(2), obj.isiMeanRate);
        a = axis(app.isiAxes);
        text(app.isiAxes, a(2) * 0.57, a(4) * 0.95, rateText, 'fontsize', 12, 'verticalalignment', 'top');
        if obj.isiNum > 0 && max(obj.isiMS(1:obj.isiNum)) > obj.isiMaxMS
          text(app.isiAxes, a(2) * 0.05, a(4) * 0.95, '(some ISIs off scale)', 'color', [0.75, 0, 0], ...
            'fontsize', 12, 'verticalalignment', 'top');
        end
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

