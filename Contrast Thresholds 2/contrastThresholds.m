function varargout = contrastThresholds(varargin)
    % contrastThreshold MATLAB code for contrastThresholds.fig
    %      contrastThreshold, by itself, creates a new contrastThreshold or raises the existing
    %      singleton*.
    %
    %      H = contrastThreshold returns the handle to a new contrastThreshold or the handle to
    %      the existing singleton*.
    %
    %      contrastThreshold('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in contrastThreshold.M with the given input arguments.
    %
    %      contrastThreshold('Property','Value',...) creates a new contrastThreshold or raises
    %      the existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before contrastThresholds_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to contrastThresholds_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Need to add save image and save data buttons
    % perhaps make the trial function a timer.

    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @openContrastThresholds, ...
                       'gui_OutputFcn',  @initContrastThresholds, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
end

% --- Executes on button press in clearDataButton.
function clearDataCallback(hObject, ~, handles)
    baseIndex = get(handles.baseContrastMenu, 'value');
    strings = get(handles.baseContrastMenu, 'string');
    originalSize = get(0, 'DefaultUIControlFontSize');
    set(0, 'DefaultUIControlFontSize', 14);
    selection = questdlg(...
                sprintf('Really clear data for %s base contrast? (This cannot be undone).', strings{baseIndex}),...
                'Clear Data', 'Yes', 'No', 'Yes');
    set(0, 'DefaultUIControlFontSize', originalSize);
    if strcmp(selection, 'Yes')
        clearAll(handles.data, handles.baseContrastMenu, handles.resultsTable);
        drawHitRates(handles);
        guidata(hObject, handles);
    end
end

function handles = drawHitRates(handles)
    baseIndex = get(handles.baseContrastMenu, 'value');
    x = handles.data.baseContrasts' * handles.data.multipliers;
    hitRate = zeros(size(handles.data.trialsDone));
    errNeg = zeros(size(handles.data.trialsDone));
    errPos = zeros(size(handles.data.trialsDone));
    pci = zeros(size(handles.data.trialsDone, 1), size(handles.data.trialsDone, 2), 2);
    for i = 1:(size(handles.data.trialsDone, 1)) 
        [hitRate(i,:), pci(i,:,:)] = binofit(handles.data.hits(i, :), handles.data.trialsDone(i, :));
        errNeg(i, :) = hitRate(i, :) - pci(i, :, 1);
        errPos(i, :) = pci(i, :, 2) - hitRate(i, :);
        % If we have enough blocks, fit a logistic functions.  Include 0.5
        % performance at base contrast
        if i == baseIndex
            blocksDone = floor(mean(handles.data.trialsDone(i, :)));
            tableData = get(handles.resultsTable,'Data');
            tableData{1, i} = sprintf('%.0f', blocksDone);
            if blocksDone > handles.data.blocksFit(i) && blocksDone > 5 
                xData = [handles.data.baseContrasts(i) (handles.data.baseContrasts(i) * handles.data.multipliers)];
                yData = [0.5 hitRate(i,:)];
                x0 = [xData(ceil(length(xData) / 2)); 5];
                lowBounds = [handles.data.baseContrasts(i); 1];
                highBounds = [5; 1000];
                fun=@(params, xData) 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData - params(1))));
                options = optimset('Display', 'off');
                [params, ~] = lsqcurvefit(fun, x0, xData, yData, lowBounds, highBounds, options);
                handles.data.curveFits(i, :) = 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData(2:end) - params(1))));
                handles.data.blocksFit(i) = blocksDone;
                tableData{2, i} = sprintf('%.1f%%', params(1) * 100.0);
                tableData{3, i} = sprintf('%.1f%%', (params(1) - handles.data.baseContrasts(i)) * 100.0);
                tableData{4, i} = sprintf('%.2f', (params(1) / handles.data.baseContrasts(i)));
            end
            set(handles.resultsTable, 'Data', tableData); 
        end
    end
    errorbar(x', hitRate', errNeg', errPos', 'o');
    hold on;
    plot(x', handles.data.curveFits', '-');
    plot(repmat(handles.data.baseContrasts, 2, 1), repmat([0; 1], 1, 4));
    axis([0.05, 1.0, 0.0 1.0]);
    set (handles.axes1, 'xGrid', 'on', 'yGrid', 'off');
    set(handles.axes1, 'yTick', [0.0; 0.2; 0.4; 0.6; 0.8; 1.0]);
    set(handles.axes1, 'yTickLabel', [0; 20; 40; 60; 80; 100]);
    set(handles.axes1, 'xTick', [0.05; 0.06; 0.07; 0.08; 0.09; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.8; 1.0]);
    set(handles.axes1, 'xTickLabel', [5; 6; 7; 8; 9; 10; 20; 30; 40; 50; 60; 80; 100]);
    set(gca,'xscale','log');
    xlabel('stimulus contrast');
    ylabel('percent correct');
    hold off;
end

function drawStatusText(handles, status)
    runString = 'Status: Running (''escape'' to quit)';
    switch status
        case 'idle'
            runString = 'Status: Waiting to run';
            statusString = '';
        case 'wait'
            statusString = '     Waiting to start trial (hit a key)';
        case 'run'
            statusString = '     Running trial';
        case 'response'
            statusString = '     Waiting for response';
        case 'intertrial'
            statusString = '     Waiting intertrial interval';
    end
    baseIndex = get(handles.baseContrastMenu, 'value');
    trialsPerBlock = size(handles.data.trialsDone, 2);
    blocksDone = min(handles.data.trialsDone(baseIndex, :));
    undone = find(handles.data.trialsDone(baseIndex, :) == blocksDone);
    set(handles.statusText, 'string', {runString, statusString, '', ...
           sprintf('      Trial %d of %d', trialsPerBlock - length(undone) + 1, trialsPerBlock)});
    drawnow;
end

% --- Outputs from this function are returned to the command line.
function varargout = initContrastThresholds(~, ~, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;  
    get(handles.runButton, 'UserData');
    buttonStruct.keyDown = '';                                            % UserDate needs to be a struct
    set(handles.runButton, 'UserData', buttonStruct, 'String', 'Start','BackgroundColor', 'green');
end

% --- Executes just before contrastThresholds is made visible.
function openContrastThresholds(hObject, ~, handles, varargin)

    rng('shuffle');
    handles.data = ctTaskData(handles.baseContrastMenu);
    handles.output = hObject;                                                   % select default command line output
    handles.stimuli = ctStimuli;
    drawStatusText(handles, 'idle');
    movegui(handles.figure1,'southeast');
    set(handles.figure1, 'visible', 'on');
    guidata(hObject, handles);                                                   % save the selection
end

%% runButton_Callback responds to stop/start button
function runButton_Callback(hObject, ~, handles)

    % if we are running, just set the abort flag
    if strcmp(get(hObject, 'String'), 'Stop')
        buttonStruct.keyDown = 'abort';
        set(hObject, 'UserData', buttonStruct);
        return;
    end
    buttonStruct.keyDown = '';
    set(hObject, 'UserData', buttonStruct);
   
    % start running
    set(hObject, 'string', 'Stop','backgroundColor', 'red');
    set(handles.stimRepsTextBox, 'enable', 'off');
    set(handles.stimDurText, 'enable', 'off');
    set(handles.preStimTimeText, 'enable', 'off');
    set(handles.baseContrastMenu, 'enable', 'off');
    set(handles.clearDataButton, 'enable', 'off');
    drawnow;
    
    data = handles.data;
    stimParams.stimReps = get(handles.stimRepsTextBox, 'value');
    stimParams.stimDurS = get(handles.stimDurText, 'value');
    baseIndex = get(handles.baseContrastMenu, 'value');
    baseContrast = data.baseContrasts(baseIndex);
    stopTimer = timer('name', 'stopTimer', 'executionMode', 'fixedRate', 'period', 0.1, 'UserData', ...
        hObject, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@stopCheck}, 'startDelay', 0.1); 
    start(stopTimer);
    theKey = '';
    while ~strcmp(theKey, 'abort')
        % Pick a trial to do
        blocksDone = min(data.trialsDone(baseIndex, :));
        undone = find(data.trialsDone(baseIndex, :) == blocksDone);
        multIndex = undone(ceil(length(undone) * (rand(1, 1))));
        changeSide = floor(2 * rand(1, 1));       
        
        % Draw dark gray fixspot and wait for keystroke
        sound(data.tones(3, :), data.sampFreqHz);
        if data.doStim
            doFixSpot(handles.stimuli, 0.65);
            drawStatusText(handles, 'wait')
        end
        while ~data.testMode && currentKey(hObject) == ''
        end
        theKey = currentKey(hObject);
        if ~strcmp(theKey, 'abort') && data.doStim
        % Draw the base stimuli with a white fixspot
            drawStatusText(handles, 'run')
            stimParams.leftContrast = baseContrast;
            stimParams.rightContrast = baseContrast;
            doStimulus(handles.stimuli, stimParams);                        % takes some time, so get new theKey
            theKey = currentKey(hObject);
        end
        if ~strcmp(theKey, 'abort')
        % Draw the test stimuli, followed by the gray fixspot
            if (changeSide == 0)
                stimParams.leftContrast = baseContrast * data.multipliers(multIndex);
                stimParams.rightContrast = baseContrast;
            else
                stimParams.leftContrast = baseContrast;
                stimParams.rightContrast = baseContrast * data.multipliers(multIndex);
            end
            if data.doStim
                doStimulus(handles.stimuli, stimParams);
                doFixSpot(handles.stimuli, 0.0);
                drawStatusText(handles, 'response')
                theKey = currentKey(hObject);
           end
        end
        % Get reponse from subject
        if ~strcmp(theKey, 'abort')
            hit = -1;
            responsePending = true;
            if data.testMode
                prob = 0.5 + 0.5 / (1.0 + exp(-10.0 * (data.multipliers(multIndex) - data.multipliers(3))));
                hit = rand(1,1) < prob;
                responsePending = false;
            end
            while responsePending
                theKey = currentKey(hObject);
                if strcmp(theKey, 'abort')
                    responsePending = false;
                else
                    if strcmp(theKey, 'left')
                        hit = changeSide == 0;
                    elseif strcmp(theKey, 'right')
                        hit = changeSide == 1;
                    end
                    responsePending = false;
                end
            end
            if (hit >= 0)
                if (hit == 1)
                    data.hits(baseIndex, multIndex) = data.hits(baseIndex, multIndex) + hit;
                    sound(data.tones(2, :), data.sampFreqHz);
                else
                    sound(data.tones(1, :), data.sampFreqHz);
                end
                data.trialsDone(baseIndex, multIndex) = data.trialsDone(baseIndex, multIndex) + 1;
            end
        end
        if data.doStim
            clearScreen(handles.stimuli);
        end
        handles = drawHitRates(handles);
        % Check whether we are done with all the trials
%         stimReps = get(handles.stimRepsTextBox, 'value');
        if sum(data.trialsDone(baseIndex, :)) >= stimParams.stimReps * data.numMultipliers
            if (~data.testMode)                      % if we're not in test mode, we're done testing
                theKey = 'abort';
            else                                        % if we're testing, see if there are more to do
                if sum(sum(data.trialsDone)) >=  stimParams.stimReps * data.numMultipliers * handles.numBases
                    theKey = 'abort';
                else                                    % more to do, try the next multiplier
                    while sum(data.trialsDone(baseIndex, :)) >= stimParams.stimReps * data.numMultipliers
                        baseIndex = mod(baseIndex, handles.numBases) + 1;
                    end
                    set(handles.baseContrastMenu, 'value', baseIndex);
                end
            end
        end
        % Update the status text
        if ~strcmp(theKey, 'abort')
            drawStatusText(handles, 'intertrial')
            if (~data.testMode && data.doStim)
                pause(get(handles.preStimTimeText, 'value'));          % interstimulus interval
            end
        end
    end
    if data.doStim
        clearScreen(handles.stimuli);
    end  
    stop(stopTimer);                                                        % stop/delete timer
    delete(stopTimer);        

    set(handles.stimRepsTextBox, 'enable', 'on');
    set(handles.stimDurText, 'enable', 'on');
    set(handles.preStimTimeText, 'enable', 'on');
    set(handles.baseContrastMenu, 'enable', 'on');
    set(handles.clearDataButton, 'enable', 'on');

    drawStatusText(handles, 'idle')
    set(handles.runButton, 'string', 'Run','backgroundColor', 'green');
    set(handles.runButton, 'enable', 'on');
    drawnow;
    guidata(hObject, handles);                          % save the changes
end

%% currentKey report which key is down
function keyDown = currentKey(hObject)
   
    buttonStruct = get(hObject, 'UserData');
    keyDown = buttonStruct.keyDown;
end

%% stopCheck monitor and record the most recent keystroke
function stopCheck(obj, event)                                              %#ok<*INUSD>

    runButton = get(obj, 'UserData');
    buttonStruct = get(runButton, 'UserData');                                    % abort commands are latched
    if strcmp(buttonStruct.keyDown, 'abort')
        return;
    end
    [~, ~, keyCode] = KbCheck(-1);
    if keyCode(KbName('Escape'));
        buttonStruct.keyDown = 'abort';
    elseif keyCode(KbName('LeftArrow'))
        buttonStruct.keyDown = 'left';
    elseif keyCode(KbName('RightArrow'))
        buttonStruct.keyDown = 'right';
    else
        buttonStruct.keyDown = '';
    end
    set(runButton, 'UserData', buttonStruct);
end

%% respond to a GUI close request 
function windowCloseRequest(hObject, eventdata, handles)

    % fist check whether the task is running
    if strcmp(get(handles.runButton, 'String'), 'Stop')
        return;
    end

%     selection = questdlg('Really exit Contrast Threshold?', 'Exit Request', 'Yes', 'No', 'Yes');

    selection = 'Yes';
      
    switch selection,
    case 'Yes',
        handles = guidata(hObject);
        cleanup(handles.stimuli);
        delete(hObject);
    case 'No'
        return
    end
end
