function timeChar = saveFigure(fHandle, folderPath, appString, extString, timeChar)

  if nargin < 5
    timeChar = char(string(datetime('now', 'format', 'MMM-dd-HHmmss')));
  end
  if ~isfolder(folderPath)
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeChar, '.', extString]);
  fprintf('saveFigure: saving to %s', filePath);
  tic
  exportgraphics(fHandle, filePath);
  fprintf(' (%.1f s)\n', toc);
  backupFile(filePath);     % save backup in repository directory
end
  