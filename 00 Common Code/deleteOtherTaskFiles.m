  
function deleteOtherTaskFiles(currentAppName)

  % Ensure the main output folder exists
  folderPath = fullfile(dataRoot(), currentAppName);
  if ~isfolder(folderPath)
    mkdir(folderPath);
  end

  % Define all possible app folder names
  allAppFolders = {'OData', 'CTData', 'RTData', 'MData', 'SRData'};

  if ismember(currentAppName, allAppFolders)
    foldersToTrash = setdiff(allAppFolders, {currentAppName});

    trashDir = fullfile(getenv('HOME'), '.Trash');

    for i = 1:numel(foldersToTrash)
      oldFolderPath = fullfile(dataRoot(), foldersToTrash{i});

      if isfolder(oldFolderPath)
        try
          % Handle name collisions in Trash
          [~, name] = fileparts(oldFolderPath);
          destPath = fullfile(trashDir, name);

          if exist(destPath, 'dir')
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            destPath = fullfile(trashDir, [name '_' timestamp]);
          end

          movefile(oldFolderPath, destPath);
        catch ME
          warning('Could not move folder "%s" to Trash: %s', ...
                  oldFolderPath, ME.message);
        end
      end
    end
  end
end
