function timeChar = savePlot(axesToSave, folderPath, appString, extString, timeChar)

  if nargin < 5
    timeChar = char(string(datetime('now', 'format', 'MMM-dd-HHmmss')));
  end
  if ~isfolder(folderPath)
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeChar, '.', extString]);
  fprintf('savePlot: writing to %s', filePath);
  tic
  exportgraphics(axesToSave, filePath);
  fprintf(' (%.1f s)\n', toc);
  backupFile(filePath, '~/Desktop', '~/Documents/Respository');     % save backup in repository directory
end
  