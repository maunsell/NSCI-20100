function ctDrawStatusText(handles, status)
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
    baseIndex = get(handles.baseContrastMenu, 'value');
    trialsPerBlock = size(handles.data.trialsDone, 2);
    blocksDone = min(handles.data.trialsDone(baseIndex, :));
    undone = find(handles.data.trialsDone(baseIndex, :) == blocksDone);
    set(handles.statusText, 'string', {runString, statusString, '', ...
           sprintf('      Trial %d of %d', trialsPerBlock - length(undone) + 1, trialsPerBlock)});
    drawnow;
end
