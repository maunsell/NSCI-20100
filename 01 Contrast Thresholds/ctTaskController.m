
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
      app.trialStartTime = [];
      app.stimStartTime = [];
      app.taskState = ctTaskState.taskStartTrial;
    case ctTaskState.taskStartTrial
      if isempty(app.trialStartTime)                                % start the trial
        ctDrawStatusText(app, 'intertrial');
        app.trialStartTime = datetime('now');
        app.stimParams.stimReps = str2double(app.stimRepsText.Value);
        app.stimParams.prestimDurS = str2double(app.prestimDurText.Value);
        app.stimParams.stimDurS = str2double(app.stimDurText.Value);
        app.stimParams.intertrialDurS = str2double(app.intertrialDurText.Value);
        %                 baseIndex = contains(app.baseContrastMenu.Items, app.baseContrastMenu.Value);
        app.stimParams.changeSide = floor(2 * rand(1, 1));
      elseif (seconds(datetime('now') - app.trialStartTime) > app.stimParams.intertrialDurS) || ~app.doStim
        sound(app.tones(3, :), app.sampFreqHz);
        if app.doStim
          drawFixSpot(app.stimuli, [0.65, 0.65, 0.65]);             % dark gray fixspot
          ctDrawStatusText(app, 'wait');
        end
        if ~app.testMode
          app.taskState = ctTaskState.taskWaitGoKey;
        else
          app.taskState = ctTaskState.taskDoStim;
        end
      end
    case ctTaskState.taskWaitGoKey                                  % just wait for user to hit the down arrow
    case ctTaskState.taskDoStim
      % start of the stimulus presentation
      if isempty(app.stimStartTime)
        blocksDone = min(app.trialsDone(app.baseIndex, :));
        undone = find(app.trialsDone(app.baseIndex, :) == blocksDone);
        app.testIndex = undone(ceil(length(undone) * (rand(1, 1))));
        app.stimStartTime = datetime('now');
        if app.doStim                                               % draw the base stimuli with a white fixspot
          drawFixSpot(app.stimuli, [0.9, 0.9, 0.9]);
          drawStimuli(app.stimuli, app.baseIndex, 0, 0);            % display the base stimulus
          ctDrawStatusText(app, 'run')
        end
      % after the increment stimulus has finished
%       elseif etime(clock, app.stimStartTimeS) > app.stimParams.prestimDurS + app.stimParams.stimDurS
      elseif seconds(datetime('now') - app.stimStartTime) > app.stimParams.prestimDurS + app.stimParams.stimDurS
        clearScreen(app.stimuli);
        ctDrawStatusText(app, 'response');
        app.taskState = ctTaskState.taskWaitResponse;
      % after base contrast, start of increment stimulus
      elseif seconds(datetime('now') - app.stimStartTime) > app.stimParams.prestimDurS
%       elseif etime(clock, app.stimStartTimeS) > app.stimParams.prestimDurS
        if app.doStim
          if (app.stimParams.changeSide == 0)
              drawStimuli(app.stimuli, app.baseIndex, app.testIndex, 0);          % increment on dleft
          else
              drawStimuli(app.stimuli, app.baseIndex, 0, app.testIndex);          % increment on right
          end
        end
      end
    case ctTaskState.taskWaitResponse
      if app.testMode
        app.taskState = ctTaskState.taskProcessResponse;
      end
      drawFixSpot(app.stimuli, [0.0, 0.0, 0.0]);
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
      app.trialStartTime = [];
      app.stimStartTime = [];
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