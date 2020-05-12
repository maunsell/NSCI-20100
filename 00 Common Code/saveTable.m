function timeString = saveTable(theTable, folderPath, appString, timeString)

  if nargin < 4
    timeString = datestr(now, 'mmm-dd-HHMMSS');
  end
  if ~isfolder(folderPath)
    mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeString, '.xls']);
  t = cell2table(theTable.Data);
  t.Properties.VariableNames = theTable.ColumnName;
  t.Properties.RowNames = theTable.RowName;
  t.Properties.DimensionNames{1} = ' ';             % blank out the column name for the row name column
  writetable(t, filePath, 'writeRowNames', true);
  backupFile(filePath, '~/Desktop', '~/Documents/Respository');
end
  