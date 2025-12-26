function ctControlState(app, state, except)

controls = {app.stimRepsText, app.stimDurText, app.intertrialDurText, ...
    app.prestimDurText, app.baseContrastMenu, app.clearDataButton, ...
    app.fitDataButton, app.loadDataButton, app.saveDataButton, app.runButton};

for c = 1:numel(controls)
    ctrl = controls{c};

    % ---- Skip exceptions ----
    skip = false;
    for e = 1:numel(except)
        if ctrl == except{e}
            skip = true;
            break;
        end
    end
    if skip
        continue;
    end

    % ---- Special case: fitDataButton ----
    if ctrl == app.fitDataButton && strcmp(state, 'on') 
      if sum(app.trialsDone(app.baseIndex, :)) >= 5 * app.numIncrements
          set(ctrl, 'Enable', 'on');
      else
        set(ctrl, 'Enable', 'off');
      end
    else
      set(ctrl, 'Enable', state);      % All other controls
    end 
end

drawnow;
end


% function ctControlState(app, state, except) 
% 
%   controls = {app.stimRepsText, app.stimDurText, app.intertrialDurText, ... 
%     app.prestimDurText, app.baseContrastMenu, app.clearDataButton, ... 
%     app.fitDataButton, app.loadDataButton, app.saveDataButton, app.runButton}; 
% 
%   for c = 1:length(controls) 
%     skip = false; 
%     for e = 1:length(except) 
%       if controls{c} == except{e}
%         skip = true; 
%         break; 
%       end 
%     end 
%     if ~skip
%       if state == 'off' || controls{c} ~= app.fitDataButton
%         set(controls{c}, 'enable', state);
%       elseif state && sum(app.trialsDone(app.baseIndex, :)) >= 5 * app.numIncrements
%         set(controls{c}, 'enable', 'on');
%       end
%     end 
%   end 
%   drawnow;
%   end