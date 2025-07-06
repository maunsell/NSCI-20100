function backupFile(filePath)

  repFilePath = strrep(filePath, dataRoot(), fullfile(getenv('HOME'), 'Documents', 'Repository'));
  system(sprintf('mkdir -p $(dirname %s)', repFilePath));
  system(sprintf('cp %s %s', filePath, repFilePath'));
end