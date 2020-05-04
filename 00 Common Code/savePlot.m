function timeString = savePlot(axesToSave, folderPath, appString, formatString, timeString)

  if nargin < 5
    timeString = datestr(now, 'mmm-dd-HHMMSS');
  end
  if ~isfolder(folderPath)
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeString, '.', formatString]);
  exportgraphics(axesToSave, filePath, 'resolution', 300);
  backupFile(filePath, '~/Desktop', '~/Documents/Respository');
end
  