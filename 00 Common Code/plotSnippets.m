classdef plotSnippets < handle
  % plotSnippets
  % Support for plotting lines as a set of snippets
  % Matlab does not perform well at the job of incrementally advancing a
  % plot a frequent intervals.  Functions like plot and loglog work by
  % creating a new line object for each call, which has considerable overhead.
  % Using these to add a bit of line gives poor performance. plotSnippets()
  % improves performance considerably by creating a lot of line objects up
  % front, and doling them out as needed. You set the lines to display
  % by changing their 'XData' and 'YData' values. clearSnippets blanks
  % all lines.  Note that all the lines are destroyed by a cla or clf call.
  % If you use those calls you must call makeSnippets again. Note also that
  % "hold on" must be used while snippets are used, or the display
  % of each snippet will erase all previous snippets.
  
  properties
    axes;
    color;
    nextIndex;
    numSnippets = 0;
    snippets;
  end
  
  methods
    % Object Initialization %%
    function obj = plotSnippets(~, axes, color)
      obj = obj@handle();                                            % object initialization
      obj.axes = axes;
      obj.color = color;
    end
    
    function clearSnippets(obj, ~)
      for s = 1:obj.numSnippets
        set(obj.snippets{s}, 'XData', NaN, 'YData', NaN);
      end
      obj.nextIndex = 1;
    end

    function makeSnippets(obj, ~, numNew)
      numNew = max(numNew, obj.numSnippets);
      obj.snippets = cell(1, numNew);
      for s = 1:numNew
        obj.snippets{s} = plot(obj.axes, NaN, NaN, obj.color);
      end
      obj.numSnippets = numNew;
      obj.nextIndex = 1;
    end

    function next = nextSnippet(obj, ~)
      if obj.nextIndex < 1
        fprintf('plotSnippets: Error -- no snippets initialized\n');
        return;
      end
      if obj.nextIndex > obj.numSnippets
        numNew = 10;
        newSnippets = cell(1, numNew);
        for s = 1:numNew
          newSnippets{s} = plot(obj.axes, NaN, NaN, obj.color);
        end
        obj.snippets = [obj.snippets, newSnippets];
        obj.numSnippets = obj.numSnippets + numNew;
      end
      next = obj.snippets{obj.nextIndex};
      obj.nextIndex = obj.nextIndex + 1;
    end
  end
end