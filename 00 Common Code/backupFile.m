function backupFile(filePath, oldPathStr, newPathStr)

  repFilePath = strrep(filePath, oldPathStr, newPathStr);
  system(sprintf('mkdir -p $(dirname %s)', repFilePath));
  system(sprintf('cp %s %s', filePath, repFilePath'));
end