function backupFile(filePath, oldPathStr, newPathStr)

  repFilePath = strrep(filePath, oldPathStr, newPathStr);
  sysCommand = sprintf('cp %s %s', filePath, repFilePath');
  system(sysCommand);
end