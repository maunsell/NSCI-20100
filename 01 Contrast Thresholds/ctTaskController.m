
%% taskController: function to handle transition of task state.
function ctTaskController(obj, ~)
    handles = obj.UserData;
    data = handles.data;
    switch data.taskState
        case ctTaskState.taskStopped
            % do nothing
        case ctTaskState.taskStartRunning
            set(handles.runButton, 'string', 'Stop','backgroundColor', 'red');
            ctControlState(handles, 'off', {handles.runButton});
            data.trialStartTimeS = 0;
            data.stimStartTimeS = 0;
            data.taskState = ctTaskState.taskStartTrial;
        case ctTaskState.taskStartTrial
           if data.trialStartTimeS == 0                                   % start the trial
                ctDrawStatusText(handles, 'intertrial');
                data.trialStartTimeS = clock;
                data.stimParams.stimReps = str2num(get(handles.stimRepsText, 'string'));
                data.stimParams.prestimDurS = str2num(get(handles.prestimDurText, 'string'));
                data.stimParams.stimDurS = str2num(get(handles.stimDurText, 'string'));
                data.stimParams.intertrialDurS = str2num(get(handles.intertrialDurText, 'string'));
                baseIndex = get(handles.baseContrastMenu, 'value');
                data.stimParams.changeSide = floor(2 * rand(1, 1));
            elseif (etime(clock, data.trialStartTimeS) > data.stimParams.intertrialDurS) || ~data.doStim
               % Draw dark gray fixspot
               sound(data.tones(3, :), data.sampFreqHz);
                if data.doStim
                    doFixSpot(handles.stimuli, 0.65);
                    ctDrawStatusText(handles, 'wait');
                end
                if ~data.testMode
                    data.taskState = ctTaskState.taskWaitGoKey;
                else
                    data.taskState = ctTaskState.taskDoStim;
                end
            end
        case ctTaskState.taskWaitGoKey
           % just wait for user to hit the down arrow button to start the stimulus
        case ctTaskState.taskDoStim
           if data.stimStartTimeS == 0                                     % start the stimulus
                baseIndex = get(handles.baseContrastMenu, 'value');
                baseContrast = data.baseContrasts(baseIndex);
                data.stimStartTimeS = clock;
                if data.doStim                              % Draw the base stimuli with a white fixspot
                    ctDrawStatusText(handles, 'run')
                    data.stimParams.leftContrast = baseContrast;
                    data.stimParams.rightContrast = baseContrast;
                    doStimulus(handles.stimuli, data.stimParams);           % display the base contrast
                end
            elseif etime(clock, data.stimStartTimeS) > data.stimParams.prestimDurS
               % Draw the test stimuli, followed by the gray fixspot
                baseIndex = get(handles.baseContrastMenu, 'value');
                baseContrast = data.baseContrasts(baseIndex);
                blocksDone = min(data.trialsDone(baseIndex, :));
                undone = find(data.trialsDone(baseIndex, :) == blocksDone);
                data.multIndex = undone(ceil(length(undone) * (rand(1, 1))));
                if (data.stimParams.changeSide == 0)
                    data.stimParams.leftContrast = baseContrast * data.multipliers(data.multIndex);
                    data.stimParams.rightContrast = baseContrast;
                else
                    data.stimParams.leftContrast = baseContrast;
                    data.stimParams.rightContrast = baseContrast * data.multipliers(data.multIndex);
                end
                if data.doStim
                    doStimulus(handles.stimuli, data.stimParams);           % display the increment stimulus
                    doFixSpot(handles.stimuli, 0.0);
                    ctDrawStatusText(handles, 'response');
                end
                data.taskState = ctTaskState.taskWaitResponse;
            end
        case ctTaskState.taskWaitResponse
            if data.testMode
                data.taskState = ctTaskState.taskProcessResponse;
            end
        case ctTaskState.taskProcessResponse
            baseIndex = get(handles.baseContrastMenu, 'value');
            blocksDone = min(data.trialsDone(baseIndex, :));
            undone = find(data.trialsDone(baseIndex, :) == blocksDone);
            if data.testMode
                prob = 0.5 + 0.5 / (1.0 + exp(-10.0 * (data.multipliers(data.multIndex) - data.multipliers(3))));
                hit = rand(1,1) < prob;
            else
                if strcmp(data.theKey, 'left')
                    hit = data.stimParams.changeSide == 0;
                elseif strcmp(data.theKey, 'right')
                    hit = data.stimParams.changeSide == 1;
                end
            end
            if (hit == 1)
                data.hits(baseIndex, data.multIndex) = data.hits(baseIndex, data.multIndex) + hit;
                sound(data.tones(2, :), data.sampFreqHz);
            else
                sound(data.tones(1, :), data.sampFreqHz);
            end
            data.trialsDone(baseIndex, data.multIndex) = data.trialsDone(baseIndex, data.multIndex) + 1;
            data.trialStartTimeS = 0;
            data.stimStartTimeS = 0;
            data.taskState = ctTaskState.taskStartTrial;
            if data.doStim
                clearScreen(handles.stimuli);
            end
            handles = ctDrawHitRates(handles, false);
            % Check whether we are done with all the trials
            if sum(data.trialsDone(baseIndex, :)) >= data.stimParams.stimReps * data.numMultipliers
                if (~data.testMode)                         % if we're not in test mode, we're done testing
                    data.taskState = ctTaskState.taskStopRunning;
                else                                        % if we're testing, see if there are more to do
                    if sum(sum(data.trialsDone)) >=  data.stimParams.stimReps * data.numMultipliers * data.numBases
                        data.taskState = ctTaskState.taskStopRunning;
                    else                                    % more to do, try the next multiplier
                        while sum(data.trialsDone(baseIndex, :)) >= data.stimParams.stimReps * data.numMultipliers
                            baseIndex = mod(baseIndex, data.numBases) + 1;
                        end
                        set(handles.baseContrastMenu, 'value', baseIndex);
                    end
                end
            end     
        case ctTaskState.taskStopRunning
            if data.doStim
                clearScreen(handles.stimuli);
            end
            ctDrawStatusText(handles, 'idle');
            set(handles.runButton, 'string', 'Run','backgroundColor', 'green');
            ctControlState(handles, 'on', {handles.runButton});
            data.taskState = ctTaskState.taskStopped;
    end
end