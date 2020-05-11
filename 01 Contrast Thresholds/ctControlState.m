function ctControlState(app, state, except)

controls = {app.stimRepsText, app.stimDurText, app.intertrialDurText, ...
  app.prestimDurText, app.baseContrastMenu, app.clearDataButton, ...
  app.savePlotsButton, app.loadDataButton, app.saveDataButton, ...
  app.showHideButton, app.runButton};

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
