function timeChars = saveTable(theTable, folderPath, appString, timeChars)

  if nargin < 4
    timeChars = char(string(datetime('now', 'format', 'MMM-dd-HHmmss')));
  end
  if ~isfolder(folderPath)
    mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeChars, '.xls']);
  t = cell2table(theTable.Data);
  % Here too, we have to play some games until we get Matlab 2020a
  t.Properties.VariableNames = {'pc_3', 'pc_6', 'pc_12', 'pc_24', 'pc_48'};
  t.Properties.RowNames = theTable.RowName;
  writetable(t, filePath, 'writeRowNames', true);
  backupFile(filePath, '~/Desktop', '~/Documents/Respository');
end
  