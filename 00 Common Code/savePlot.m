function timeChar = savePlot(axesToSave, folderPath, appString, extString, timeChar)

if nargin < 5 || isempty(timeChar)
  timeChar = char(datetime('now','Format','MMM-dd-HHmmss'));
end

folderPath = fullfile(dataRoot(), folderPath);
if ~isfolder(folderPath)
  mkdir(folderPath);
end
filePath = fullfile(folderPath, [appString, '-', timeChar, '.', extString]);

% --- Get on-screen pixel size of the axes we want to save ---
ax = axesToSave;
oldAxUnits = ax.Units;
ax.Units = 'pixels';
axPos = ax.Position;           % [x y w h] in pixels
ax.Units = oldAxUnits;

% Add a small margin so labels/ticks don't get clipped
pad = 10;                      % pixels
figW = max(50, round(axPos(3) + 2*pad));
figH = max(50, round(axPos(4) + 2*pad));

% --- Invisible figure sized to match the UIAxes ---
fHandle = figure('Visible','off', ...
  'Units','pixels', ...
  'Position',[100 100 figW figH], ...
  'Color','w');

% --- Find existing visible legend associated with the axes (if any) ---
allLegends = findobj(ancestor(ax, 'figure'), 'Type', 'Legend', 'Visible', 'on');
lgd = [];

for i = 1:numel(allLegends)
  lgd_i = allLegends(i);
  legendAxes = unique(arrayfun(@(h) ancestor(h, 'axes'), lgd_i.PlotChildren));
  if any(legendAxes == ax)
    lgd = lgd_i;
    break;
  end
end

% --- Copy axes (+ legend if present) into the new figure ---
if isempty(lgd)
  axCopy = copyobj(ax, fHandle);
else
  copied = copyobj([ax lgd], fHandle);
  axCopy = copied(1);  % axes is first
end

% --- Make the copied axes fill the figure (with padding) ---
axCopy.Units = 'pixels';
axCopy.Position = [pad pad figW-2*pad figH-2*pad];

% Helpful: make sure background is consistent
try
  axCopy.Color = 'w';
catch
end

drawnow;  % ensure layout is resolved before export

% --- Export settings tuned by extension ---
extLower = lower(extString);

switch extLower
  case {'pdf','eps'}
    exportgraphics(axCopy, filePath, ...
      'ContentType','vector', ...
      'BackgroundColor','white');

  case {'png','tif','tiff','jpg','jpeg'}
    exportgraphics(axCopy, filePath, ...
      'Resolution', 200, ...
      'BackgroundColor','white');

  otherwise
    % Let MATLAB decide defaults for other extensions
    exportgraphics(axCopy, filePath, 'BackgroundColor','white');
end

close(fHandle);
backupFile(filePath);

end


% function timeChar = savePlot(axesToSave, folderPath, appString, extString, timeChar)
% 
% if nargin < 5
%   timeChar = char(datetime('now','Format','MMM-dd-HHmmss'));
% end
% folderPath = fullfile(dataRoot(), folderPath);
% if ~isfolder(folderPath)
%   mkdir(folderPath);
% end
% filePath = fullfile(folderPath, [appString, '-', timeChar, '.', extString]);
% 
% % --- Invisible figure workaround for fast export ---
% fHandle = figure('Visible', 'off', 'Position', [100 100 750 750]);
% 
% % --- Safely find existing, visible legend associated with the axes ---
% allLegends = findobj(ancestor(axesToSave, 'figure'), 'Type', 'Legend', 'Visible', 'on');
% lgd = [];
% 
% for i = 1:numel(allLegends)
%   lgd_i = allLegends(i);
%   % Get the parent axes of all items shown in the legend
%   legendAxes = unique(arrayfun(@(h) ancestor(h, 'axes'), lgd_i.PlotChildren));
%   % Check if the axesToSave is among them
%   if any(legendAxes == axesToSave)
%     lgd = lgd_i;
%     break;
%   end
% end
% % --- Copy axes and legend (if found) together ---
% if isempty(lgd)
%   axCopy = copyobj(axesToSave, fHandle);
% else
%   copied = copyobj([axesToSave lgd], fHandle);
%   axCopy = copied(1);  % axes is always first
% end
% 
% % Resize copied axes
% axCopy.Units = 'pixels';
% axCopy.Position = [50 50 650 650];
% 
% drawnow;
% 
% % Export
% exportgraphics(axCopy, filePath);
% 
% close(fHandle);
% 
% backupFile(filePath);
% end
