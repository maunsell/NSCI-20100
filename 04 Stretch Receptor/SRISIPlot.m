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
    % isiLastPlot;  % countt of the last ISI plot
    isiCountText    % handle to in-axes text label    
    isiMS;          % array of all isi in ms
    isiLine         % handle to the plotted ISI points
    isiPlotXLimit;  % maximum displayed point in the ISI plot
    isiPlotYLimit;  % maximum displayed isi in the ISI plot
    longCounts;     % individual spike counts for long count window
    longHist;       % histogram of spike counts for long interval
    maxISIMS;       % largest ISI in list
    numISIs;        % number of ISIs recorded
    numLongCounts;  % number of long window counts in the buffer
  end
  
  methods
    % SRISIPlot Initialization %%
    function obj = SRISIPlot(app)
      obj = obj@handle();
      % obj.isiLastPlot = 0;
      obj.isiMS = zeros(1000, 1);
      obj.maxISIMS = 10;
      % obj.isiSnippets = plotSnippets(app, app.isiAxes, 'bo');
      obj.isiLine = gobjects(1);
      obj.isiCountText = gobjects(1);
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

    function clearAll(obj, app)
      obj.isiPlotXLimit = 50;
      obj.isiPlotYLimit = 10;
      obj.numISIs = 0;
      obj.maxISIMS = 10;

      hold(app.isiAxes, 'off');
      cla(app.isiAxes);

      axis(app.isiAxes, [0, str2double(app.longWindowLimitText.Value), 0, max(10, obj.maxISIMS * 1.1)]);
      app.isiAxes.YGrid = 'on';
      hold(app.isiAxes, 'on');

      % One graphics object for all points
      obj.isiLine = plot(app.isiAxes, NaN, NaN, 'bo', ...
        'LineStyle','none', ...
        'MarkerSize',4);

      % In-axes label (included in PNG exports)
      obj.isiCountText = text(app.isiAxes, 0.025, 0.025, '0 ISIs displayed', ...
        'Units','normalized', 'HorizontalAlignment','left', 'VerticalAlignment','bottom', ...
        'FontWeight','bold', 'FontSize',12, 'Color',[0 0 0], 'BackgroundColor',[1 1 1], ...
        'Margin',2, 'Interpreter','none', 'HitTest','off', 'PickableParts','none', 'Clipping','off');
    end
  
    function [numISIs, driftPC] = countStats(obj)
      numISIs = obj.numISIs;
      if numISIs < 20
        driftPC = 0;
        return;
      end
      n2 = floor(numISIs/2);
      m1 = mean(obj.isiMS(1:n2));
      m2 = mean(obj.isiMS(n2+1:2*n2));
      driftPC = (m2 - m1) / ((m1 + m2)/2) * 100.0;
    end

    function plotISI(obj, app)
      if obj.numISIs == 0
        return;
      end
      rescale = false;

      % X limit: grow when needed
      if obj.numISIs > obj.isiPlotXLimit
        obj.isiPlotXLimit = obj.isiPlotXLimit * 2.0;
        rescale = true;
      end
      % Y limit: use max, not mean (keeps outliers visible)
      newMax = max(obj.isiMS(1:obj.numISIs));
      if newMax > 0.9 * obj.isiPlotYLimit
        obj.isiPlotYLimit = max(10, newMax * 1.1);
        rescale = true;
      end
      if rescale
        axis(app.isiAxes, [0, obj.isiPlotXLimit, 0, obj.isiPlotYLimit]);
      end

      % Update points (<=1000 points is cheap)
      obj.isiLine.XData = 1:obj.numISIs;
      obj.isiLine.YData = obj.isiMS(1:obj.numISIs);

      if isgraphics(obj.isiCountText)
        [~, driftPC] = countStats(obj);
        if abs(driftPC) < 0.05
          driftPC = 0;
        end
        labelStr = sprintf('%d ISIs displayed,  Drift: %+0.1f%%', obj.numISIs, driftPC);
        obj.isiCountText.String = labelStr;
      end
    end

  end
end

