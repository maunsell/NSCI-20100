function SRControlState(app, state, except)
      
  controls = {app.startButton, app.clearButton, app.savePlotsButton, app.shortWindowMSText, app.longWindowMSText, ...
    app.contMSPerDivButton, app.vPerDivButton};   
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
end
