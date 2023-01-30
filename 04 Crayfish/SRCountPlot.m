classdef SRCountPlot < handle
  % SRCountPlot Handle count data, histograms and table for StretchReceptor
  % Maintain a histogram
  % change the number of bins as needed
  % plot as needed
  % re-Configure the axes based on selections from the isiMaxS menu
  % clear values on demand
  
  properties
    countBins;      % number bins in spike count histograms
    countMaxX;      % last count histogram bin to plot
    countMaxY;      % limit on count histogram y axis
    longCounts;     % individual spike counts for long count window
    longHist;       % histogram of spike counts for long interval
    longMaxCount;
    longPlot;       % the plotted long window histogram
    numLongCounts;  % number of long window counts in the buffer
    numShortCounts; % number of short window counts in the buffer
    shortCounts;    % individual spike counts for short count window
    shortHist;      % histogram of spike counts for short interval
    shortMaxCount;
    shortPlot;      % the plotted short histogram
    sumLongCounts;  % sum of all long counts
  end
  
  methods
    % SRISIPlot Initialization %%
    function obj = SRCountPlot(app)
      obj = obj@handle();
      obj.countBins = 100;
      obj.longCounts = zeros(1000, 1);
      obj.longHist = zeros(obj.countBins, 1);
      obj.shortHist = zeros(obj.countBins, 1);

      clearAll(obj, app);
      app.countAxes.YGrid = 'on';
      xlabel(app.countAxes, 'Spike Counts', 'fontsize', 14, 'fontWeight', 'bold');
      addStyle(app.resultsTable, uistyle('backgroundColor', [0.85, 0.85, 0.43]), 'cell', [1, 1]);
      addStyle(app.resultsTable, uistyle('backgroundColor', [0.90, 0.60, 0.47]), 'cell', [2, 1]);
      addStyle(app.resultsTable, uistyle('horizontalAlignment', 'center'));
    end

    % addLongCount -- add a new long count to the distribution
    function addLongCount(obj, app, longCount)
      obj.numLongCounts = obj.numLongCounts + 1;                         % increment count of spike counts
      obj.sumLongCounts = obj.sumLongCounts + longCount;
      if obj.numLongCounts > length(obj.longCounts)                      % need to lengthen isi buffer?
        obj.longCounts = [obj.longCounts; zeros(1000, 1)];
      end
      obj.longCounts(obj.numLongCounts) = longCount;                      % record spike count
      obj.longHist(longCount + 1) = obj.longHist(longCount + 1) + 1;      % zero based counting for histogram
      obj.longMaxCount = max(obj.longMaxCount, obj.longHist(longCount + 1));
      remake = false;
      if max(obj.shortMaxCount, obj.longMaxCount) > 0.95 * obj.countMaxY  % rescale y axis on overflow
        obj.countMaxY = obj.countMaxY * 1.5;                              % adjust the y axis maximum
        remake = true;
      end
      if longCount >= obj.countMaxX
        obj.countMaxX = longCount + 1;
        remake = true;
      end
      if remake
        makeCountHistograms(obj, app);
      end
      plotCounts(obj, app);
      tableData = get(app.resultsTable, 'Data');          % update table
      tableData = loadCountData(obj, app, tableData, obj.shortCounts(1:obj.numShortCounts), app.shortWindowMS, 2);
      tableData = loadCountData(obj, app, tableData, obj.longCounts(1:obj.numLongCounts), app.longWindowMS, 1);
      set(app.resultsTable, 'Data', tableData);
    end

    %% addShortCount -- add a new short count to the distribution
    function addShortCount(obj, app, shortCount)
      obj.numShortCounts = obj.numShortCounts + 1;                        % increment count of spike counts
      if obj.numShortCounts > length(obj.shortCounts)                     % need to lengthen isi buffer?
        obj.shortCounts = [obj.shortCounts; zeros(1000, 1)];
      end
      obj.shortCounts(obj.numShortCounts) = shortCount;                   % record spike count
      obj.shortHist(shortCount + 1) = obj.shortHist(shortCount + 1) + 1;  % zero based counting for histogram
      obj.shortMaxCount = max(obj.shortMaxCount, obj.shortHist(shortCount + 1));
      plotISI(app.isiPlot, app);
    end
    
    % clearAll -- clear all values
    function clearAll(obj, app)
      obj.countMaxX = 10;             % last bin to plot
      obj.countMaxY = 10;             % count in most filled bin
      obj.longMaxCount = 0;
      obj.numLongCounts = 0;
      obj.shortMaxCount = 0;
      obj.sumLongCounts = 0;
      obj.numShortCounts = 0;
      hold(app.countAxes, 'off');
      cla(app.countAxes);
      a = axis(app.countAxes);
      axis(app.countAxes, [a(1), a(2), 0, obj.countMaxY]);
      makeCountHistograms(obj, app);
      hold on;
      edges = -0.5:obj.countMaxX + 0.5;
      obj.longPlot = histogram(app.countAxes, 'binedges', edges, 'bincounts', obj.longHist(1:obj.countMaxX + 1), ...
        'faceColor', [0.75, 0.75, 0]);
      obj.shortPlot = histogram(app.countAxes, 'binedges', edges, 'bincounts', obj.shortHist(1:obj.countMaxX + 1), ...
        'faceColor', [0.8500, 0.3250, 0.0980]);
    end

    % loadCountData
    %  load the data table with values for one count window
    function tableData = loadCountData(obj, app, tableData, counts, windowMS, row)
      meanRate = mean(counts / (windowMS / 1000));
      quartileRate = std(counts / (windowMS / 1000)) * 1.15035;
      tableData{row, 2} = sprintf('%.0f', length(counts));
      tableData{row, 3} = validString(obj, app, meanRate - quartileRate);
      tableData{row, 4} = validString(obj, app, obj.sumLongCounts / obj.numLongCounts / (app.longWindowMS / 1000));
      tableData{row, 5} = validString(obj, app, meanRate + quartileRate);
    end
    
    % makeCountHistograms
    % recompile a histogram based on the current counts
    function makeCountHistograms(obj, app)
      obj.longHist = zeros(obj.countBins, 1);
      obj.shortHist = zeros(obj.countBins, 1);
      for i = 1:obj.numLongCounts
        bin = min(obj.countBins, obj.longCounts(i) + 1);          % zero based counting for histogram
        obj.longHist(bin) = obj.longHist(bin) + 1;
      end
      for i = 1:obj.numShortCounts
        bin = min(obj.countBins, obj.shortCounts(i) + 1);         % zero based counting for histogram
        obj.shortHist(bin) = obj.shortHist(bin) + 1;
      end
      axis(app.countAxes, [-0.5, obj.countMaxX + 0.5, 0, obj.countMaxY]);
      % We need to rescale the counts histogram plot whenever we remake
%       hold(app.countAxes, 'off');
%       hold(app.countAxes, 'on');
%       set(obj.shortPlot, 'BinCounts', obj.shortHist(1:obj.countMaxX + 1));
%       set(obj.longPlot, 'BinCounts', obj.longHist(1:obj.countMaxX + 1));
    end

    % plotCounts
    % plot histograms of spike counts
    function plotCounts(obj, ~)
%       cla(app.countAxes);
      edges = -0.5:obj.countMaxX + 0.5;
%       histogram(app.countAxes, 'binedges', edges, 'bincounts', obj.longHist(1:obj.countMaxX + 1), ...
%         'faceColor', [0.75, 0.75, 0]);
%       histogram(app.countAxes, 'binedges', edges, 'bincounts', obj.shortHist(1:obj.countMaxX + 1), ...
%         'faceColor', [0.8500, 0.3250, 0.0980]);
      set(obj.shortPlot, 'BinEdges', edges, 'BinCounts', obj.shortHist(1:obj.countMaxX + 1)');
      set(obj.longPlot, 'BinEdges', edges, 'BinCounts', obj.longHist(1:obj.countMaxX + 1)');
    end

    % validString
    %  return a string rendering that is integer for whole numbers, one fractional value other
    function string = validString(~, ~, value)
      if isnan(value) || isinf(value)
        string = '';
      else
        string = sprintf('%.1f', value);
      end
    end

  end
end

