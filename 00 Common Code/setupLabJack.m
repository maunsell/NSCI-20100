function lbj = setupLabJack(sampleRateHz)
  %  get hardware info and do not continue if daq device/drivers unavailable
  lbj = labJackU6;                        % create the daq object
  open(lbj);                              % open connection to the daq
  if isempty(lbj.handle)
    fig = uifigure;
    % set(fig, 'visible', 'on');
    selection = uiconfirm(fig, ['No LabJack device found.', ...
      ' If the green LED on the LabJack is not flashing slowly, then exit here, ', ...
      'unplug and replug the USB cable, and re-launch app.'], ...
      'Fatal Error', 'Icon', 'error', 'options', {'Exit'});
    % set(fig, 'visible', 'off');
    close(fig);
    lbj = [];
    return;
  else
    fprintf(1,'LabJack Ready.\n\n');
  end
  % create input channel list
  removeChannel(lbj, -1);                     % remove all input channels
  addChannel(lbj, 0, 10, ['s', 's']);         % add channel 0 as input
  lbj.SampleRateHz = sampleRateHz;            % sample rate (Hz)
  lbj.ResolutionADC = 1;                      % ADC resolution (AD bit depth)

  % configure LabJack for analog input streaming
  errorCode = streamConfigure(lbj);
  if errorCode > 0
    fprintf(1, 'Unable to configure LabJack. Error %d.\n',errorCode);
    try clear('lbj'); catch, end
    return
  end
end
