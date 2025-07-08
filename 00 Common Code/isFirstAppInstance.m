function okToProceed = isFirstAppInstance(appFigureHandle)
% isFirstAppInstance  Check for other active tagged apps, excluding this one.
%
%   okToProceed = isFirstAppInstance(app.UIFigure)
%
%   Returns false if any *other* visible figure has a conflicting tag.

  % Define mutually exclusive tags
  conflictTags = {'ContrastThresholds', 'SaccadeRT', 'Metrics', 'StretchReceptor'};
  existingApps = [];
  conflictSource = '';  % Store which tag triggered the conflict
  for i = 1:numel(conflictTags)
    figs = findall(0, 'Type', 'figure', 'Tag', conflictTags{i});
    for j = 1:numel(figs)
      f = figs(j);
      if isvalid(f) && f ~= appFigureHandle
        try
          if strcmp(f.Visible, 'on')
            existingApps = [existingApps; f]; %#ok<AGROW>
            if isempty(conflictSource)
              conflictSource = conflictTags{i};  % Record the first hit
            end
          end
        catch
          % Skip non-standard figures
        end
      end
    end
  end
  
  if ~isempty(existingApps)
    d = uifigure('Name', 'App Conflict Detected', ...
      'Position', [500 500 400 120], ...
      'WindowStyle', 'modal');
  
    % Create a specific message using the conflicting tag
    msg = sprintf('A version of %s is already running.', conflictSource);
  
    uilabel(d, ...
      'Text', msg, ...
      'Position', [25 60 350 30], ...
      'HorizontalAlignment', 'center');
  
    uibutton(d, ...
      'Text', 'OK', ...
      'Position', [150 20 100 30], ...
      'ButtonPushedFcn', @(btn, event) delete(d));
  
    uiwait(d);
    okToProceed = false;
  else
    okToProceed = true;
  end
end