function ctDrawStatusText(app, status)
  runString = 'Status: Running (''escape'' to quit)';
  switch status
    case 'idle'
      runString = 'Status: Waiting to run';
      statusString = '';
    case 'wait'
      statusString = '     Waiting to start trial (hit a key)';
    case 'run'
      statusString = '     Running trial';
    case 'response'
      statusString = '     Waiting for response';
    case 'intertrial'
      statusString = '     Waiting intertrial interval';
  end
  trialsPerBlock = size(app.trialsDone, 2);
  blocksDone = min(app.trialsDone(app.baseIndex, :));
  undone = find(app.trialsDone(app.baseIndex, :) == blocksDone);
  app.statusText.Text = {runString, statusString, ...
    sprintf('     Trial %d of %d in this repeat', trialsPerBlock - length(undone) + 1, trialsPerBlock)};
  drawnow;
end
