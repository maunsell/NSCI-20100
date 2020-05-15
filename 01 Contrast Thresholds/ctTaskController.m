
%% taskController: function to handle transition of task state.
function ctTaskController(~, ~, app)
%     handles = obj.UserData;
%     data = handles.data;
  switch app.taskState
    case ctTaskState.taskStopped
      % do nothing
    case ctTaskState.taskStartRunning
      set(app.runButton, 'text', 'Stop','backgroundColor', 'red');
      ctControlState(app, 'off', {app.runButton});
      app.trialStartTimeS = 0;
      app.stimStartTimeS = 0;
      app.taskState = ctTaskState.taskStartTrial;
    case ctTaskState.taskStartTrial
      if app.trialStartTimeS == 0                                   % start the trial
        ctDrawStatusText(app, 'intertrial');
        app.trialStartTimeS = clock;
        app.stimParams.stimReps = str2double(app.stimRepsText.Value);
        app.stimParams.prestimDurS = str2double(app.prestimDurText.Value);
        app.stimParams.stimDurS = str2double(app.stimDurText.Value);
        app.stimParams.intertrialDurS = str2double(app.intertrialDurText.Value);
        %                 baseIndex = contains(app.baseContrastMenu.Items, app.baseContrastMenu.Value);
        app.stimParams.changeSide = floor(2 * rand(1, 1));
      elseif (etime(clock, app.trialStartTimeS) > app.stimParams.intertrialDurS) || ~app.doStim
        % Draw dark gray fixspot
        sound(app.tones(3, :), app.sampFreqHz);
        if app.doStim
          doFixSpot(app.stimuli, 0.65);
          ctDrawStatusText(app, 'wait');
        end
        if ~app.testMode
          app.taskState = ctTaskState.taskWaitGoKey;
        else
          app.taskState = ctTaskState.taskDoStim;
        end
      end
    case ctTaskState.taskWaitGoKey
      % just wait for user to hit the down arrow button to start the stimulus
    case ctTaskState.taskDoStim
      if app.stimStartTimeS == 0                                     % start the stimulus
        baseContrast = app.baseContrasts(app.baseIndex);
        app.stimStartTimeS = clock;
        if app.doStim                         % Draw the base stimuli with a white fixspot
          ctDrawStatusText(app, 'run')
          app.stimParams.leftContrast = baseContrast;
          app.stimParams.rightContrast = baseContrast;
          doStimulus(app.stimuli, app);       % display the base contrast
        end
      elseif etime(clock, app.stimStartTimeS) > app.stimParams.prestimDurS
        % Draw the test stimuli, followed by the gray fixspot
        baseContrast = app.baseContrasts(app.baseIndex);
        blocksDone = min(app.trialsDone(app.baseIndex, :));
        undone = find(app.trialsDone(app.baseIndex, :) == blocksDone);
        app.testIndex = undone(ceil(length(undone) * (rand(1, 1))));
        if (app.stimParams.changeSide == 0)
          app.stimParams.leftContrast = app.testContrasts(app.baseIndex, app.testIndex);
          app.stimParams.rightContrast = baseContrast;
        else
          app.stimParams.leftContrast = baseContrast;
          app.stimParams.rightContrast = app.testContrasts(app.baseIndex, app.testIndex);
        end
        if app.doStim
          doStimulus(app.stimuli, app);       % display the increment stimulus
          doFixSpot(app.stimuli, 0.0);
          ctDrawStatusText(app, 'response');
        end
        app.taskState = ctTaskState.taskWaitResponse;
      end
    case ctTaskState.taskWaitResponse
      if app.testMode
        app.taskState = ctTaskState.taskProcessResponse;
      end
    case ctTaskState.taskProcessResponse
      %             blocksDone = min(app.trialsDone(app.baseIndex, :));
      %             undone = find(app.trialsDone(app.baseIndex, :) == blocksDone);
      if app.testMode
        prob = 0.5 + 0.5 / (1.0 + exp(-10.0 * (app.testContrasts(app.baseIndex, app.testIndex) - ...
          app.testContrasts(app.baseIndex, 3)) / app.baseContrasts(app.baseIndex)));
        hit = rand(1,1) < prob;
      else
        if strcmp(app.theKey, 'left')
          hit = app.stimParams.changeSide == 0;
        elseif strcmp(app.theKey, 'right')
          hit = app.stimParams.changeSide == 1;
        end
      end
      if (hit == 1)
        app.hits(app.baseIndex, app.testIndex) = app.hits(app.baseIndex, app.testIndex) + hit;
        sound(app.tones(2, :), app.sampFreqHz);
      else
        sound(app.tones(1, :), app.sampFreqHz);
      end
      app.trialsDone(app.baseIndex, app.testIndex) = app.trialsDone(app.baseIndex, app.testIndex) + 1;
      app.trialStartTimeS = 0;
      app.stimStartTimeS = 0;
      app.taskState = ctTaskState.taskStartTrial;
      if app.doStim
        clearScreen(app.stimuli);
      end
      ctDrawHitRates(app, false);
      % Check whether we are done with all the trials
      if sum(app.trialsDone(app.baseIndex, :)) >= app.stimParams.stimReps * app.numIncrements
        if (~app.testMode)                         % if we're not in test mode, we're done testing
          app.taskState = ctTaskState.taskStopRunning;
        else                                        % if we're testing, see if there are more to do, try next block
          if sum(app.trialsDone, 'all') >= app.stimParams.stimReps * app.numIncrements * app.numBases
            app.taskState = ctTaskState.taskStopRunning;
          else                                    % more to do, try the next multiplier
            while sum(app.trialsDone(app.baseIndex, :)) >= app.stimParams.stimReps * app.numIncrements
              app.baseIndex = mod(app.baseIndex, app.numBases) + 1;
            end
            app.baseContrastMenu.Value = app.baseContrastMenu.Items{app.baseIndex};
          end
        end
      end
    case ctTaskState.taskStopRunning
      if app.doStim
        clearScreen(app.stimuli);
      end
      ctDrawStatusText(app, 'idle');
      set(app.runButton, 'text', 'Run', 'backgroundColor', 'green');
      ctControlState(app, 'on', {app.runButton});
      app.taskState = ctTaskState.taskStopped;
  end
end