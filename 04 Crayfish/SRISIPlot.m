classdef SRISIPlot < handle
  % SRISIPlot Handle isi data and plotting for StretchReceptor
  % Maintain a histogram
  % change the number of bins as needed
  % plot as needed
  % Re-Configure the axes based on selections from the isiMaxS menu
  % clear values on demand
  
  properties
    countMaxX;      % last count histogram bin to plot
    countMaxY;      % limit on count histogram y axis
    isiLastPlot;    % countt of the last ISI plot
    isiMS;          % array of all isi in ms
    isiPlotXLimit;  % maximum displayed point in the ISI plot
    isiPlotYLimit;  % maximum displayed isi in the ISI plot
    isiSnippets;    % plotting snippets for the axes
    longCounts;     % individual spike counts for long count window
    longHist;       % histogram of spike counts for long interval
    maxISIMS;       % largest ISI in list
    numISIs;        % number of ISIs recorded
    numLongCounts;  % number of long window counts in the buffer
    numShortCounts; % number of short window counts in the buffer
    shortCounts;    % individual spike counts for short count window
    shortHist;      % histogram of spike counts for short interval
  end
  
  methods
    % SRISIPlot Initialization %%
    function obj = SRISIPlot(app)
      obj = obj@handle();
      obj.isiLastPlot = 0;
      obj.isiMS = zeros(1000, 1);
      obj.maxISIMS = 10;
      obj.isiSnippets = plotSnippets(app, app.isiAxes, 'bo');
      clearAll(obj, app);
      app.isiAxes.YGrid = 'on';

      xlabel(app.isiAxes, 'ISI Ordered in Time', 'fontsize', 14, 'fontWeight', 'bold');
      ylabel(app.isiAxes, 'ISI (ms)', 'fontsize', 14, 'fontWeight', 'bold');
    end

    % addISI -- add a new isi to the list of isi
    function addISI(obj, ~, newISIMS)
      if obj.numISIs >= length(obj.isiMS)                             % need to lengthen isi buffer?
        obj.isiMS = [obj.isiMS; zeros(1000, 1)];
      end
      obj.numISIs = obj.numISIs + 1;                                  % increment ISI count
      obj.isiMS(obj.numISIs) = newISIMS;                              % add ISI to list
    end
    
    % clearAll -- clear all values
    function clearAll(obj, app)
      obj.isiPlotXLimit = 50;
      obj.isiPlotYLimit = 10;
      obj.numISIs = 0;
      obj.maxISIMS = 10;
      hold(app.isiAxes, 'off');
      cla(app.isiAxes);
      axis(app.isiAxes, [0, str2double(app.longWindowLimitText.Value), 0, max(10, obj.maxISIMS * 1.1)]);
      hold(app.isiAxes, 'on');
      makeSnippets(obj.isiSnippets, app, 100);
    end

    % displayStats: When plot is down, display the mean and SD for first
    % and second halves of the ISI samples
    function displayStats(obj, app)
      if obj.numISIs < 20
        return;
      end
      displayText = cell(1, 3);
      displayText{1} = sprintf('%d ISIs', obj.numISIs);
      halfLabels = [{'1st'}, {'2nd'}];
      for i = 1:2
        startIndex = 1 + (i - 1) * floor(obj.numISIs / 2);
        endIndex = startIndex + floor(obj.numISIs / 2) - 1;
        displayText{i + 1} = sprintf('%s half: mean %.0f, SD %.0f', halfLabels{i}, ...
                  mean(obj.isiMS(startIndex:endIndex)), std(obj.isiMS(startIndex:endIndex)));
      end
      text(app.isiAxes, 0.025, 0.95, displayText, 'units', 'normalized', 'VerticalAlignment', 'top');
    end

    % plotISI - plot the ISIs as a function of time
    function plotISI(obj, app)
      rescale = false;
      if obj.numISIs > obj.isiPlotXLimit
        obj.isiPlotXLimit = obj.isiPlotXLimit * 2.0;
        rescale = true;
      end
      meanISI = mean(obj.isiMS(1:obj.numISIs));
      if meanISI > 0.5 * obj.isiPlotYLimit
        obj.isiPlotYLimit = meanISI * 2.0;
        rescale = true;
      end
      if rescale                                                          % replot entire set of isis
        hold(app.isiAxes, 'off');
        axis(app.isiAxes, [0, obj.isiPlotXLimit, 0, obj.isiPlotYLimit]);
        clearSnippets(obj.isiSnippets);
        hold(app.isiAxes, 'on');
        obj.isiLastPlot = 0;                                              % force a replot of all points
      end
      set(nextSnippet(obj.isiSnippets, app), 'XData', obj.isiLastPlot + 1:obj.numISIs, ...
          'YData', obj.isiMS(obj.isiLastPlot + 1:obj.numISIs));
      obj.isiLastPlot = obj.numISIs;
    end

  end
end

