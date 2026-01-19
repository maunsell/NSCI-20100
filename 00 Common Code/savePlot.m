function timeChar = savePlot(axesToSave, folderPath, appString, extString, timeChar)

if nargin < 5
  timeChar = char(datetime('now','Format','MMM-dd-HHmmss'));
end
folderPath = fullfile(dataRoot(), folderPath);
if ~isfolder(folderPath)
  mkdir(folderPath);
end
filePath = fullfile(folderPath, [appString, '-', timeChar, '.', extString]);

% --- Invisible figure workaround for fast export ---
fHandle = figure('Visible', 'off', 'Position', [100 100 750 750]);

% --- Safely find existing, visible legend associated with the axes ---
allLegends = findobj(ancestor(axesToSave, 'figure'), 'Type', 'Legend', 'Visible', 'on');
lgd = [];

for i = 1:numel(allLegends)
  lgd_i = allLegends(i);
  % Get the parent axes of all items shown in the legend
  legendAxes = unique(arrayfun(@(h) ancestor(h, 'axes'), lgd_i.PlotChildren));
  % Check if the axesToSave is among them
  if any(legendAxes == axesToSave)
    lgd = lgd_i;
    break;
  end
end
% --- Copy axes and legend (if found) together ---
if isempty(lgd)
  axCopy = copyobj(axesToSave, fHandle);
else
  copied = copyobj([axesToSave lgd], fHandle);
  axCopy = copied(1);  % axes is always first
end

% Resize copied axes
axCopy.Units = 'pixels';
axCopy.Position = [50 50 650 650];

drawnow;

% Export
exportgraphics(axCopy, filePath);

close(fHandle);

backupFile(filePath);
end
