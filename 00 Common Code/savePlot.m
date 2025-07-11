function timeChar = savePlot(axesToSave, folderPath, appString, extString, timeChar)

  if nargin < 5
    timeChar = char(string(datetime('now', 'format', 'MMM-dd-HHmmss')));
  end
  folderPath = fullfile(dataRoot(), folderPath);     % put everything in data root
  if ~isfolder(folderPath)
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeChar, '.', extString]);
  % Here, we do a bizarre maneuver to workaround a terrible latency problem
  % with Matlab's exportgraphics(). When running the lab, exportgraphics()
  % always takes ~5s to output a plot from the GUI. But this time gets
  % slower and slower the longer that the task been running.  I could not
  % find what was bogging things down. I tried many things, but what works
  % is the following strategy of 1) creating a new, invisible figure,
  % copying the target axes into that new figure, 3) using exportgraphics()
  % to save the axes from the new figure, then 4) destroying the figure.
  % All this nonsense can be completed in under a second, which is fine for
  % our purposes. 
  fHandle = figure('visible', 'off', 'Position', [100, 100, 750, 750]); % create a new figure, big enough for all plots
  copyobj(axesToSave, fHandle);                                     % copy the axes into that figure
  pos = fHandle.Children.Position;                                  % make sure the axes are positioned visibly
  fHandle.Children.Position = [10, 10, pos(3), pos(4)];
  exportgraphics(fHandle.Children(1), filePath);                    % export the copied axes (now the first child)
  close(fHandle);                                                   % destroy the window
  backupFile(filePath);     % save backup in repository directory
end
  