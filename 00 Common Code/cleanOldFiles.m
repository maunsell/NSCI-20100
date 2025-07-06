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
  
  % Define all possible app folder names and remove the current app's folder from the deletion list
  allAppFolders = {'OData', 'CTData', 'RTData', 'MData', 'SRData'};
  if ismember(currentAppName, allAppFolders)
    foldersToDelete = setdiff(allAppFolders, {currentAppName});
    % Delete the others if they exist in data root  
    for i = 1:length(foldersToDelete)
      oldFolderPath = fullfile(dataRoot(), foldersToDelete{i});
      if isfolder(oldFolderPath)
        try
          rmdir(oldFolderPath, 's');
        catch ME
          warning('Could not remove folder "%s": %s', oldFolderPath, ME.message);
        end
      end
    end
  end
end
  
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
