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
%     baseIndex = get(app.baseContrastMenu, 'value');
    baseIndex = find(contains(get(app.baseContrastMenu, 'items'), get(app.baseContrastMenu, 'value')));
    trialsPerBlock = size(app.trialsDone, 2);
    blocksDone = min(app.trialsDone(baseIndex, :));
    undone = find(app.trialsDone(baseIndex, :) == blocksDone);
    set(app.statusText, 'text', {runString, statusString, '', ...
           sprintf('      Trial %d of %d', trialsPerBlock - length(undone) + 1, trialsPerBlock)});
    drawnow;
end
