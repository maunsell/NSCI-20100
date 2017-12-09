function ctControlState(handles, state, except)

    controls = {handles.stimRepsText,handles.stimDurText, handles.intertrialDurText, ...
            handles.prestimDurText, handles.baseContrastMenu, handles.clearDataButton, ...
            handles.savePlotsButton, handles.loadDataButton, handles.saveDataButton, ...
            handles.showHideButton, handles.runButton};
        
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
