function varargout = EOG(varargin)
% EOG displays an analog data stream from a LabJack U6
%
% EOG is a demonstration application built using the LABJACKU6 class.
%
% Analog input channels 0 and 1 (AIN0 AIN1) are enabled. The DAQ outputs
%  are also enabled- you can connect them to the AIN0/AIN1 to demonstrate 
%  analog streaming.
%
% 
% See also labjackU6.m
%
% M.A. Hopcroft
% mhopeng@gmail.com
%

% MH Aug2012
% v1.0

%#ok<*TRYNC>

% Last Modified by GUIDE v2.5 14-Aug-2012 17:25:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EOG_OpeningFcn, ...
                   'gui_OutputFcn',  @EOG_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
% End initialization code - DO NOT EDIT
end

% --- Executes just before EOG is made visible.
function EOG_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EOG (see VARARGIN)

handles.output = hObject;                                       % select default command line output
guidata(hObject, handles);                                      % save the selection

%% initialization
function varargout = EOG_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% initialize application
varargout{1} = handles.output;
set(handles.startbutton, 'String', 'Start','BackgroundColor', 'green');
% set the close function to automatically close the connection the daq
set(hObject,'CloseRequestFcn',{@closeProgram, handles});
handles.lbj=[];                             % the U6 object
guidata(hObject, handles);                  % save updates to handles

%% respond to button presses
function startbutton_Callback(hObject, eventdata, handles)                  %#ok<DEFNU>
% hObject    handle to startbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(handles.startbutton, 'String'), 'Start') % if start button, do the following

    fprintf(1,'\nEOG v1.0\n %s\n',datestr(clock));

    %% Set up the LabJack DAQ
    %  get hardware info and do not continue if daq device/drivers unavailable
    if isempty(handles.lbj)
        lbj = labJackU6;                        % create the daq object
        lbj.verbose = 1;                        % normal message level
        lbj.Tag = 'LabJackU6';                  % set name to be the daq's name
        open(lbj);                              % open connection to the daq
        if isempty(lbj.handle)
            error('No USB connection to a LabJack was found. Check connections and try again.');
        end
        fprintf(1,'EOG: LabJack Ready.\n\n');
        handles.lbj=lbj;                        % save the daq object for future use
    else
        lbj=handles.lbj;
    end
    % create input channel list
    removeChannel(lbj, -1);                     % remove all input channels
    addChannel(lbj,[0 1],[10 10],['s' 's']);    % add channels 0,1 as inputs
    lbj.SampleRateHz = 1000;                    % sample rate (Hz)
    lbj.ResolutionADC = 1;                      % ADC resolution (AD bit depth)

    voltage = 0; 
    analogOut(lbj, 0, voltage);                 % For debugging (AOuts to AIns)
    analogOut(lbj, 1, voltage + 1);

    % configure LabJack for analog input streaming
    
    errorCode = streamConfigure(lbj);
    if errorCode > 0
        fprintf(1,'EOG: Unable to configure LabJack. Error %d.\n',errorCode);
        return
    end 
    
    % Initialize the variables for storing the data that is plotted
    taskData.trialLimitS = 1.0;
    taskData.samplesNeeded = floor(taskData.trialLimitS * lbj.SampleRateHz);
    taskData.taskState = TaskState.taskIdle;
    taskData.trialStartTimeS = 0;
    taskData.samplesRead = 0;
    taskData.dataReady = false;
%     taskData.totalPoints = 0;                % number of data points collected
    taskData.numSummed = 0;
    taskData.numPlotted = 0;
    taskData.discardData = true;                   % flag to data timer to discard streamed data
    taskData.rawData = zeros(taskData.samplesNeeded, lbj.numChannels); % for raw data
    taskData.summedData = zeros(taskData.samplesNeeded, lbj.numChannels); % for raw data
    taskData.avgData = zeros(taskData.samplesNeeded, lbj.numChannels); % for averaged data
    lbj.UserData = taskData;                                           % pass to U6 object

    %% - Prepare to Get Data
    % create timer to control the task
    taskTimer = timer('Name', 'TaskTimer', 'ExecutionMode', 'fixedRate',...
        'Period', 0.1, 'UserData', lbj, 'ErrorFcn', {@timerErrorFcnStop, handles}, 'TimerFcn', {@taskController});
    
    % create timer to get data from LabJack
    dataCollectRateHz = 50;                       % Fast enough to prevent overflow w/o blocking other activity
    dataTimer = timer('Name', 'LabJackData', 'ExecutionMode', 'fixedRate',...
        'Period', 1/dataCollectRateHz, 'UserData', lbj, 'ErrorFcn', {@timerErrorFcnStop, handles},...
        'TimerFcn', {@dataStreamGet}, 'StartDelay', 0.1); % StartDelay allows other parts of the gui to execute

    % create timer object to do the plotting
    plotTimer=timer('Name', 'LabJackTimer', 'ExecutionMode', 'fixedRate',...
        'Period', 0.250, 'UserData', lbj, 'ErrorFcn', {@timerErrorFcnStop, handles},...
        'TimerFcn', {@plotStreamData, [handles.axes1 handles.axes2]});
    
    % set the gui button to "running" state
    set(handles.startbutton, 'String', 'Stop', 'BackgroundColor', 'red')
      
    % save timers to handles and update the GUI display
    handles.taskTimer = taskTimer;
    handles.dataTimer = dataTimer;
    handles.plotTimer = plotTimer;
    handles.lbj = lbj;
    guidata(hObject, handles);    
    
    %% Start plots, data pickup, and data acquisition 
    start(plotTimer);
    start(dataTimer);    
	startStream(lbj);
    start(taskTimer);

%% Stop -- we're already running, so it's a the stop button    
else % stop
    disp('EOG Stop')
    % stop/delete timers, and pause the data stream
    stop(timerfind);
    delete(timerfind);        
    stopStream(handles.lbj);

    set(handles.startbutton, 'String', 'Start','BackgroundColor', 'green')
    drawnow;  
end

%% taskController: function to collect data from LabJack
function taskController(obj, event)                                         %#ok<*INUSD>
lbj = obj.UserData;                                                         % handle to labjack is in timer UserData
taskData = lbj.UserData;                                                    % UserData must be initialized w daq setup
switch taskData.taskState
    case TaskState.taskIdle
        disp('idle');
        if taskData.trialStartTimeS == 0
            taskData.trialStartTimeS = clock;
        elseif etime(clock, taskData.trialStartTimeS) > 0.075               % let data settle
            taskData.trialStartTimeS = clock;                               % reset the trial clock
            taskData.dataState = DataState.dataStart;
            taskData.taskState = TaskState.taskPrestim;
            taskData.stimTimeS = 0.250 + rand() * 0.250;
        end
    case TaskState.taskPrestim
        disp('prestim');
        if etime(clock, taskData.trialStartTimeS) > taskData.stimTimeS
            % DO THE STIMULUS
            taskData.taskState = TaskState.taskPoststim;
        end
    case TaskState.taskPoststim
        disp('poststim');
        % CHECK FOR THE SACCADE (OR TIME LIMIT)
        if etime(clock, taskData.trialStartTimeS) > taskData.trialLimitS
            taskData.dataState = DataState.dataStop;
            taskData.taskState = TaskState.taskIdle;
            taskData.trialStartTimeS = 0;
        end
    case TaskState.taskEndtrial
        disp('end');
        taskData.trialStartTimeS = 0;
end
lbj.UserData = taskData;                                                    % save new points to UserData

%% dataStreamGet: function to collect data from LabJack
function dataStreamGet(obj, event)                                          %#ok<*INUSD>
% reads stream data from the LabJack

lbj = obj.UserData;                                                         % handle to labjack is in timer UserData
[dRaw, errorCode] = getStreamData(lbj);                                     %#ok<*NASGU> % get stream data
taskData = lbj.UserData;                                                    % UserData must be initialized w daq setup
if taskData.discardData
    return;
end
numNew = min(length(dRaw), taskData.samplesNeeded - taskData.samplesRead);
taskData.rawData(taskData.samplesRead + 1:taskData.samplesRead + numNew, :) = dRaw(1:numNew, :);
taskData.samplesRead = taskData.samplesRead + numNew;

if (taskData.samplesRead == taskData.samplesNeeded)
    taskData.summedData = taskData.summedData + taskData.rawData;  % sum in new trace
    taskData.avgData = taskData.summedData / taskData.numSummed;
    taskData.numSummed = taskData.numSummed + 1;                      % enable plotting
%     taskData.discardData = true;                                         % we're free running, need to discard a couple of packets
    taskData.samplesRead = 0;                                            % prep for next cycle
end;
lbj.UserData = taskData;                                                 % save new points to UserData
voltage = taskData.samplesRead / 500.0;
analogOut(lbj,0, voltage);                                                  % debugging- connect DOC0 to AIN Ch0
analogOut(lbj,1, voltage + 1);

%% plotStreamData Fcn
function plotStreamData(obj, event, daqaxes)
% This function gets data from the daq, averages data points, saves
%  data to a file, and plots it in the figure. It is the TimerFcn for the
%  plotTimer.

lbj=obj.UserData;                                                           % handle to labjack is in timer UserData
taskData = lbj.UserData;
if (taskData.numSummed <= taskData.numPlotted)                        % check for new data
    return
else
    % update data plot
    timestepS = 1 / lbj.SampleRateHz;                                       % time interval of samples
    timeaxes1 = [0:1:size(taskData.avgData,1) - 1] .* timestepS;         % make array of timepoints

    plot(daqaxes(1), timeaxes1, taskData.rawData, '-');
    title(daqaxes(1),['Most recent AI trace from ' lbj.Tag], 'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(1),'Analog Input (V)','FontSize',14);
    xlabel(daqaxes(1),['Time (s)'],'FontSize',14);

    plot(daqaxes(2), timeaxes1, taskData.avgData, '-');
    title(daqaxes(2),['AI from ' lbj.Tag sprintf('(average of %d traces', taskData.numSummed)], ...
                  'FontSize',12,'FontWeight','Bold')
    ylabel(daqaxes(2),'Analog Input (V)','FontSize',14);
    xlabel(daqaxes(2),['Time (s)'],'FontSize',14);

    drawnow;
    taskData.numPlotted = taskData.numSummed;
    lbj.UserData = taskData;                                             % save new points to UserData
end

%% close program
function closeProgram(hObject, eventdata, handles)
% this function is called  when the user closes the main window
%
fprintf(1,'EOG: close window\n');
% close the timer and clear the LabJack handle
try stop(timerfind); end
try delete(timerfind); end
try clear('handles.lbj'); end
delete(hObject);                                                            % close the program window
