function fileName = autoSaveName(taskName, timeString)

  fileName = sprintf('%s-Auto-%s', taskName, timeString);
  dirName = sprintf('~/Desktop/%sData/Data/', taskName);
  % check whether there are old auto saves that need to be purged
  dirList = dir(dirName);
  fileNames = {dirList(:).name};
  indices = find(contains(fileNames,[taskName, '-Auto']));
  maxTime = [];
  maxName = [];
  if length(indices) >= 2
    for i = 1:length(indices)
      name = fileNames{indices(i)};
      timeIndex = regexp(name, '[0-9]{6,6}');
      if isempty(timeIndex)
        continue;
      end
      fileTime = str2double(name(timeIndex:timeIndex+5));
      if isempty(maxTime)
        maxTime = fileTime;
        maxName = name;
      elseif fileTime >= maxTime
          delete([dirName, maxName]);
          maxTime = fileTime;
          maxName = name;
      end
    end
  end
  % move the one remaining auto save to a temp location for now.
  if ~isempty(maxName)
    movefile([dirName, maxName], [dirName, 'temp.mat']);
  end
end