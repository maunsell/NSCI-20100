function ok = confirmTestMode()
% confirmTestModeIfNeeded  Returns true if test mode should be enabled
% Only allows test mode after confirmation on a development machine
% whose name includes 'BSCD' (e.g., 'BSCD322-01').

  try
    ok = true;
    % Get computer name (MacOS)
    [~, name] = system('scutil --get ComputerName');
    name = strtrim(name);
    if contains(name, 'BSCD', 'IgnoreCase', true)
      originalSize = get(0, 'DefaultUIControlFontSize');
      set(0, 'DefaultUIControlFontSize', 14);
      selection = questdlg( ...
        'You are about to enter TEST MODE. This mode inserts synthetic data and is not appropriate for student use.', ...
        'Confirm Test Mode', 'Proceed', 'Cancel', 'Cancel');
      ok = strcmp(selection, 'Proceed');
      set(0, 'DefaultUIControlFontSize', originalSize);
    end
  catch
      % Fail safe: do not allow test mode if check fails
      ok = false;
      warning('Could not verify computer name. Test mode disabled.');
  end
end