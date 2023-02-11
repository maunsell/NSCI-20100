function timeChar = savePlot(axesToSave, folderPath, appString, extString, timeChar)

  if nargin < 5
    timeChar = char(string(datetime('now', 'format', 'MMM-dd-HHmmss')));
  end
  if ~isfolder(folderPath)
      fprintf(' savePlot: making folder\n');
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeChar, '.', extString]);
  fprintf(' savePlot: about to export %s\n', filePath);
  tic
  exportgraphics(axesToSave, filePath, 'resolution', 300);
  toc
  fprintf(' savePlot: about to backup %s\n', filePath);
  tic
  backupFile(filePath, '~/Desktop', '~/Documents/Respository');     % save backup in repository directory
  toc
  fprintf(' savePlot: all done\n');
end
  