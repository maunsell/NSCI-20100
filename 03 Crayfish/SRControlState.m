function SRControlState(handles, state, except)
      
%     controls = {handles.startButton, handles.clearButton, handles.savePlotsButton, handles.saveDataButton, ...
%         handles.maxISIMenu};
    controls = {handles.startButton, handles.savePlotsButton, handles.saveDataButton, ...
        handles.maxISIMenu};
        
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
    drawnow limitrate nocallbacks;
end
