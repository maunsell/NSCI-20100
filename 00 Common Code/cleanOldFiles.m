function cleanOldFiles(currentAppName)
  % Ensure the main output folder exists
  folderPath = [dataRoot(), '/', currentAppName];
  if ~isfolder(folderPath)
    mkdir(folderPath);
  else
    % Delete old files from inside it
    today = datetime("today");
    cleanFolderRecursive(folderPath, today);
  end
end
  
%% Remove any files older than today, recursively
function cleanFolderRecursive(currentFolder, today)
  contents = dir(currentFolder);
  for i = 1:length(contents)
    name = contents(i).name;
    fullPath = fullfile(currentFolder, name);
  
    if strcmp(name, '.') || strcmp(name, '..')
      continue;
    end
  
    if contents(i).isdir
      cleanFolderRecursive(fullPath, today);
    else
      modTime = datetime(contents(i).date);  % modification time
      if modTime < today
        delete(fullPath);
      end
    end
  end
end
