function timeString = saveTable(theTable, folderPath, appString, timeString)

  if nargin < 4
    timeString = datestr(now, 'mmm-dd-HHMMSS');
  end
  if ~isfolder(folderPath)
    mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeString, '.xls']);
  t = cell2table(theTable.Data);
  % Here too, we have to play some games until we get Matlab 2020a
  %t.Properties.VariableNames = theTable.ColumnName;
  t.Properties.VariableNames = {'pc_3', 'pc_6', 'pc_12', 'pc_24', 'pc_48'};
  t.Properties.RowNames = theTable.RowName;
  %t.Properties.DimensionNames{1} = {' '};             % blank out the column name for the row name column
%   t.Properties.DimensionNames = {' ', 'Variables'};

  writetable(t, filePath, 'writeRowNames', true);
  backupFile(filePath, '~/Desktop', '~/Documents/Respository');
end
  