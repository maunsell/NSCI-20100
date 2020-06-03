function MetricsControlState(app, state, except)
      
    controls = {app.startButton, app.clearButton, app.savePlotsButton, ...
            app.saveDataButton, app.loadDataButton, app.viewDistanceText, app.thresholdDegText};
        
    for c = 1:length(controls)
        skip = false;
        for e = 1:length(except)
            if controls{c} == except{e}
                skip = true;
                break;
            end
        end
        if ~skip
            set(controls{c}, 'enable', state);
        end
    end
    drawnow;
end
