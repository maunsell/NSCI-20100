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
        ctDrawHitRates(handles, true);
        guidata(hObject, handles);
    end    
end

% %% currentKey report which key is down
% function keyDown = currentKey(hObject)
%     buttonStruct = get(hObject, 'UserData');
%     keyDown = buttonStruct.keyDown;
% end

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
        if data.taskState ~= ctTaskState.taskStopped
            data.taskState = ctTaskState.taskStopRunning;
        elseif keyCode(KbName('LeftShift'))
            showHideButton_Callback(handles.showHideButton, 0, handles);      
        end
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

% --- Executes on button press in loadDataButton.
function loadDataButton_Callback(hObject, ~, handles)
    cleanup(handles.stimuli);                       % remove stimulus display
    ctControlState(handles, 'off', {handles.loadDataButton});
    [fileName, filePath] = uigetfile('*.mat', 'Load Matlab Data Workspace', '~/Desktop/');
    if fileName ~= 0
        stop(timerfind);                                            % stop/delete timers; pause data stream
        delete(timerfind);      
        load([filePath fileName]);
        handles.data = d;
        handles = ctDrawHitRates(handles, true);
        taskTimer = timer('name', 'TaskTimer', 'executionMode', 'fixedRate', 'period', 0.1,... 
            'UserData', handles, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@ctTaskController});
        keyTimer = timer('name', 'KeyTimer', 'executionMode', 'fixedRate', 'period', 0.1,... 
            'UserData', handles, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@keyboardCheck});
        start(taskTimer);
        start(keyTimer);
    end
    handles.stimuli = ctStimuli();                  % restore stimulus display
    set(handles.runButton, 'backgroundColor', 'green');
    ctControlState(handles, 'on', {handles.loadDataButton});
    guidata(hObject, handles);                                      % save the selections
end

%% --- Executes just before contrastThresholds is made visible.
function openContrastThresholds(hObject, ~, handles, varargin)
    rng('shuffle');
    handles.data = ctTaskData(handles.baseContrastMenu);
    handles.output = hObject;                                                   % select default command line output
    handles.stimuli = ctStimuli;
    
    testStimuli(handles.stimuli, handles);
    
    
    ctDrawStatusText(handles, 'idle');
    movegui(handles.figure1, 'northwest');
    set(handles.figure1, 'visible', 'on');
    guidata(hObject, handles);                                                   % save the selection
    
    KbName('UnifyKeyNames');
    taskTimer = timer('name', 'TaskTimer', 'executionMode', 'fixedRate', 'period', 0.1,... 
        'UserData', handles, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@ctTaskController});
    keyTimer = timer('name', 'KeyTimer', 'executionMode', 'fixedRate', 'period', 0.1,... 
        'UserData', handles, 'errorFcn', {@timerErrorFcnStop, handles}, 'timerFcn', {@keyboardCheck});
    start(taskTimer);
    start(keyTimer);
end

%% runButton_Callback responds to stop/start button
function runButton_Callback(hObject, ~, handles)      
    if strcmp(get(hObject, 'String'), 'Stop')           % if we are running, just set the abort flag
        handles.data.taskState = ctTaskState.taskStopRunning;
    else
        baseIndex = get(handles.baseContrastMenu, 'value');
        stimReps = str2num(get(handles.stimRepsText, 'string'));
        data = handles.data;
        if sum(data.trialsDone(baseIndex, :)) < stimReps * data.numIncrements
            data.taskState = ctTaskState.taskStartRunning;
        else
            contrastStrings = get(handles.baseContrastMenu, 'string');
            originalSize = get(0, 'DefaultUIControlFontSize');
            set(0, 'DefaultUIControlFontSize', 14);
            helpdlg(sprintf('%d reps of %s contrast have already been done', stimReps, contrastStrings{baseIndex}));
            set(0, 'DefaultUIControlFontSize', originalSize);
        end
    end
    guidata(hObject, handles);                          % save the changes
end
%% saveDataButton_Callback responds to save button
% --- Executes on button press in saveDataButton.
function saveDataButton_Callback(hObject, ~, handles)
    cleanup(handles.stimuli);
    ctControlState(handles, 'off', {handles.saveDataButton});
    [fileName, filePath] = uiputfile('*.mat', 'Save Matlab Data Workspace', '~/Desktop/ContrastData.mat');
    if fileName ~= 0
        d = handles.data;
        save([filePath fileName], 'd');
    end
    handles.stimuli = ctStimuli();    
    set(handles.runButton, 'backgroundColor', 'green');
    ctControlState(handles, 'on', {handles.saveDataButton});
end

%% --- Respond to button press in savePlotsButton.
function savePlotsButton_Callback(hObject, ~, handles)
    cleanup(handles.stimuli);
    ctControlState(handles, 'off', {handles.savePlotsButton});
    [fileName, filePath] = uiputfile('*.pdf', 'Save Window Image as PDF', '~/Desktop/ContrastThresholds.pdf');
    if fileName ~= 0
        set(handles.figure1, 'PaperUnits', 'inches');
        figurePos = get(handles.figure1, 'position');
        widthInch = figurePos(3) / 72;
        heightInch = figurePos(4) / 72;
        set(handles.figure1, 'PaperSize', [widthInch + 1.0, heightInch + 1.0]);
        set(handles.figure1, 'PaperPosition', [0.5, 0.5, widthInch, heightInch]);
        sprintf(handles.figure1, '-dpdf', '-r600', [filePath fileName]);
    end
    handles.stimuli = ctStimuli();
    set(handles.runButton, 'backgroundColor', 'green');
    ctControlState(handles, 'on', {handles.savePlotsButton});
end

%% respond to the showHideButton
function showHideButton_Callback(hObject, ~, handles)      
    if strcmp(get(hObject, 'String'), 'Hide Display')
        cleanup(handles.stimuli);
        set(hObject, 'string', 'Show Display','backgroundColor', 'red');
        set(handles.runButton, 'string', 'Run','backgroundColor', [0.9412 0.9412 0.9412]);
        state = 'off';
    elseif strcmp(get(hObject, 'String'), 'Show Display')
        handles.stimuli = ctStimuli();
        set(hObject, 'string', 'Hide Display','backgroundColor', [0.9412 0.9412 0.9412]);
        set(handles.runButton, 'string', 'Run','backgroundColor', 'green');
        state = 'on';
    end
    ctControlState(handles, state, {handles.showHideButton});
    guidata(hObject, handles);                          % save the changes
end

%% respond to the a timer error
function timerErrorFcn(obj, event, handles)
    disp('timer error');
end

%% respond to a GUI close request 
function windowCloseRequest(hObject, ~, handles)

    % first check whether the task is running
    if strcmp(get(handles.runButton, 'String'), 'Stop')
        return;
    end
    originalSize = get(0, 'DefaultUIControlFontSize');
    set(0, 'DefaultUIControlFontSize', 14);
    selection = questdlg('Really exit Contrast Threshold? Unsaved data will be lost.',...
        'Exit Request', 'Yes', 'No', 'Yes');      
    set(0, 'DefaultUIControlFontSize', originalSize);
    switch selection
    case 'Yes'
        stop(timerfind);
        delete(timerfind);
        handles = guidata(hObject);
        cleanup(handles.stimuli);
        delete(hObject);
    case 'No'
        return
    end
end
