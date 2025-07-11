classdef SRCountPlot < handle
  % SRCountPlot Handle count data, histograms and table for StretchReceptor
  % Maintain a histogram
  % change the number of bins as needed
  % plot as needed
  % re-Configure the axes based on selections from the isiMaxS menu
  % clear values on demand
  
  properties
    clearingNow;    % flag for clearing underway
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
    % SRCountPlot Initialization %%
    function obj = SRCountPlot(app)
      obj = obj@handle();
      obj.clearingNow = false;
      obj.countBins = 100;
      obj.longCounts = zeros(1000, 1);
      obj.longHist = zeros(obj.countBins, 1);
      obj.shortHist = zeros(obj.countBins, 1);
      clearAll(obj, app);
      app.countAxes.YGrid = 'on';
      xlabel(app.countAxes, 'Spike Counts', 'fontsize', 14, 'fontWeight', 'bold');
      ylabel(app.countAxes, 'Number of Intervals', 'fontsize', 14, 'fontWeight', 'bold');
      % configureTable(obj, app);
      addStyle(app.resultsTable, uistyle('horizontalAlignment', 'center'));
    end

    % addLongCount -- add a new long count to the distribution
    function addLongCount(obj, app, longCount)
      if obj.clearingNow
        return;
      end
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
      tableData = loadCountData(obj, app, tableData, obj.longCounts(1:obj.numLongCounts), app.longWindowMS, 1);
      set(app.resultsTable, 'Data', tableData);
      plotISI(app.isiPlot, app);
    end
    
    % clearAll -- clear all values
    function clearAll(obj, app)
      obj.clearingNow = true;
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
      hold(app.countAxes, 'on');
      makeCountHistograms(obj, app);
      edges = -0.5:obj.countMaxX + 0.5;
      obj.longPlot = histogram(app.countAxes, 'binedges', edges, 'bincounts', obj.longHist(1:obj.countMaxX + 1), ...
        'faceColor', [0.75, 0.75, 0]);
      obj.shortPlot = histogram(app.countAxes, 'binedges', edges, 'bincounts', obj.shortHist(1:obj.countMaxX + 1), ...
        'faceColor', [0.8500, 0.3250, 0.0980]);
       obj.clearingNow = false;
      % clear the contents of the count table
      tableData = cell(2, 7);
      tableData{1, 3} = app.longWindowMSText.Value;
      % if app.doShortCounts
      %   tableData{2, 3} = app.shortWindowMSText.Value;
      % end
      set(app.resultsTable, 'Data', tableData);
    end

    % configureTable
    % configure the data table to determine whether it shows long and short counts
    % function configureTable(~, app)
    %   app.resultsTable.Position(2) = 50;
    %   app.resultsTable.Position(4) = 50;
    % end

    % loadCountData
    % load the data table with values for one count window
    function tableData = loadCountData(obj, app, tableData, counts, windowMS, row)
      if row == 2 && ~app.doShortCounts
        for c = 1:7
          tableData{row, c} = '0';
        end
      else
        tableData{1, 3} = app.longWindowMSText.Value;
        rates = counts / (windowMS / 1000);
        sdRate = std(rates);                                        % SD of rate
        [numISIs, driftPC] = countStats(app.isiPlot);
        tableData{row, 1} = sprintf('%.0f', numISIs);
        tableData{row, 2} = sprintf('%.0f%%', driftPC);
        tableData{row, 4} = sprintf('%.0f', length(counts));
        tableData{row, 5} = validString(obj, app, mean(rates));
        tableData{row, 6} = validString(obj, app, sdRate);
        tableData{row, 7} = validString(obj, app, sdRate * 1.34);
      end
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
    end

    % plotCounts
    % plot histograms of spike counts
    function plotCounts(obj, ~)
      if obj.clearingNow
        return;
      end
      edges = -0.5:obj.countMaxX + 0.5;
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

