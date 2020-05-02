function timeString = savePlot(axesToSave, folderPath, appString, formatString, timeString)

  if nargin < 5
    timeString = datestr(now,'HHMMSS');
  end
  if ~isfolder(folderPath)
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeString, '.', formatString]);
  exportgraphics(axesToSave, filePath, 'resolution', 300);
  repFilePath = strrep(filePath, '~/Desktop', '~/Documents/Respository');
  sysCommand = sprintf('cp %s %s', filePath, repFilePath');
  system(sysCommand);
end

function saveOnePlot(axesToSave, folderPath, appString, formatString, timeString)
  if ~isfolder(folderPath)
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeString, '.', formatString]);
  exportgraphics(axesToSave, filePath, 'resolution', 300);
end