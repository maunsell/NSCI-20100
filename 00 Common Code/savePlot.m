function timeString = savePlot(axesToSave, folderPath, appString, formatString, timeString)

  if nargin < 5
    timeString = datestr(now, 'mmm-dd-HHMMSS');
  end
  if ~isfolder(folderPath)
      mkdir(folderPath);
  end
  filePath = fullfile(folderPath, [appString, '-', timeString, '.', formatString]);
  
  %exportgraphics(axesToSave, filePath, 'resolution', 300);
  
  % Workaround until BSLC gets Matlab 2020a
  
    % Create a temporary figure with axes.
  fig = figure;
  fig.Visible = 'off';
  figAxes = axes(fig);
  % Copy all UIAxes children, take over axes limits and aspect ratio.            
  allChildren = axesToSave.XAxis.Parent.Children;
  copyobj(allChildren, figAxes)
  figAxes.XLim = axesToSave.XLim;
  figAxes.YLim = axesToSave.YLim;
  figAxes.ZLim = axesToSave.ZLim;
  figAxes.XScale = axesToSave.XScale;
  figAxes.YScale = axesToSave.YScale;
  figAxes.GridLineStyle = axesToSave.GridLineStyle;
  figAxes.Units = axesToSave.Units;
  figAxes.Position = axesToSave.Position;
  figAxes.Position(2) = 75;
  figAxes.Position(1) = 0;
    
  figAxes.XTick = axesToSave.XTick;
  figAxes.XTickLabel = axesToSave.XTickLabel;
  figAxes.YTick = axesToSave.YTick;
  figAxes.YTickLabel = axesToSave.YTickLabel;
  figAxes.FontName = axesToSave.FontName;
  figAxes.FontSize = axesToSave.FontSize;
  figAxes.XLabel.String = axesToSave.XLabel.String;
  figAxes.YLabel.String = axesToSave.YLabel.String;
  
  figAxes.XGrid = axesToSave.XGrid;
  figAxes.GridLineStyle = axesToSave.GridLineStyle;
  figAxes.GridColor = axesToSave.GridColor;
  figAxes.GridAlpha = axesToSave.GridAlpha;

  
  figAxes.DataAspectRatio = axesToSave.DataAspectRatio;
  % Save as png and fig files.
  saveas(fig, filePath, 'png');
  % savefig(fig, fileName);
  % Delete the temporary figure.
  delete(fig);

  backupFile(filePath, '~/Desktop', '~/Documents/Respository');
end
  