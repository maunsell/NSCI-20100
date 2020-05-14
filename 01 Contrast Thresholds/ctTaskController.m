
%% taskController: function to handle transition of task state.
function ctTaskController(obj, ~, app)
    handles = obj.UserData;
    data = handles.data;
    switch app.taskState
        case ctTaskState.taskStopped
            % do nothing
        case ctTaskState.taskStartRunning
            set(handles.runButton, 'string', 'Stop','backgroundColor', 'red');
            ctControlState(handles, 'off', {handles.runButton});
            data.trialStartTimeS = 0;
            data.stimStartTimeS = 0;
            app.taskState = ctTaskState.taskStartTrial;
        case ctTaskState.taskStartTrial
           if data.trialStartTimeS == 0                                   % start the trial
                ctDrawStatusText(app, handles, 'intertrial');
                data.trialStartTimeS = clock;
                data.stimParams.stimReps = str2double(get(handles.stimRepsText, 'string'));
                data.stimParams.prestimDurS = str2double(get(handles.prestimDurText, 'string'));
                data.stimParams.stimDurS = str2double(get(handles.stimDurText, 'string'));
                data.stimParams.intertrialDurS = str2double(get(handles.intertrialDurText, 'string'));
%                 baseIndex = contains(app.baseContrastMenu.Items, app.baseContrastMenu.Value);
                data.stimParams.changeSide = floor(2 * rand(1, 1));
            elseif (etime(clock, data.trialStartTimeS) > data.stimParams.intertrialDurS) || ~data.doStim
               % Draw dark gray fixspot
               sound(data.tones(3, :), data.sampFreqHz);
                if data.doStim
                  doFixSpot(app.stimuli, 0.65);
                 	ctDrawStatusText(app, handles, 'wait');
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
           if data.stimStartTimeS == 0                                     % start the stimulus
                baseIndex = contains(app.baseContrastMenu.Items, app.baseContrastMenu.Value);
                baseContrast = app.baseContrasts(baseIndex);
                data.stimStartTimeS = clock;
                if data.doStim                        % Draw the base stimuli with a white fixspot
                    ctDrawStatusText(app, handles, 'run')
                    data.stimParams.leftContrast = baseContrast;
                    data.stimParams.rightContrast = baseContrast;
                    doStimulus(app.stimuli, app, data.stimParams);           % display the base contrast
                end
            elseif etime(clock, data.stimStartTimeS) > data.stimParams.prestimDurS
               % Draw the test stimuli, followed by the gray fixspot
                baseIndex = contains(app.baseContrastMenu.Items, app.baseContrastMenu.Value);
                baseContrast = app.baseContrasts(baseIndex);
                blocksDone = min(data.trialsDone(baseIndex, :));
                undone = find(data.trialsDone(baseIndex, :) == blocksDone);
                data.testIndex = undone(ceil(length(undone) * (rand(1, 1))));
                if (data.stimParams.changeSide == 0)
                    data.stimParams.leftContrast = data.testContrasts(baseIndex, data.testIndex);
                    data.stimParams.rightContrast = baseContrast;
                else
                    data.stimParams.leftContrast = baseContrast;
                    data.stimParams.rightContrast = data.testContrasts(baseIndex, data.testIndex);
                end
                if data.doStim
                    doStimulus(app.stimuli, app, data.stimParams);           % display the increment stimulus
                    doFixSpot(app.stimuli, 0.0);
                    ctDrawStatusText(app, handles, 'response');
                end
                app.taskState = ctTaskState.taskWaitResponse;
            end
        case ctTaskState.taskWaitResponse
            if app.testMode
                app.taskState = ctTaskState.taskProcessResponse;
            end
        case ctTaskState.taskProcessResponse
                baseIndex = contains(app.baseContrastMenu.Items, app.baseContrastMenu.Value);
%             blocksDone = min(data.trialsDone(baseIndex, :));
%             undone = find(data.trialsDone(baseIndex, :) == blocksDone);
            if app.testMode
                prob = 0.5 + 0.5 / (1.0 + exp(-10.0 * (data.testContrasts(baseIndex, data.testIndex) - ...
                    data.testContrasts(baseIndex, 3)) / app.baseContrasts(baseIndex)));
                hit = rand(1,1) < prob;
            else
                if strcmp(app.theKey, 'left')
                    hit = data.stimParams.changeSide == 0;
                elseif strcmp(app.theKey, 'right')
                    hit = data.stimParams.changeSide == 1;
                end
            end
            if (hit == 1)
                data.hits(baseIndex, data.testIndex) = data.hits(baseIndex, data.testIndex) + hit;
                sound(data.tones(2, :), data.sampFreqHz);
            else
                sound(data.tones(1, :), data.sampFreqHz);
            end
            data.trialsDone(baseIndex, data.testIndex) = data.trialsDone(baseIndex, data.testIndex) + 1;
            data.trialStartTimeS = 0;
            data.stimStartTimeS = 0;
            app.taskState = ctTaskState.taskStartTrial;
            if data.doStim
                clearScreen(app.stimuli);
            end
            handles = ctDrawHitRates(app, handles, false);            
            % Check whether we are done with all the trials
            if sum(data.trialsDone(baseIndex, :)) >= data.stimParams.stimReps * data.numIncrements
                if (~app.testMode)                         % if we're not in test mode, we're done testing
                    app.taskState = ctTaskState.taskStopRunning;
                else                                        % if we're testing, see if there are more to do
                    if sum(sum(data.trialsDone)) >=  data.stimParams.stimReps * data.numIncrements * app.numBases
                        app.taskState = ctTaskState.taskStopRunning;
                    else                                    % more to do, try the next multiplier
                        while sum(data.trialsDone(baseIndex, :)) >= data.stimParams.stimReps * data.numIncrements
                            baseIndex = mod(baseIndex, app.numBases) + 1;
                        end
                        app.baseContrastMenu.Value = app.baseContrastMenu.Items{baseIndex};
                    end
                end
            end     
        case ctTaskState.taskStopRunning
            if data.doStim
                clearScreen(app.stimuli);
            end
            ctDrawStatusText(app, handles, 'idle');
            set(app.runButton, 'text', 'Run', 'backgroundColor', 'green');
            ctControlState(handles, 'on', {handles.runButton});
            app.taskState = ctTaskState.taskStopped;
    end
end