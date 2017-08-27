function varargout = EOG(varargin)
% EOG displays an analog data stream from a LabJack U3
%
% EOG signals come through analog input channels 0 and 1 (AIN0 AIN1) on the LabJack. Connect LabJack DAC0/1 to AIN0/1
% for debugging with synthetic eye movements.
%
% Derived from LJSteam.m by 
% M.A. Hopcroft
% mhopeng@gmail.com
%

% Begin initialization code
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
% End initialization code
end

%% closeEOG: clean up
function closeEOG(hObject, eventdata, handles)
% this function is called  when the user closes the main window
% close the timer and clear the LabJack handle
%
fprintf(1,'EOG: close window\n');
cleanup(handles.visStim);
try stop(timerfind); end
try delete(timerfind); end
try clear('handles.lbj'); end
delete(hObject);                                                            % close the program window

%% collectData: function to collect data from LabJack
function collectData(obj, event)                                        %#ok<*INUSD>
% reads stream data from the LabJack

lbj = obj.UserData;                                                         % handle to labjack is in timer UserData
[dRaw, errorCode] = getStreamData(lbj);                                     %#ok<*NASGU> % get stream data
taskData = lbj.UserData;                                                    % UserData must be initialized w daq setup
switch taskData.dataState
    case DataState.dataIdle
        return;
    case DataState.dataStart
        taskData.samplesRead = 0;
        taskData.dataState = DataState.dataCollect;
    case DataState.dataCollect
        numNew = min(length(dRaw), taskData.trialSamples - taskData.samplesRead);
        taskData.rawData(taskData.samplesRead + 1:taskData.samplesRead + numNew, :) = dRaw(1:numNew, :);
        taskData.samplesRead = taskData.samplesRead + numNew;
        if (taskData.samplesRead == taskData.trialSamples)
            taskData.dataState = DataState.dataIdle;
            taskData.taskState = TaskState.taskEndtrial;
        end
%    case DataState.dataStop
end
lbj.UserData = taskData;                                                    % save new points to UserData

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
set(handles.startbutton, 'String', 'Start','BackgroundColor', 'green');
% set(hObject, 'CloseRequestFcn', {@closeEOG, handles});                  % close function will close LabJack
% handles.lbj = [];                                                       % the LabJack object
% guidata(hObject, handles);                                              % save updates to handles

% openEOG: just before gui is made visible.
function openEOG(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EOG (see VARARGIN)

handles.output = hObject;                                               % select default command line output
handles.visStim = EOGStimulus;
set(hObject, 'CloseRequestFcn', {@closeEOG, handles});                  % close function will close LabJack
handles.lbj = [];                                                       % the LabJack object
% set(handles.startbutton, 'String', 'Start','BackgroundColor', 'green');
guidata(hObject, handles);                                              % save the selection

%% processSignals: function to process data from one trial
function [taskData, validTrial, maxIndex] = processSignals(taskData)
    taskData.posTrace = taskData.rawData(:, 1) - taskData.rawData(:, 2);
    taskData.posTrace = taskData.posTrace - mean(taskData.posTrace(1:floor(taskData.sampleRateHz * taskData.prestimDurS)));
    % Debug: add some noise to make things realistic
    taskData.posTrace = taskData.posTrace + 0.3 * rand(size(taskData.posTrace)) - 0.15;
    % do a boxcar filter of the raw signal
    windowSize = 50;
    b = (1 / windowSize) * ones(1, windowSize);
    taskData.posTrace = filter(b, 1, taskData.posTrace);
    taskData.velTrace(1:end - 1) = diff(taskData.posTrace);
    taskData.velTrace(end) = taskData.velTrace(end - 1);
    if (taskData.stepSign == 1)
        [~, maxIndex] = max(taskData.velTrace);
    else
        [~, maxIndex] = min(taskData.velTrace);
    end
    saccadeOffset = taskData.saccadeSamples / 2;
    validTrial = (maxIndex >= saccadeOffset) && (maxIndex < taskData.trialSamples - saccadeOffset);
    if ~validTrial
        return
    end
    if (taskData.stepSign == 1)
        taskData.posSummed(:, taskData.offsetIndex) = taskData.posSummed(:, taskData.offsetIndex)... 
                    + taskData.posTrace(floor(maxIndex - saccadeOffset):floor(maxIndex + saccadeOffset - 1));  
        taskData.velSummed(:, taskData.offsetIndex) = taskData.velSummed(:, taskData.offsetIndex)... 
                    + taskData.velTrace(floor(maxIndex - saccadeOffset):floor(maxIndex + saccadeOffset - 1));  
    else
        taskData.posSummed(:, taskData.offsetIndex) = taskData.posSummed(:, taskData.offsetIndex)...
                    - taskData.posTrace(floor(maxIndex - saccadeOffset):floor(maxIndex + saccadeOffset - 1));  
        taskData.velSummed(:, taskData.offsetIndex) = taskData.velSummed(:, taskData.offsetIndex)... 
                    - taskData.velTrace(floor(maxIndex - saccadeOffset):floor(maxIndex + saccadeOffset - 1));  
    end
    taskData.numSummed(taskData.offsetIndex) = taskData.numSummed(taskData.offsetIndex) + 1;
    taskData.posAvg(:, taskData.offsetIndex) = taskData.posSummed(:, taskData.offsetIndex) ...
        / taskData.numSummed(taskData.offsetIndex);
    taskData.velAvg(:, taskData.offsetIndex) = taskData.velSummed(:, taskData.offsetIndex) ...
        / taskData.numSummed(taskData.offsetIndex);
    taskData.offsetsDone(taskData.offsetIndex) = taskData.offsetsDone(taskData.offsetIndex) + 1;

%% Set up the LabJack
function lbj = setupLabJack(handles)
%  get hardware info and do not continue if daq device/drivers unavailable
if isempty(handles.lbj)
    lbj = labJackU6;                        % create the daq object
%        lbj.verbose = 1;                       % more messages
%         lbj.Tag = 'LabJackU3';                % set name to be the daq's name
    open(lbj);                              % open connection to the daq
    if isempty(lbj.handle)
        error('No USB connection to a LabJack was found. Check connections and try again.');
    else
        fprintf(1,'EOG: LabJack Ready.\n\n');
        handles.lbj = lbj;                  % save the daq object for future use
    end
else
    lbj = handles.lbj;                      % get a copy of lbj for convenience
end
% create input channel list
removeChannel(lbj, -1);                     % remove all input channels
addChannel(lbj, [0 1], [10 10], ['s' 's']); % add channels 0,1 as inputs
lbj.SampleRateHz = 1000;                    % sample rate (Hz)
lbj.ResolutionADC = 1;                      % ADC resolution (AD bit depth)
voltage = 2.5; 
analogOut(lbj, 0, voltage);                 % For debugging (AOuts to AIns)
analogOut(lbj, 1, voltage);

% configure LabJack for analog input streaming

errorCode = streamConfigure(lbj);
if errorCode > 0
    fprintf(1,'EOG: Unable to configure LabJack. Error %d.\n',errorCode);
    return
end

%% respond to button presses
function startbutton_Callback(hObject, eventdata, handles)                  %#ok<DEFNU>
% hObject    handle to startbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(handles.startbutton, 'String'), 'Start') % if start button, do the following

    fprintf(1,'\nEOG v1.0\n %s\n', datestr(clock));
%     handles.visStim = setupVisStim(handles);
    handles.lbj = setupLabJack(handles);

%     %% Set up the LabJack DAQ
%     %  get hardware info and do not continue if daq device/drivers unavailable
%     if isempty(handles.lbj)
%         lbj = labJackU6;                        % create the daq object
%         lbj.verbose = 1;                        % more messages
% %         lbj.Tag = 'LabJackU3';                  % set name to be the daq's name
%         open(lbj);                              % open connection to the daq
%         if isempty(lbj.handle)
%             error('No USB connection to a LabJack was found. Check connections and try again.');
%         end
%         fprintf(1,'EOG: LabJack Ready.\n\n');
%         handles.lbj=lbj;                        % save the daq object for future use
%     else
%         lbj = handles.lbj;                      % get a copy of lbj for convenience
%     end
%     % create input channel list
%     removeChannel(lbj, -1);                     % remove all input channels
%     addChannel(lbj, [0 1], [10 10], ['s' 's']); % add channels 0,1 as inputs
%     lbj.SampleRateHz = 1000;                    % sample rate (Hz)
%     lbj.ResolutionADC = 1;                      % ADC resolution (AD bit depth)
% 
%     voltage = 2.5; 
%     analogOut(lbj, 0, voltage);                 % For debugging (AOuts to AIns)
%     analogOut(lbj, 1, voltage);
% 
%     % configure LabJack for analog input streaming
%     
%     errorCode = streamConfigure(lbj);
%     if errorCode > 0
%         fprintf(1,'EOG: Unable to configure LabJack. Error %d.\n',errorCode);
%         return
%     end 
    
    % Initialize the variables for storing the data that is plotted
    taskData.offsetPix = [100 200 300 400];
    taskData.numOffsets = length(taskData.offsetPix);
    taskData.currentOffsetPix = 0.0;
    taskData.stepSign = 1;
    taskData.offsetIndex = 0;
    taskData.offsetsDone = zeros (1, taskData.numOffsets);
    taskData.blocksDone = 0;
    taskData.sampleRateHz = handles.lbj.SampleRateHz;
    taskData.saccadeDurS = 0.25;
    taskData.saccadeSamples = floor(taskData.saccadeDurS * taskData.sampleRateHz);
    taskData.trialDurS = max(0.50, 2 * taskData.saccadeDurS);
    taskData.trialSamples = floor(taskData.trialDurS * taskData.sampleRateHz);
    taskData.prestimDurS = min(taskData.trialDurS / 4, 0.250);
    taskData.taskState = TaskState.taskIdle;
    taskData.trialStartTimeS = 0;
    taskData.samplesRead = 0;
    taskData.dataState = DataState.dataIdle;
    taskData.numSummed = zeros(1, taskData.numOffsets);
    taskData.rawData = zeros(taskData.trialSamples, handles.lbj.numChannels);    % raw data
    taskData.posTrace = zeros(taskData.trialSamples, 1);                         % trial EOG position trace
    taskData.posSummed = zeros(taskData.saccadeSamples, taskData.numOffsets);    % summed position traces
    taskData.posAvg = zeros(taskData.saccadeSamples, taskData.numOffsets);       % averaged position traces
    taskData.velTrace = zeros(taskData.trialSamples, 1);                         % trial EOG velocity trace
    taskData.velSummed = zeros(taskData.saccadeSamples, taskData.numOffsets);    % summed position traces
    taskData.velAvg = zeros(taskData.saccadeSamples, taskData.numOffsets);       % averaged position traces
    handles.lbj.UserData = taskData;                                             % pass to LabJack object

    %% - Prepare to Get Data
    % create timer to control the task
    taskTimer = timer('Name', 'TaskTimer', 'ExecutionMode', 'fixedRate',...
        'Period', 0.1, 'UserData', handles.lbj, 'ErrorFcn', {@timerErrorFcnStop, handles},...
        'TimerFcn', {@taskController, handles.visStim, [handles.axes1 handles.axes2 handles.axes3 handles.axes4]});
    
    % create timer to get data from LabJack
    dataCollectRateHz = 50;                       % Fast enough to prevent overflow w/o blocking other activity
    dataTimer = timer('Name', 'LabJackData', 'ExecutionMode', 'fixedRate',...
        'Period', 1/dataCollectRateHz, 'UserData', handles.lbj, 'ErrorFcn', {@timerErrorFcnStop, handles},...
        'TimerFcn', {@collectData}, 'StartDelay', 0.1); % StartDelay allows other parts of the gui to execute

    % set the gui button to "running" state
    set(handles.startbutton, 'String', 'Stop', 'BackgroundColor', 'red')
      
    % save timers to handles and update the GUI display
    handles.taskTimer = taskTimer;
    handles.dataTimer = dataTimer;
%     handles.lbj = lbj;
    guidata(hObject, handles);    
    
    %% Start plots, data pickup, and data acquisition 
	startStream(handles.lbj);
    start(dataTimer);    
    start(taskTimer);

%% Stop -- we're already running, so it's a the stop button    
else % stop
    disp('EOG Stop')
    stop(timerfind);                                                        % stop/delete timers; pause data stream
    delete(timerfind);        
    stopStream(handles.lbj);
    set(handles.startbutton, 'String', 'Start','BackgroundColor', 'green')
    drawnow;  
end

%% taskController: function to collect data from LabJack
function taskController(obj, ~, visStim, daqaxes)
lbj = obj.UserData;                                                         % handle to labjack is in timer UserData
taskData = lbj.UserData;                                                    % UserData must be initialized w daq setup
switch taskData.taskState
    case TaskState.taskIdle
        if taskData.trialStartTimeS == 0                                    % initialize a new trial
            if sum(taskData.offsetsDone) >= taskData.numOffsets             % finished another block
                taskData.offsetsDone = zeros(1, taskData.numOffsets);       % clear counters
                taskData.blocksDone = taskData.blocksDone + 1;              % increment block counter
            end
            taskData.offsetIndex = ceil(rand() * taskData.numOffsets);
            while taskData.offsetsDone(taskData.offsetIndex) > 0
                taskData.offsetIndex = mod(taskData.offsetIndex, taskData.numOffsets) + 1;
            end
            taskData.trialStartTimeS = clock;
            taskData.voltage = taskData.currentOffsetPix / 1000.0;          % debugging- connect DOC0 to AIN Ch0
            analogOut(lbj,0, 2.5 + taskData.voltage);
            analogOut(lbj,1, 2.5 - taskData.voltage);
        elseif etime(clock, taskData.trialStartTimeS) > 0.050               % data settled for one taskTimer cycle
            taskData.trialStartTimeS = clock;                               % reset the trial clock
            taskData.stimTimeS = taskData.prestimDurS + rand() * 0.1250;
            taskData.dataState = DataState.dataStart;
            taskData.taskState = TaskState.taskPrestim;
        end
    case TaskState.taskPrestim
        if etime(clock, taskData.trialStartTimeS) > taskData.stimTimeS
            if taskData.currentOffsetPix > 0
                taskData.stepSign = -1;
            else
                taskData.stepSign = 1;
            end
            taskData.currentOffsetPix = taskData.currentOffsetPix + ...
                    taskData.stepSign * taskData.offsetPix(taskData.offsetIndex);
            drawDot(visStim, taskData.currentOffsetPix);
            taskData.voltage = taskData.currentOffsetPix / 1000.0;          % debugging- connect DOC0 to AIN Ch0
            analogOut(lbj,0, 2.5 + taskData.voltage);
            analogOut(lbj,1, 2.5 - taskData.voltage);
            taskData.taskState = TaskState.taskPoststim;
        end
    case TaskState.taskPoststim
        % just wait for end of trial
    case TaskState.taskEndtrial
        [taskData, validTrial, maxIndex] = processSignals(taskData);
        if validTrial
            updatePlots(lbj, taskData, daqaxes, maxIndex);
        end
        taskData.trialStartTimeS = 0;
        taskData.taskState = TaskState.taskIdle;
end
lbj.UserData = taskData;                                                    % save new points to UserData
    
%% updatePlots: function to refresh the plots after each trial
function updatePlots(lbj, taskData, daqaxes, maxIndex)
    timestepS = 1 / lbj.SampleRateHz;                                       % time interval of samples
    trialTimes = (0:1:size(taskData.posTrace, 1) - 1) * timestepS;          % make array of trial time points
    saccadeTimes = (-(size(taskData.posAvg, 1) / 2):1:(size(taskData.posAvg,1) / 2) - 1) * timestepS;              

    colors = get(daqaxes(1), 'ColorOrder');
    plot(daqaxes(1), trialTimes, taskData.posTrace, 'color', colors(taskData.offsetIndex,:));
    title(daqaxes(1), 'Most recent position trace', 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(1),'Analog Input (V)','FontSize',14);
 
    plot(daqaxes(2), saccadeTimes, taskData.posAvg, '-');
    title(daqaxes(2), ['Average position traces (left/right combined; ' sprintf('n>=%d)', taskData.blocksDone)], ...
                  'FontSize',12,'FontWeight','Bold')

    a1 = axis(daqaxes(1));
    a2 = axis(daqaxes(2));
    yLim = max([abs(a1(3)), abs(a1(4)), abs(a2(3)), abs(a2(4))]);
    axis(daqaxes(1), [-inf inf -yLim yLim]);
    axis(daqaxes(2), [-inf inf -yLim yLim]);
    hold(daqaxes(1), 'on');
    plot(daqaxes(1), [maxIndex, maxIndex] * timestepS, [-yLim yLim], 'color', colors(taskData.offsetIndex,:),...
        'linestyle', ':');
    hold(daqaxes(1), 'off');

    plot(daqaxes(3), trialTimes, taskData.velTrace, 'color', colors(taskData.offsetIndex,:));
    a = axis(daqaxes(3));
    yLim = max(abs(a(3)), abs(a(4)));
    axis(daqaxes(3), [-inf inf -yLim yLim]);
    title(daqaxes(3), 'Most recent velocity trace', 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(3),'Analog Input (dV/dt)','FontSize',14);
    xlabel(daqaxes(3),'Time (s)','FontSize',14);

    plot(daqaxes(4), saccadeTimes, taskData.velAvg, '-');
    title(daqaxes(4), 'Average velocity traces (left/right combined)', 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(4),'Analog Input (V)','FontSize',14);
    xlabel(daqaxes(4),'Time (s)','FontSize',14);
  
    a1 = axis(daqaxes(3));
    a2 = axis(daqaxes(4));
    yLim = max([abs(a1(3)), abs(a1(4)), abs(a2(3)), abs(a2(4))]);
    axis(daqaxes(3), [-inf inf -yLim yLim]);
    axis(daqaxes(4), [-inf inf -yLim yLim]);
    
    hold(daqaxes(3), 'on');
    plot(daqaxes(3), [maxIndex, maxIndex] * timestepS, [-yLim yLim], 'color', colors(taskData.offsetIndex,:), 'linestyle', ':');
    hold(daqaxes(3), 'off');

    drawnow;
