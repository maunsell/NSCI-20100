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
        ctDrawHitRates(handles);
        guidata(hObject, handles);
    end
end

%% --- Outputs from this function are returned to the command line.
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

%% stopCheck monitor and record the most recent keystroke
function keyboardCheck(obj, event)                                              %#ok<*INUSD>

    handles = get(obj, 'UserData');
    data = handles.data;
    [~, ~, keyCode] = KbCheck(-1);
    if keyCode(KbName('ESCAPE'))
        data.taskState = ctTaskState.taskStopRunning;
        disp('ESCAPE')
    elseif data.taskState == ctTaskState.taskWaitGoKey
        if keyCode(KbName('DownArrow'))
            data.taskState = ctTaskState.taskDoStim;
        end
    elseif data.taskState == ctTaskState.taskWaitResponse
        if keyCode(KbName('LeftArrow'))
            data.theKey = 'left';
            data.taskState = ctTaskState.taskProcessResponse;
        elseif keyCode(KbName('RightArrow'))
            data.theKey = 'right';
            data.taskState = ctTaskState.taskProcessResponse;
        end
    end    
end

%% --- Executes just before contrastThresholds is made visible.
function openContrastThresholds(hObject, ~, handles, varargin)

    rng('shuffle');
    handles.data = ctTaskData(handles.baseContrastMenu);
    handles.output = hObject;                                                   % select default command line output
    handles.stimuli = ctStimuli;
    ctDrawStatusText(handles, 'idle');
    movegui(handles.figure1,'southeast');
    set(handles.figure1, 'visible', 'on');
    guidata(hObject, handles);                                                   % save the selection
    
    taskTimer = timer('name', 'TaskTimer', 'executionMode', 'fixedRate', 'period', 0.1,... 
        'UserData', handles, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@ctTaskController});
    keyTimer = timer('name', 'KeyTimer', 'executionMode', 'fixedRate', 'period', 0.1,... 
        'UserData', handles, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@keyboardCheck});
    start(keyTimer);
    start(taskTimer);
end

%% runButton_Callback responds to stop/start button
function runButton_Callback(hObject, ~, handles)
        

    handles.data.taskState = ctTaskState.taskStopped;

    % if we are running, just set the abort flag
    if strcmp(get(hObject, 'String'), 'Stop')
        handles.data.taskState = ctTaskState.taskStopRunning;
%         while (handles.data.taskState ~= ctTaskState.taskStopped)
%             pause(0.1);
%         end
%         set(handles.runButton, 'string', 'Run','backgroundColor', 'green');
%         set(handles.runButton, 'enable', 'on');
%         drawnow;

%         buttonStruct.keyDown = 'abort';
%         set(hObject, 'UserData', buttonStruct);
    else 
%         set(handles.runButton, 'string', 'Stop','backgroundColor', 'red');
%         set(handles.runButton, 'enable', 'off');
%         drawnow;
        handles.data.taskState = ctTaskState.taskStartRunning;
        disp('runButton setting taskState to taskStartRunning');
    end
    guidata(hObject, handles);                          % save the changes   end
    
    
%     buttonStruct.keyDown = '';
%     set(hObject, 'UserData', buttonStruct);
   
    % start running
%     set(hObject, 'string', 'Stop','backgroundColor', 'red');
%     set(handles.stimRepsTextBox, 'enable', 'off');
%     set(handles.stimDurText, 'enable', 'off');
%     set(handles.preStimTimeText, 'enable', 'off');
%     set(handles.baseContrastMenu, 'enable', 'off');
%     set(handles.clearDataButton, 'enable', 'off');
%     set(handles.savePlotsButton, 'enable', 'off');
%     set(handles.saveDataButton, 'enable', 'off');
%     drawnow;
    
%     data = handles.data;
%     stimParams.stimReps = get(handles.stimRepsTextBox, 'value');
%     stimParams.stimDurS = get(handles.stimDurText, 'value');
%     baseIndex = get(handles.baseContrastMenu, 'value');
%     baseContrast = data.baseContrasts(baseIndex);
%     stopTimer = timer('name', 'stopTimer', 'executionMode', 'fixedRate', 'period', 0.1, 'UserData', ...
%         hObject, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@stopCheck}, 'startDelay', 0.1); 
%     start(stopTimer);
%     theKey = '';
%     while ~strcmp(theKey, 'abort')
%         % Pick a trial to do
%         blocksDone = min(data.trialsDone(baseIndex, :));
%         undone = find(data.trialsDone(baseIndex, :) == blocksDone);
%         multIndex = undone(ceil(length(undone) * (rand(1, 1))));
%         changeSide = floor(2 * rand(1, 1));       
%         
%         % Draw dark gray fixspot and wait for keystroke
%         sound(data.tones(3, :), data.sampFreqHz);
%         if data.doStim
%             doFixSpot(handles.stimuli, 0.65);
%             drawStatusText(handles, 'wait')
%         end
%         while ~data.testMode && currentKey(hObject) == ''
%         end
%         theKey = currentKey(hObject);
%         if ~strcmp(theKey, 'abort') && data.doStim
%         % Draw the base stimuli with a white fixspot
%             drawStatusText(handles, 'run')
%             stimParams.leftContrast = baseContrast;
%             stimParams.rightContrast = baseContrast;
%             doStimulus(handles.stimuli, stimParams);                        % takes some time, so get new theKey
%             theKey = currentKey(hObject);
%         end
%         if ~strcmp(theKey, 'abort')
%         % Draw the test stimuli, followed by the gray fixspot
%             if (changeSide == 0)
%                 stimParams.leftContrast = baseContrast * data.multipliers(multIndex);
%                 stimParams.rightContrast = baseContrast;
%             else
%                 stimParams.leftContrast = baseContrast;
%                 stimParams.rightContrast = baseContrast * data.multipliers(multIndex);
%             end
%             if data.doStim
%                 doStimulus(handles.stimuli, stimParams);
%                 doFixSpot(handles.stimuli, 0.0);
%                 drawStatusText(handles, 'response')
%                 theKey = currentKey(hObject);
%            end
%         end
%         % Get reponse from subject
%         if ~strcmp(theKey, 'abort')
%             hit = -1;
%             responsePending = true;
%             if data.testMode
%                 prob = 0.5 + 0.5 / (1.0 + exp(-10.0 * (data.multipliers(multIndex) - data.multipliers(3))));
%                 hit = rand(1,1) < prob;
%                 responsePending = false;
%             end
%             while responsePending
%                 theKey = currentKey(hObject);
%                 if strcmp(theKey, 'abort')
%                     responsePending = false;
%                 else
%                     if strcmp(theKey, 'left')
%                         hit = changeSide == 0;
%                     elseif strcmp(theKey, 'right')
%                         hit = changeSide == 1;
%                     end
%                     responsePending = false;
%                 end
%             end
%             if (hit >= 0)
%                 if (hit == 1)
%                     data.hits(baseIndex, multIndex) = data.hits(baseIndex, multIndex) + hit;
%                     sound(data.tones(2, :), data.sampFreqHz);
%                 else
%                     sound(data.tones(1, :), data.sampFreqHz);
%                 end
%                 data.trialsDone(baseIndex, multIndex) = data.trialsDone(baseIndex, multIndex) + 1;
%             end
%         end
%         if data.doStim
%             clearScreen(handles.stimuli);
%         end
%         handles = drawHitRates(handles);
%         % Check whether we are done with all the trials
% %         stimReps = get(handles.stimRepsTextBox, 'value');
%         if sum(data.trialsDone(baseIndex, :)) >= stimParams.stimReps * data.numMultipliers
%             if (~data.testMode)                      % if we're not in test mode, we're done testing
%                 theKey = 'abort';
%             else                                        % if we're testing, see if there are more to do
%                 if sum(sum(data.trialsDone)) >=  stimParams.stimReps * data.numMultipliers * handles.numBases
%                     theKey = 'abort';
%                 else                                    % more to do, try the next multiplier
%                     while sum(data.trialsDone(baseIndex, :)) >= stimParams.stimReps * data.numMultipliers
%                         baseIndex = mod(baseIndex, handles.numBases) + 1;
%                     end
%                     set(handles.baseContrastMenu, 'value', baseIndex);
%                 end
%             end
%         end
%         % Update the status text
%         if ~strcmp(theKey, 'abort')
%             drawStatusText(handles, 'intertrial')
%             if (~data.testMode && data.doStim)
%                 pause(get(handles.preStimTimeText, 'value'));          % interstimulus interval
%             end
%         end
%     end
%     if data.doStim
%         clearScreen(handles.stimuli);
%     end  
%     stop(stopTimer);                                                        % stop/delete timer
%     delete(stopTimer);        

%     set(handles.stimRepsTextBox, 'enable', 'on');
%     set(handles.stimDurText, 'enable', 'on');
%     set(handles.preStimTimeText, 'enable', 'on');
%     set(handles.baseContrastMenu, 'enable', 'on');
%     set(handles.clearDataButton, 'enable', 'on');
%     set(handles.savePlotsButton, 'enable', 'on');
%     set(handles.saveDataButton, 'enable', 'on');

%     drawStatusText(handles, 'idle')
%     set(handles.runButton, 'string', 'Run','backgroundColor', 'green');
%     set(handles.runButton, 'enable', 'on');
%     drawnow;
%     guidata(hObject, handles);                          % save the changes
end

% --- Executes on button press in saveDataButton.
function saveDataButton_Callback(hObject, ~, handles)

    [fileName, filePath] = uiputfile('*.mat', 'Save Matlab Data Workspace', '~/ContrastData.mat');
    if fileName ~= 0
        d = handles.data;
        p = properties(d);
        for i = 1:length(p)
            eval([p{i} '= d.' p{i} ';']);
            if i == 1
                eval(['save ' filePath fileName ' ' p{i} ';']);
            else
             	eval(['save ' filePath fileName ' ' p{i} ' -append ;']);
            end
            eval(['clear ' p{i} ';']);
        end
    end
    end

%% --- Respond to button press in savePlotsButton.
function savePlotsButton_Callback(hObject, ~, handles)
% hObject    handle to savePlotsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [fileName, filePath] = uiputfile('*.pdf', 'Save Window Image as PDF', '~/ContrastThresholds.pdf');
    if fileName ~= 0
        figurePos = get(handles.figure1, 'position');
        widthInch = figurePos(3) / 72;
        heightInch = figurePos(4) / 72;
        set(handles.figure1, 'PaperOrientation', 'landscape');
        set(handles.figure1, 'PaperUnits', 'inches');
%         set(handles.figure1, 'PaperSize', [heightInch + 2, widthInch + 2]);
%         set(handles.figure1, 'PaperPosition', [1, 5.5, widthInch, heightInch]);
        set(handles.figure1, 'PaperSize', [heightInch + 0.5, widthInch + 1.5]);
        set(handles.figure1, 'PaperPosition', [0.75, -2, widthInch, heightInch]);
        print(handles.figure1, '-dpdf', '-r600', [filePath fileName]);
    end
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
        stop(timerfind);
        delete(timerfind);
        handles = guidata(hObject);
        cleanup(handles.stimuli);
        delete(hObject);
    case 'No'
        return
    end
end
