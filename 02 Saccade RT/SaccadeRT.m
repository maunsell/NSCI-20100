function varargout = SaccadeRT(varargin)
% SaccadeRT displays an analog data stream from a LabJack U3
%
% EOG signals come through analog input channels 0 and 1 (AIN0 AIN1) on the LabJack. Connect LabJack DAC0/1 to AIN0/1
% for debugging with synthetic eye movements.
%
% Initialization code
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @openRT, ...
                       'gui_OutputFcn',  @initRT, ...
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

%% clearButton_Callback
function clearButton_Callback(hObject, eventdata, handles)                  

    originalSize = get(0, 'DefaultUIControlFontSize');
    set(0, 'DefaultUIControlFontSize', 14);
    selection = questdlg('Really clear all data? (This cannot be undone).', 'Clear Data', 'Yes', 'No', 'Yes');
    set(0, 'DefaultUIControlFontSize', originalSize);
    switch selection
        case 'Yes'
        clearAll(handles.saccades);
%         clearAll(handles.ampDur);
        for i = 1:handles.data.numTrialTypes
            clearAll(handles.rtDists{i});
        end
        clearAll(handles.data);
        plot(handles.posVelPlots, handles, 0, 0);
        set(handles.calibrationText, 'string', '');
        guidata(hObject, handles);
    end
end

%% closeRT: clean up
function closeRT(hObject, eventdata, handles)
    % this function is called  when the user closes the main window
    % close the timer and clear the LabJack handle
    %
    % fist check whether the task is running
    if strcmp(get(handles.startButton, 'String'), 'Stop')
        return;
    end
    originalSize = get(0, 'DefaultUIControlFontSize');
    set(0, 'DefaultUIControlFontSize', 14);
    selection = questdlg('Really exit? Unsaved data will be lost.',...
        'Exit Request', 'Yes', 'No', 'Yes');      
    set(0, 'DefaultUIControlFontSize', originalSize);
    switch selection
    case 'Yes'
        try delete(handles.visStim); catch, end
        try stop(timerfind); catch, end
        try delete(timerfind); catch, end
        try clear('handles.lbj'); catch, end
        delete(hObject);                                                            % close the program window
    case 'No'
        return
    end
end

%% collectData: function to collect data from LabJack
function collectData(obj, event)                                            %#ok<*INUSD>
% reads stream data from the LabJack
    handles = obj.UserData;
    data = handles.data;
    lbj = handles.lbj;                                                     % obj.UserData is pointer to handles
    switch data.dataState
        case RTDataState.dataIdle
            return;
        case RTDataState.dataCollect
            [dRaw, ~] = getStreamData(lbj);                                     %#ok<*NASGU> % get stream data
            numNew = min(length(dRaw), data.trialSamples - data.samplesRead);
            data.rawData(data.samplesRead + 1:data.samplesRead + numNew, :) = dRaw(1:numNew, :);
            data.samplesRead = data.samplesRead + numNew;
            if (data.samplesRead == data.trialSamples)
                tStart = tic;
                handles.lbj.verbose = 0;
                stopStream(handles.lbj);
                handles.lbj.verbose = 1;
                data.dataState = RTDataState.dataIdle;
                data.taskState = RTTaskState.taskEndtrial;
            end        
    end
end

%% --- Executes on button press in Filter60.
function Filter60Hz_Callback(hObject, eventdata, handles) 

    set60HzFilter(handles.data, get(hObject,'Value'));
end

%% initRT: initialization
function varargout = initRT(hObject, eventdata, handles)               %#ok<*INUSL>
% initialize application.  We need to set up GUI items  after the GUI has been
% created by after openRT function. This method gets called after the GUI is
% created but before control returns to the command line.
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    varargout{1} = handles.output;
    set(handles.startButton, 'String', 'Start','BackgroundColor', 'green');
%     addPsychtoolboxPaths;
end

%% loadDataButton_Callback
% --- Executes on button press in loadDataButton.
function loadDataButton_Callback(hObject, ~, handles) %#ok<*DEFNU>
%
    c = RTConstants;
    RTControlState(handles, 'off', {})
    [fileName, filePath] = uigetfile('*.mat', 'Load Matlab Data Workspace', '~/Desktop');
    if fileName ~= 0
        testMode = handles.data.testMode;                               % keep testMode across data loads
        load([filePath fileName]);
        handles.data = d;
        handles.data.testMode = testMode;                               % keep testMode across data loads
        handles.saccades = s;
        set(handles.calibrationText, 'string', sprintf('Calibration %.1f deg/V', handles.saccades.degPerV));
        handles.rtDists{1} = r1;
        handles.rtDists{2} = r2;
        handles.rtDists{3} = r3;
        
        % saved axes handles generally aren't valid if we are in a new run.
        % Load the handles with the current axes handles.
        
%         handles.ampDur.fHandle = handles.axes5;                         % loaded axes handle might be invalid
        handles.rtDists{1}.fHandle = handles.axes6;
        handles.rtDists{2}.fHandle = handles.axes7;
        handles.rtDists{3}.fHandle = handles.axes8;
        guidata(hObject, handles);                                      % save the selections
        
        [startIndex, endIndex] = processSignals(handles.saccades, d);
        plot(handles.posVelPlots, handles, startIndex, endIndex);
%         handles.ampDur.lastN = 0;                                       % force ampDur to plot
%         plotAmpDur(handles.ampDur);
        for i = 1:handles.data.numTrialTypes
            plot(handles.rtDists{i});
        end
    end
    RTControlState(handles, 'on', {})
end

%% openRT
% openRT: just before gui is made visible.
function openRT(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RT (see VARARGIN)

    % test mode requires connecting DAC0 to AIN0 and DAC1 to AIN1 on the LabJack
    if ~isempty(varargin)
        testMode = strcmp(varargin{1}, 'debug') || strcmp(varargin{1}, 'test');
    else
        testMode = false;
    end
    
    testMode = true;
    
    if testMode
        set(handles.warnText, 'string', 'Test Mode');
    end   
    handles.output = hObject;                                               % select default command line output
    handles.saccades = RTSaccades;
    set(hObject, 'CloseRequestFcn', {@closeRT, handles});                  % close function will close LabJack
    handles.lbj = setupLabJack();
    handles.data = RTTaskData(handles.lbj.numChannels, handles.lbj.SampleRateHz);
    handles.visStim = RTStimulus(handles.data.stepSizeDeg);
    handles.posVelPlots = RTPosVelPlots(handles);
%     handles.ampDur = RTAmpDur(handles.axes5, handles.data.offsetsDeg, handles.lbj.SampleRateHz);
    axes = [handles.axes6 handles.axes7 handles.axes8];
    handles.RTDist = cell(1, handles.data.numTrialTypes);
    for i = 1:length(axes)
        handles.rtDists{i} = RTDist(i, axes(i));
    end
    
    % set up test mode
    handles.data.testMode = testMode;
    if (handles.data.testMode)
        analogOut(handles.lbj, 0, 2.5);                                     % For debugging (AOuts to AIns)
    end
    movegui(hObject, 'northeast');
    guidata(hObject, handles);                                              % save the selection
end

%% PsychotoolboxPaths
function addPsychtoolboxPaths
    if ~exist('/Applications/Psychtoolbox/PsychAlpha','dir')
        printf('adding Psychtoolbox paths');
        list = genpath('/Applications/Psychtoolbox');
        folders = strsplit(list, pathsep);
        folders(contains(folders, '.svn')) = [];
        newlist = sprintf('%s:', folders{:});
        addpath(newlist);
    else
        printf('Psychtoolbox paths already set');
    end
end

%%sampleRateText_Callback
% function sampleRateText_Callback(hObject, eventdata, handles)
%     requestedRateHz = str2double(get(handles.sampleRateText, 'string'));
%     clippedRateHz = min([requestedRateHz, 1000, max(100, requestedRateHz)]);
%     if (clippedRateHz ~= requestedRateHz)
%         set(handles.sampleRateText, 'String', clippedRateHz);
%     end
%     if clippedRateHz ~= handles.data.sampleRateHz
%         setSampleRateHz(handles.data, clippedRateHz);
%         handles.lbj.SampleRateHz = clippedRateHz;
%         errorCode = streamConfigure(handles.lbj);
%         if errorCode > 0
%             fprintf(1,'RT: Unable to configure LabJack to new rate. Error %d.\n', errorCode);
%         end
%     end
% end

%% saveDataButton_Callback
function saveDataButton_Callback(hObject, eventdata, handles)
% Saving the workspace for a GUI isn't simple.  What we have accessible in this
% environment is mostly the handles.  If we save, it's an attempt to save
% handles, which doesn't work.  Instead, we get a list of all the properties
% from the RTTaskData class, and then use eval statement to assign those to
% local variable and save them (one by one).
    RTControlState(handles, 'off', {})
    [fileName, filePath] = uiputfile('*.mat', 'Save Matlab Data Workspace', '~/Desktop/RTData.mat');
    if fileName ~= 0
        d = handles.data;
        s = handles.saccades;
        r1 = handles.rtDists{1};
        r2 = handles.rtDists{2};
        r3 = handles.rtDists{3};
       save([filePath fileName], 'd', 's');
    end
    RTControlState(handles, 'on', {})
end

%% savePlotsButton_Callback
function savePlotsButton_Callback(hObject, eventdata, handles)
    RTControlState(handles, 'off', {})
    [fileName, filePath] = uiputfile('*.pdf', 'Save Window Plots as PDF', '~/Desktop/RTPlots.pdf');
    if fileName ~= 0
        set(handles.figure1, 'PaperUnits', 'inches');
        figurePos = get(handles.figure1, 'position');
        widthInch = figurePos(3) / 72;
        heightInch = figurePos(4) / 72;
        set(handles.figure1, 'inverthardcopy', 'off');                  % keep gray background
        set(handles.figure1, 'PaperOrientation', 'landscape');
        set(handles.figure1, 'PaperSize', [widthInch + 1.0, heightInch + 1.0]);
        set(handles.figure1, 'PaperPosition', [0.5, 0.5, widthInch, heightInch]);
        print(handles.figure1, '-dpdf', '-r600', [filePath fileName]);
    end
    RTControlState(handles, 'on', {})
end

%% Set up the LabJack
function lbj = setupLabJack()
%  get hardware info and do not continue if daq device/drivers unavailable

    lbj = labJackU6;                        % create the daq object
    open(lbj);                              % open connection to the daq
    if isempty(lbj.handle)
        originalSize = get(0, 'DefaultUIControlFontSize');
        set(0, 'DefaultUIControlFontSize', 14);
        questdlg('Exit and check USB connections.', ...
            'No LabJack Device Found', 'OK', 'OK');
        set(0, 'DefaultUIControlFontSize', originalSize);
    else
        fprintf(1,'Reaction Time: LabJack Ready.\n\n');
    end
    % create input channel list
    removeChannel(lbj, -1);                     % remove all input channels
    addChannel(lbj, 0, 10, ['s' 's']);          % add channel 0 as input
    lbj.SampleRateHz = 1000;                    % sample rate (Hz)
    lbj.ResolutionADC = 1;                      % ADC resolution (AD bit depth)

    % configure LabJack for analog input streaming

    errorCode = streamConfigure(lbj);
    if errorCode > 0
        fprintf(1,'Reaction Time: Unable to configure LabJack. Error %d.\n',errorCode);
        return
    end
end

%% respond to button presses
function startButton_Callback(hObject, eventdata, handles)                  
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if strcmp(get(handles.startButton, 'String'), 'Start') % if start button, do the following
        fprintf(1,'\nReaction Time v1.0\n %s\n', datestr(clock));
        viewDistanceCM = str2double(get(handles.viewDistanceText, 'string'));
        limitDistanceCM = maxViewDistanceCM(handles.visStim);
        if viewDistanceCM > limitDistanceCM
            errordlg(sprintf('Viewing distance must be <= %d cm', floor(limitDistanceCM)));
            return;
        end
        setViewDistanceCM(handles.visStim, str2double(get(handles.viewDistanceText, 'string')));
        handles.saccades.thresholdDeg = str2double(get(handles.thresholdDegText, 'string'));
        % create timer to control the task
        taskRateHz = 25;
        handles.taskTimer = timer('Name', 'TaskTimer', 'ExecutionMode', 'fixedRate',...
            'Period', 1.0/taskRateHz, 'UserData', handles, 'ErrorFcn', {@taskError, handles}, 'TimerFcn',...
            {@taskController, [handles.axes1 handles.axes3]});

        % create timer to get data from LabJack
        handles.data.taskState = RTTaskState.taskStarttrial;
        handles.data.trialStartTimeS = 0;
        handles.data.dataState = RTDataState.dataIdle;
        dataCollectRateHz = 25;                       % Fast enough to prevent overflow w/o blocking other activity
        handles.dataTimer = timer('Name', 'LabJackData', 'ExecutionMode', 'fixedRate',...
            'Period', 1.0 / dataCollectRateHz, 'UserData', handles, 'ErrorFcn', {@taskError, handles},...
            'TimerFcn', {@collectData}, 'StartDelay', 0.050); % StartDelay allows other parts of the gui to execute

        % set the gui button to "running" state
        set(handles.startButton, 'String', 'Stop', 'BackgroundColor', 'red');
        RTControlState(handles, 'off', {handles.startButton})
        % save timers to handles and update the GUI display

        %% Start plots, data pickup, and data acquisition 
        start(handles.dataTimer);    
        start(handles.taskTimer);

    %% Stop -- we're already running, so it's a the stop button    
    else % stop
        stop(timerfind);                                                        % stop/delete timers; pause data stream
        delete(timerfind);      
        handles.dataTimer = 0;
        handles.taskTimer = 0;
        stopStream(handles.lbj);
        set(handles.startButton, 'string', 'Start','backgroundColor', 'green');
        RTControlState(handles, 'on', {handles.startButton})
        drawnow;
        drawCenterStimulus(handles.visStim);                                	% recenter fixspot
    end
    guidata(hObject, handles);    
end

%% taskController: function to collect data from LabJack
function taskController(obj, events, daqaxes)
    
    c = RTConstants;
    handles = obj.UserData;
    data = handles.data;
    lbj = handles.lbj;                                              	% get handle to LabJack
    visStim = handles.visStim;
    saccades = handles.saccades;
    rtDists = handles.rtDists;
    switch data.taskState
        case RTTaskState.taskStarttrial
            if sum(data.trialTypesDone) >= data.numTrialTypes          	% finished another block
                data.trialTypesDone = zeros(1, data.numTrialTypes);    	% clear counters
                data.blocksDone = data.blocksDone + 1;                  % increment block counter
            end
            if atStepRangeLimit(visStim)
                data.trialType = c.kCenteringTrial;
            else
                data.trialType = ceil(rand() * data.numTrialTypes);     % randomly selected saccade step
                startIndex = data.trialType;                            % mark the index where search starts
                while true                                             	% find an unused, doable step
                    if data.trialTypesDone(data.trialType) == 0         % unused and doable
                        break;
                    end
                    data.trialType = mod(data.trialType, data.numTrialTypes) + 1; % try the next one
                    assert(data.trialType ~= startIndex, 'SaccadeRT taskController: failed to find unused trial type');                     % no types available (shouldn't happen)
                end
            end
            if rand() > 0.5
                data.stepDirection = c.kLeft;
            else
                data.stepDirection = c.kRight;
            end
            prepareImages(visStim, data.trialType, data.stepDirection);
            if data.testMode 
                data.voltage = min(5.0, visStim.currentOffsetPix / 1000.0);  % debugging - DACO0 should go to AIN0
                analogOut(lbj, 0, 2.5 + data.voltage);
            end
            data.trialStartTimeS = clock;
            data.taskState = RTTaskState.taskSettle;                  	% go to settle state
       case RTTaskState.taskSettle
            if etime(clock, data.trialStartTimeS) > 0.015               % data settled for one taskTimer cycle
                data.trialStartTimeS = clock;                         	% reset the trial clock
                data.prestimTimeS = data.prestimDurS + rand() * 0.125;	% jitter the stimon time a bit
                if data.trialType == c.kGapTrial                        % gap trials have target after the gap
                 	data.targetTimeS = data.prestimTimeS + data.gapDurS;
                else
                    data.targetTimeS = data.prestimTimeS;              	% all others have target before the gap
                end
                if data.trialType == c.kOverlapTrial                    % overlap trials have fixOff after the gap
                    data.fixOffTimeS = data.prestimTimeS + data.gapDurS;
                else                                                    % all others have fixOff before the gap
                   data.fixOffTimeS = data.prestimTimeS;                
                end
                data.samplesRead = 0;
                handles.lbj.verbose = 0;
                startStream(handles.lbj);
                handles.lbj.verbose = 1;
                data.dataState = RTDataState.dataCollect;
                data.taskState = RTTaskState.taskPrestim;              	% go to prestim state
            end
        case RTTaskState.taskPrestim
           if etime(clock, data.trialStartTimeS) > data.prestimTimeS	% preStim time up?
                if data.trialType == c.kCenteringTrial
                	drawCenterStimulus(visStim);
                else
                	drawImage(visStim, visStim.gapStim);
                end
               	data.taskState = RTTaskState.taskGapstim;               % go to gap state
            end
        case RTTaskState.taskGapstim
           if etime(clock, data.trialStartTimeS) > data.prestimTimeS + data.gapDurS
                drawImage(visStim, visStim.finalStim);                   % gap time up, draw postgap stim
               	data.taskState = RTTaskState.taskPoststim;
            end
        case RTTaskState.taskEndtrial
            if data.trialType ~= c.kCenteringTrial                  	% no updates needed on centering trials
                [startIndex, endIndex] = processSignals(saccades, data);
                plot(handles.posVelPlots, handles, startIndex, endIndex);
                if startIndex > 0
                    addRT(rtDists{data.trialType}, (startIndex / data.sampleRateHz  - data.targetTimeS) * 1000.0);
                end
                if (mod(sum(data.numSummed), data.numTrialTypes) == 0)	% finished a block
                    needsRescale = plot(rtDists{data.trialType});
                    if needsRescale > 0
                      	for i = 1:data.numTrialTypes
                             rescale(rtDists{i}, needsRescale);
                             plot(rtDists{i});
                        end
                    end
                end   
                set(handles.calibrationText, 'string', sprintf('Calibration %.1f deg/V', saccades.degPerV));
            end
            data.trialStartTimeS = 0;
            data.taskState = RTTaskState.taskStarttrial;
    end
end

%% taskError: error function to collect data from LabJack
function taskError(obj, events, handles)
    fprintf('timer error\n')
end
