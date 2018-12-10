function varargout = EOG(varargin)
% EOG displays an analog data stream from a LabJack U3
%
% EOG signals come through analog input channels 0 and 1 (AIN0 AIN1) on the LabJack. Connect LabJack DAC0/1 to AIN0/1
% for debugging with synthetic eye movements.
%
% Initialization code
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @openEOG, ...
                       'gui_OutputFcn',  @initEOG, ...
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
        clearAll(handles.ampDur);
%         for i = 1:handles.data.numOffsets
%             clearAll(handles.rtDists{i});
%         end
        clearAll(handles.data);
        plot(handles.posVelPlots, handles, 0, 0, true);
        set(handles.calibrationText, 'string', '');
        guidata(hObject, handles);
    end
end

%% closeEOG: clean up
function closeEOG(hObject, eventdata, handles)
    % this function is called  when the user closes the main window
    % close the timer and clear the LabJack handle
    %
    % fist check whether the task is running
    if strcmp(get(handles.startButton, 'String'), 'Stop')
        return;
    end
    originalSize = get(0, 'DefaultUIControlFontSize');
    set(0, 'DefaultUIControlFontSize', 14);
    selection = questdlg('Really exit EOG? Unsaved data will be lost.',...
        'Exit Request', 'Yes', 'No', 'Yes');      
    set(0, 'DefaultUIControlFontSize', originalSize);
    switch selection
    case 'Yes'
        cleanup(handles.visStim);
        delete(handles.visStim);
        try delete(handles.ampDur); catch, end
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
        case DataState.dataIdle
            return;
        case DataState.dataCollect
            [dRaw, ~] = getStreamData(lbj);                                     %#ok<*NASGU> % get stream data
            numNew = min(length(dRaw), data.trialSamples - data.samplesRead);
            data.rawData(data.samplesRead + 1:data.samplesRead + numNew, :) = dRaw(1:numNew, :);
            data.samplesRead = data.samplesRead + numNew;
            if (data.samplesRead == data.trialSamples)
                tStart = tic;
                handles.lbj.verbose = 0;
                stopStream(handles.lbj);
                handles.lbj.verbose = 1;
                data.dataState = DataState.dataIdle;
                data.taskState = TaskState.taskEndtrial;
            end        
    end
end

%% --- Executes on button press in Filter60.
function Filter60Hz_Callback(hObject, eventdata, handles) 

    set60HzFilter(handles.data, get(hObject,'Value'));
end

%% initEOG: initialization
function varargout = initEOG(hObject, eventdata, handles)               %#ok<*INUSL>
% initialize application.  We need to set up GUI items  after the GUI has been
% created by after openEOG function. This method gets called after the GUI is
% created but before control returns to the command line.
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    varargout{1} = handles.output;
    set(handles.startButton, 'String', 'Start','BackgroundColor', 'green');
end

%% loadDataButton_Callback
% --- Executes on button press in loadDataButton.
function loadDataButton_Callback(hObject, ~, handles) %#ok<*DEFNU>
    EOGControlState(handles, 'off', {})
    [fileName, filePath] = uigetfile('*.mat', 'Load Matlab Data Workspace', '~/Desktop');
    if fileName ~= 0
        testMode = handles.data.testMode;                               % keep testMode across data loads
        load([filePath fileName]);
        handles.data = d;
        handles.data.testMode = testMode;                               % keep testMode across data loads
        handles.ampDur = a;
        handles.saccades = s;
        set(handles.calibrationText, 'string', sprintf('Calibration %.1f deg/V', handles.saccades.degPerV));
%         handles.rtDists{1} = r1;
%         handles.rtDists{2} = r2;
%         handles.rtDists{3} = r3;
%         handles.rtDists{4} = r4;
        
        % saved axes handles generally aren't valid if we are in a new run.
        % Load the handles with the current axes handles.
        
        handles.ampDur.fHandle = handles.axes5;                         % loaded axes handle might be invalid
%         handles.rtDists{1}.fHandle = handles.axes6;
%         handles.rtDists{2}.fHandle = handles.axes7;
%         handles.rtDists{3}.fHandle = handles.axes8;
%         handles.rtDists{4}.fHandle = handles.axes9;
        guidata(hObject, handles);                                      % save the selections
        
        [startIndex, endIndex] = processSignals(handles.saccades, d);
        plot(handles.posVelPlots, handles, startIndex, endIndex, true);
        handles.ampDur.lastN = 0;                                       % force ampDur to plot
        plotAmpDur(handles.ampDur);
%         for i = 1:4
%             plot(handles.rtDists{i});
%         end

    end
    EOGControlState(handles, 'on', {})
end

%% openEOG
% openEOG: just before gui is made visible.
function openEOG(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EOG (see VARARGIN)

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
    handles.visStim = EOGStimulus;
    handles.saccades = EOGSaccades;
    set(hObject, 'CloseRequestFcn', {@closeEOG, handles});                  % close function will close LabJack
    handles.lbj = setupLabJack();
    handles.posVelPlots = EOGPosVelPlots(handles);
    handles.data = EOGTaskData(handles.lbj.numChannels, handles.lbj.SampleRateHz);
    handles.ampDur = EOGAmpDur(handles.axes5, handles.data.offsetsDeg, handles.lbj.SampleRateHz);
%     axes = [handles.axes6 handles.axes7 handles.axes8 handles.axes9];
%     handles.RTDist = cell(1, handles.data.numOffsets);
%     for i = 1:length(axes)
%         handles.rtDists{i} = EOGRTDist(i, handles.data.offsetsDeg(i), axes(i));
%     end
    
    % set up test mode
    handles.data.testMode = testMode;
    if (handles.data.testMode)
        analogOut(handles.lbj, 0, 2.5);                                     % For debugging (AOuts to AIns)
    end
    movegui(hObject, 'northeast');
    guidata(hObject, handles);                                              % save the selection
end

%%sampleRateText_Callback
function sampleRateText_Callback(hObject, eventdata, handles)
    requestedRateHz = str2double(get(handles.sampleRateText, 'string'));
    clippedRateHz = min([requestedRateHz, 1000, max(100, requestedRateHz)]);
    if (clippedRateHz ~= requestedRateHz)
        set(handles.sampleRateText, 'String', clippedRateHz);
    end
    if clippedRateHz ~= handles.data.sampleRateHz
        setSampleRateHz(handles.data, clippedRateHz);
        handles.lbj.SampleRateHz = clippedRateHz;
        errorCode = streamConfigure(handles.lbj);
        if errorCode > 0
            fprintf(1,'EOG: Unable to configure LabJack to new rate. Error %d.\n', errorCode);
        end
    end
end

%% saveDataButton_Callback
function saveDataButton_Callback(hObject, eventdata, handles)
% Saving the workspace for a GUI isn't simple.  What we have accessible in this
% environment is mostly the handles.  If we save, it's an attempt to save
% handles, which doesn't work.  Instead, we get a list of all the properties
% from the EOGTaskData class, and then use eval statement to assign those to
% local variable and save them (one by one).
    EOGControlState(handles, 'off', {})
    [fileName, filePath] = uiputfile('*.mat', 'Save Matlab Data Workspace', '~/Desktop/EOGData.mat');
    if fileName ~= 0
        d = handles.data;
        a = handles.ampDur;
        s = handles.saccades;
%         r1 = handles.rtDists{1};
%         r2 = handles.rtDists{2};
%         r3 = handles.rtDists{3};
%         r4 = handles.rtDists{4};
       save([filePath fileName], 'd', 'a', 's');
    end
    EOGControlState(handles, 'on', {})
end

%% savePlotsButton_Callback
function savePlotsButton_Callback(hObject, eventdata, handles)
% hObject    handle to savePlotsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    EOGControlState(handles, 'off', {})
    [fileName, filePath] = uiputfile('*.pdf', 'Save Window Plots as PDF', '~/Desktop/EOGData.pdf');
    if fileName ~= 0
        set(handles.figure1, 'PaperUnits', 'inches');
        figurePos = get(handles.figure1, 'position');
        widthInch = figurePos(3) / 72;
        heightInch = figurePos(4) / 72;
        set(handles.figure1, 'PaperOrientation', 'landscape');
        set(handles.figure1, 'PaperSize', [widthInch + 1.0, heightInch + 1.0]);
        set(handles.figure1, 'PaperPosition', [0.5, 0.5, widthInch, heightInch]);
        print(handles.figure1, '-dpdf', '-r600', '-noui', [filePath fileName]);
    end
    EOGControlState(handles, 'on', {})
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
        fprintf(1,'EOG: LabJack Ready.\n\n');
    end
    % create input channel list
    removeChannel(lbj, -1);                     % remove all input channels
    addChannel(lbj, 0, 10, ['s' 's']);          % add channel 0 as input
    lbj.SampleRateHz = 1000;                    % sample rate (Hz)
    lbj.ResolutionADC = 1;                      % ADC resolution (AD bit depth)

    % configure LabJack for analog input streaming

    errorCode = streamConfigure(lbj);
    if errorCode > 0
        fprintf(1,'EOG: Unable to configure LabJack. Error %d.\n',errorCode);
        return
    end
end

%% respond to button presses
function startButton_Callback(hObject, eventdata, handles)                  
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if strcmp(get(handles.startButton, 'String'), 'Start') % if start button, do the following
        fprintf(1,'\nEOG v1.0\n %s\n', datestr(clock));
        viewDistanceCM = str2double(get(handles.viewDistanceText, 'string'));
        limitDistanceCM = maxViewDistanceCM(handles.visStim, max(handles.data.offsetsDeg));
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
            {@taskController, [handles.axes1 handles.axes2 handles.axes3 handles.axes4]});

        % create timer to get data from LabJack
        handles.data.taskState = TaskState.taskStarttrial;
        handles.data.trialStartTimeS = 0;
        handles.data.dataState = DataState.dataIdle;
        dataCollectRateHz = 25;                       % Fast enough to prevent overflow w/o blocking other activity
        handles.dataTimer = timer('Name', 'LabJackData', 'ExecutionMode', 'fixedRate',...
            'Period', 1.0 / dataCollectRateHz, 'UserData', handles, 'ErrorFcn', {@taskError, handles},...
            'TimerFcn', {@collectData}, 'StartDelay', 0.050); % StartDelay allows other parts of the gui to execute

        % set the gui button to "running" state
        set(handles.startButton, 'String', 'Stop', 'BackgroundColor', 'red');
        EOGControlState(handles, 'off', {handles.startButton})
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
        EOGControlState(handles, 'on', {handles.startButton})
        drawnow;
        centerStimulus(handles.visStim);                                        % recenter fixspot
    end
    guidata(hObject, handles);    
end

%% taskController: function to collect data from LabJack
function taskController(obj, events, daqaxes)
    handles = obj.UserData;
    data = handles.data;
    lbj = handles.lbj;                                              	% get handle to LabJack
    visStim = handles.visStim;
    saccades = handles.saccades;
    ampDur = handles.ampDur;
%     rtDists = handles.rtDists;
    switch data.taskState
        case TaskState.taskStarttrial
            fprintf('finished %d trials\n', sum(data.offsetsDone));

            if sum(data.offsetsDone) >= data.numOffsets                 % finished another block
                data.offsetsDone = zeros(1, data.numOffsets);           % clear counters
                data.blocksDone = data.blocksDone + 1;                  % increment block counter
            end
            data.offsetIndex = ceil(rand() * data.numOffsets);
            while data.offsetsDone(data.offsetIndex) > 0
                data.offsetIndex = mod(data.offsetIndex, data.numOffsets) + 1;
            end
            data.absStepIndex = mod(data.offsetIndex - 1, data.numOffsets / 2) + 1;
            if data.offsetIndex <= data.numOffsets / 2
                data.stepSign = 1;
            else 
                data.stepSign = -1;
            end
           fprintf('doing index %d,  %.0f\n', data.offsetIndex, data.offsetsDeg(data.offsetIndex));
            if data.testMode 
                data.voltage = min(5.0, visStim.currentOffsetPix / 500.0);  % debugging- connect DACO0 to AIN0
                analogOut(lbj, 0, 2.5 + data.voltage);
            end
            data.trialStartTimeS = clock;
            data.taskState = TaskState.taskSettle;                      % go to settle state
        case TaskState.taskSettle
            if etime(clock, data.trialStartTimeS) > 0.015               % data settled for one taskTimer cycle
                data.trialStartTimeS = clock;                               % reset the trial clock
                data.stimTimeS = data.prestimDurS + rand() * 0.125;         % jitter the stimon time a bit
                data.samplesRead = 0;
                handles.lbj.verbose = 0;
                startStream(handles.lbj);
                handles.lbj.verbose = 1;
                data.dataState = DataState.dataCollect;
                data.taskState = TaskState.taskPrestim;                     % go to prestim state
%                 if data.testMode
%                     data.stimStartPixel = visStim.currentOffsetPix;
%                     data.saccHalfTimeS = -1;
%                 end
            end
        case TaskState.taskPrestim
           if etime(clock, data.trialStartTimeS) > data.stimTimeS
%                 data.stepSign = stepStimulus(visStim, data.offsetsDeg(data.offsetIndex));
                stepStimulus(visStim, data.offsetsDeg(data.offsetIndex));
                data.taskState = TaskState.taskPoststim;
            end
        case TaskState.taskPoststim
%             elapsedTimeS = etime(clock, data.trialStartTimeS);
%             if data.testMode && elapsedTimeS > data.stimTimeS + 0.1
%                 accelPixelPerSS = 5.0;
%                 if data.saccHalfTimeS < 0                           % set up the saccade parameters
%                     pixelOffset = visStim.currentOffsetPix - data.stimStartPixel; % stimulus step in pixels
%                     data.saccHalfTimeS = sqrt(pixelOffset / 2.0 * accelPixelPerSS);
%                     fprintf('saccade start %.3f\n', elapsedTimeS);
%                 end
%                 saccadeTimeS = data.stimTimeS + 0.100;
%                 if elapsedTimeS > saccadeTimeS && elapsedTimeS < saccadeTimeS + data.saccHalfTimeS
%                     fprintf('first half %.3f\n', elapsedTimeS);
%                     currentPosPixels = 0.5 * accelPixelPerSS * (elapsedTimeS - saccadeTimeS)^2;
%                     data.voltage = min(5.0, currentPosPixels / 500.0);
%                     analogOut(lbj, 0, 2.5 + data.voltage);
%                 elseif elapsedTimeS > saccadeTimeS + data.saccHalfTimeS && elapsedTimeS < saccadeTimeS + 2.0 * data.saccHalfTimeS
%                     fprintf('second half %.3f\n', elapsedTimeS);
%                     firstHalfPixels = 0.5 * accelPixelPerSS * (data.saccHalfTimeS)^2;
%                     firstHalfSpeed = data.saccHalfTimeS * accelPixelPerSS;
%                     secondHalfTimeS = elapsedTimeS - (saccadeTimeS + data.saccHalfTimeS);
%                     currentPosPixels = firstHalfPixels + firstHalfSpeed * secondHalfTimeS +...
%                         0.5 * -accelPixelPerSS * (secondHalfTimeS)^2; 
%                     data.voltage = min(5.0, currentPosPixels / 500.0);
%                     analogOut(lbj, 0, 2.5 + data.voltage);
%                end
%             end
        case TaskState.taskEndtrial
              fprintf('TaskState.taskEndtrial\n') 
           [startIndex, endIndex] = processSignals(saccades, data);
               fprintf('TaskState.taskEndtrial posVelPlots\n') 
           plot(handles.posVelPlots, handles, startIndex, endIndex, false);
            set(handles.calibrationText, 'string', sprintf('Calibration %.1f deg/V', saccades.degPerV));
               fprintf('TaskState.taskEndtrial addAmpDur\n') 
           addAmpDur(ampDur, data.offsetIndex, startIndex, endIndex);
              fprintf('TaskState.taskEndtrial plotAmpDur\n') 
            plotAmpDur(ampDur);
%             if startIndex > 0
%                 addRT(rtDists{data.offsetIndex}, (startIndex / data.sampleRateHz  - data.stimTimeS) * 1000.0);
%             end
%             if (mod(sum(data.numSummed), data.numOffsets) == 0)
%                 needsRescale = plot(rtDists{data.offsetIndex});
%                 if needsRescale > 0
%                      for i = 1:data.numOffsets
%                          rescale(rtDists{i}, needsRescale);
%                          plot(rtDists{i});
%                     end
%                 end
%             end   
            data.trialStartTimeS = 0;
            data.taskState = TaskState.taskStarttrial;
              fprintf('TaskState.taskEndtrial done\n') 
    end
end

%% taskError: error function to collect data from LabJack
function taskError(obj, events, handles)
    fprintf('timer error\n')
end
