function varargout = StretchReceptor(varargin)
% SR displays an analog data stream from a LabJack U3 or U6
%
% SR signals come through analog input channels 0 (AIN0) on the LabJack. Connect LabJack DAC0 to AIN0
% for debugging with synthetic spikes.
%
% Initialization code
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @openSR, ...
                       'gui_OutputFcn',  @initSR, ...
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
    clearAll(handles.data);
    clearAll(handles.plots, handles);
    clearAll(handles.isiPlot);
    guidata(hObject, handles);
end

%% closeSR: clean up
function closeSR(hObject, eventdata, handles)
    % this function is called  when the user closes the main window
    % close the timer and clear the LabJack handle
    %
    % fist check whether the task is running
    if strcmp(get(handles.startButton, 'String'), 'Stop')
        return;
    end
%     originalSize = get(0, 'DefaultUIControlFontSize');
%     set(0, 'DefaultUIControlFontSize', 14);
%     selection = questdlg('Really exit SR? Unsaved data will be lost.',...
%         'Exit Request', 'Yes', 'No', 'Yes');      
%     set(0, 'DefaultUIControlFontSize', originalSize);
%     switch selection
%     case 'Yes'
        try delete(handles.ampDur); catch, end
        try stop(timerfind); catch, end
        try delete(timerfind); catch, end
        try clear('handles.lbj'); catch, end
        delete(hObject);                                                            % close the program window
%     case 'No'
%         return
%     end
end

%% collectData: function to collect data from LabJack
function collectData(obj, event)                                            %#ok<*INUSD>
% reads and processes stream data from the LabJack
    handles = obj.UserData;                                                 % obj.UserData is pointer to handles
    data = handles.data;                                                    % get data
    % If the continuous display scaling has just changed, we will refresh that plot
    if data.contPlotRescale
        setLimits(data,handles);
        clearContPlot(handles.plots, handles)
        clearTriggerPlot(handles.plots, handles)
        data.contPlotRescale = false;
    end
    % We need a new trace if we hit or exceeded the sample buffer limit on the previous call
    if (data.samplesRead >= data.contSamples)
        data.samplesRead = 0;
        data.lastSpikeIndex = data.lastSpikeIndex - data.contSamples;
        if data.singleTrace                                         % if singleTrace, stop data collection
            handles.plots.samplesPlotted = 0;
            startButton_Callback(handles.startButton, event, handles);
        end
    end
    if (handles.plots.samplesPlotted > data.samplesRead)
        if handles.plots.singleSpike
            clearContPlot(handles.plots, handles);
        else
            clearAll(handles.plots, handles);
        end
    end
    
    % read and process any new data
    
    [dRaw, ~] = getStreamData(handles.lbj);                         % get stream data

    % the LabJack marks lost data as -9999.  We clip it out and don't do anything more. Typically lost data appear
    % at the end of the trace (after the buffer has filled).  Oddly, there is generally one spurious large value
    % (+10.115) that appears exactly 8 samples before the first error values.  We clip that out as well.
    
    dRaw(dRaw > 10.0) = [];                                         % and clip out all error values
    dRaw(dRaw == -9999) = [];                                         % and clip out all error values
%     firstErrorIndex = find(dRaw == -9999, 1, 'first');              % get the first error index
%     if ~isempty(firstErrorIndex)                                    % for one or more errors,
%         fprintf('found an error\n');
%         for i = firstErrorIndex - 10:firstErrorIndex + 10
%             fprintf('%.3f ', dRaw(i));
%         end
%         fprintf('\n');
%         if (firstErrorIndex > 8)                                    % clip out the spurious erroneous value
%             dRaw(firstErrorIndex - 8) = [];
%         end
%         dRaw(dRaw == -9999) = [];                                   % and clip out all error values
%     end
    
    % now we can process any valid data
    
    numNew = min(length(dRaw), data.contSamples - data.samplesRead); 
    if numNew > 0
        data.rawData(data.samplesRead + 1:data.samplesRead + numNew) = dRaw(1:numNew);
        processSignals(handles.signals, data, data.samplesRead, numNew);
        data.samplesRead = data.samplesRead + numNew;
        plot(handles.plots, handles);
        if numNew < length(dRaw)                                    % more data read from LabJack?
            if data.singleTrace                                     % if singleTrace, stop data collection
                handles.plots.samplesPlotted = 0;
                data.samplesRead = 0;
                startButton_Callback(handles.startButton, event, handles);
            else
                numNew = length(dRaw) - numNew;
                data.rawData(1:numNew) = dRaw(end - numNew + 1:end);
                processSignals(handles.signals, data, 0, numNew);
                data.samplesRead = numNew;
            end
        end
    end
    guidata(handles.startButton, handles);                          % save variables (guidata requires gui decendent
end

%% collectError: error function for collectData
function collectError(obj, events, handles)
    fprintf('data error');
    dbstack
%     callStackString = GetCallStack(ME);
% 	errorMessage = sprintf('Error in program %s.\nTraceback (most recent at top):\n%s\nError Message:\n%s',...
% 		mfilename, callStackString, ME.message);
% 	uiwait(errordlg(errorMessage));
end

%% change in contMSPerDivButton.
function contMSPerDivButton_Callback(hObject, ~, handles) %#ok<*DEFNU>
    contents = cellstr(get(hObject,'String'));
    newValue = str2double(contents{get(hObject, 'Value')});
    if newValue ~= handles.data.contMSPerDiv
        handles.data.contMSPerDiv = newValue;
        if strcmp(get(handles.startButton, 'String'), 'Start')  % if we're not running
            setLimits(handles.data, handles);
            clearContPlot(handles.plots, handles)
        else
            handles.data.contPlotRescale = true;                % else let dataCollect do the update
        end
    end
end

%% fakeSpike: make a fake spike on LabJack
function fakeSpike(obj, event)                                              %#ok<*INUSD>
    persistent count;
    
    if isempty(count)
        count = 1;
    else
        count = count + 1;
    end
    numSpikes = 1 + (mod(count, 5) == 0);
    
    handles = obj.UserData;                                             % obj.UserData is pointer to handles
    lbj = handles.lbj;                                                  % get lbj
    for s = 1:numSpikes
        analogOut(lbj, 0, 4.5);
        java.lang.Thread.sleep(1.5);
        analogOut(lbj, 0, 1.5);
        java.lang.Thread.sleep(3.0);
        analogOut(lbj, 0, 2.5);
        java.lang.Thread.sleep(3.0);
   end    
end

%% fakeSpikeError: function to collect data from LabJack
function fakeSpikeError(obj, events, handles)
    fprintf('fake spike error\n');
end

%% selection change in filterMenu.
function filterMenu_Callback(hObject, eventdata, handles)
    selectFilter(handles.data);
end

%% initSR: initialization
function varargout = initSR(hObject, eventdata, handles)                    %#ok<*INUSL>
% initialize application.  We need to set up GUI items  after the GUI has been
% created by after openSR function. This method gets called after the GUI is
% created but before control returns to the command line.
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    varargout{1} = handles.output;
    set(handles.startButton, 'String', 'Start','BackgroundColor', 'green');
end

%% selection change in maxISIMenu.
function maxISIMenu_Callback(hObject, eventdata, handles)
    setISIMaxS(handles.isiPlot);
end

%% Set up the LabJack
function lbj = openLabJack()
%  get hardware info and do not continue if daq device/drivers unavailable

    lbj = labJackU6;                        % create the daq object
    open(lbj);                              % open connection to the daq
    if isempty(lbj.handle)
        originalSize = get(0, 'DefaultUIControlFontSize');
        set(0, 'DefaultUIControlFontSize', 14);
        questdlg('Exit and check USB connections.', 'No LabJack Device Found', 'OK', 'OK');
        set(0, 'DefaultUIControlFontSize', originalSize);
    else
        fprintf(1,'StretchReceptor: LabJack Ready\n\n');
    end
    % create input channel list
    removeChannel(lbj, -1);                     % remove all input channels
    addChannel(lbj, 0, 10, ['s' 's']);          % add channel 0 as input
    lbj.SampleRateHz = 5000;                    % sample rate (Hz)
    lbj.ResolutionADC = 1;                      % ADC resolution (AD bit depth)

    % configure LabJack for analog input streaming

    errorCode = streamConfigure(lbj);
    if errorCode > 0
        fprintf(1,'StretchReceptor: Unable to configure LabJack. Error %d.\n',errorCode);
        return
    end
end

%% openSR: just before gui is made visible.
function openSR(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SR (see VARARGIN)

    % test mode requires connecting DAC0 to AIN0 and DAC1 to AIN1 on the LabJack
    if ~isempty(varargin)
        testMode = strcmp(varargin{1}, 'debug') || strcmp(varargin{1}, 'test');
    else
        testMode = false;
    end
    if testMode
        set(handles.warnText, 'string', 'Test Mode');
    end   
    handles.output = hObject;                                      	% select default command line output
    set(hObject, 'CloseRequestFcn', {@closeSR, handles});          	% close function will close LabJack
    handles.lbj = openLabJack();                                    % LJ first, it has no contigencies
    handles.data = SRData(handles);                                 % data next
    handles.isiPlot = SRISIPlot(handles);                           % isi plot before signal processing
    handles.signals = SRSignalProcess(handles);                     % signal processing after data
    handles.plots = SRPlots(handles);                              	% plots after handles.data
    
    handles.signals.fH = handles;
       
    % set up test mode
    handles.data.testMode = testMode;
    if handles.data.testMode
        analogOut(handles.lbj, 0, 2.5);                             % For debugging (AOuts to AIns)
    end
    movegui(hObject, 'northeast');
    guidata(hObject, handles);                                                   % save the selection
end

%% button press in retriggerButton.
function retriggerButton_Callback(hObject, eventdata, handles)
    clearTriggerPlot(handles.plots, handles);
end   % retriggerButton_Callback()

%% executes on button press in saveDataButton.
function saveDataButton_Callback(hObject, eventdata, handles)
% Saving the workspace for a GUI isn't simple.  What we have accessible in this
% environment is mostly the handles.  If we save, it's an attempt to save
% handles, which doesn't work.  Instead, we get a list of all the properties
% from the SRTaskData class, and then use eval statement to assign those to
% local variable and save them (one by one).
    SRControlState(handles, 'off', {})
    [fileName, filePath] = uiputfile('*.mat', 'Save Matlab Data Workspace', '~/Desktop/SRData.mat');
    if fileName ~= 0
        isiMS = handles.isiPlot.isiMS(1:handles.isiPlot.isiNum);
        save([filePath fileName], 'isiMS');
    end
    SRControlState(handles, 'on', {})
end

%% respond to button press in savePlotsButton.
function savePlotsButton_Callback(hObject, eventdata, handles)
% hObject    handle to savePlotsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    SRControlState(handles, 'off', {})
    [fileName, filePath] = uiputfile('*.pdf', 'Save Window Plots as PDF', '~/Desktop/SRPlots.pdf');
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
    SRControlState(handles, 'on', {})
end

%% button press in singleSpikeCheckbox.
function singleSpikeCheckbox_Callback(hObject, eventdata, handles)
    handles.plots.singleSpike = get(hObject, 'value');
    if handles.plots.singleSpike
        set(handles.retriggerButton, 'Enable', 'on');
        retriggerButton_Callback(hObject, eventdata, handles);  % clear plot and enable for a single spike
    else
        set(handles.retriggerButton, 'Enable', 'off');
    end
	guidata(hObject, handles);                                  % save change
end   % singleSpikeCheckbox_Callback()

%% button press in singleTraceCheckbox.
function singleTraceCheckbox_Callback(hObject, eventdata, handles)
    handles.data.singleTrace = get(hObject, 'value');
	guidata(hObject, handles);                                  % save change
end

%% respond to start/stop button presses

function startButton_Callback(hObject, eventdata, handles)                  
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    if strcmp(get(handles.startButton, 'String'), 'Start') % if start button, do the following
        fprintf(1,'\nStretchReceptor v1.0\n %s\n', datestr(clock));
%         handles.data.dataState = DataState.dataIdle;            % set data state to idle
        dataCollectRateHz = 25;                                 % prevent overflow w/o blocking other activity
        handles.dataTimer = timer('Name', 'CollectData', 'ExecutionMode', 'fixedRate',...
            'Period', 1.0 / dataCollectRateHz, 'UserData', handles, 'ErrorFcn', {@collectError, handles},...
            'TimerFcn', {@collectData}, 'StartDelay', 0.050);   % startDelay allows rest of the gui to execute

        % create timer to make fake spikes for LabJack
        if handles.data.testMode
            fakeSpikeRateHz = 4;
            handles.fakeSpikeTimer = timer('Name', 'FakeSpikes', 'ExecutionMode', 'fixedRate',...
                'Period', 1.0 / fakeSpikeRateHz, 'UserData', handles, 'ErrorFcn', {@fakeSpikeError, handles},...
                'TimerFcn', {@fakeSpike}, 'StartDelay', 0.050);
        end
        
        % set the gui button to "running" state
        % clear the plots
        if handles.plots.singleSpike
            clearContPlot(handles.plots, handles);
        else
           	clearAll(handles.plots, handles);
            handles.data.lastSpikeIndex = 2 * handles.data.maxContSamples;      % flag start of ISI sequence
        end
        
        set(handles.startButton, 'String', 'Stop', 'BackgroundColor', 'red');
        SRControlState(handles, 'off', {handles.startButton})
        startStream(handles.lbj);

        % Start plots, data pickup, and data acquisition 
        start(handles.dataTimer);
        if handles.data.testMode
            start(handles.fakeSpikeTimer);
        end
%         profile on;

    % Stop -- we're already running, so it's a the stop button    
    else % stop
        stop(timerfind);                                        % stop/delete timers; pause data stream
        delete(timerfind);      
        handles.dataTimer = 0;
        handles.fakeSpikeTimer = 0;
        stopStream(handles.lbj);
        clearAll(handles.signals);                              % stop audio processing
        set(handles.startButton, 'string', 'Start','backgroundColor', 'green');
        SRControlState(handles, 'on', {handles.startButton})
        drawnow;
%         profile viewer
    end
    guidata(hObject, handles);                                  % save variables
end

%% threshold slider has a new value
function thresholdSlider_Callback(hObject, eventdata, handles)
    handles.data.thresholdV = get(hObject, 'value');
    clearTriggerPlot(handles.plots, handles);
	guidata(hObject, handles);                                  % save change
end

%% change in vPerDivButton.
function vPerDivButton_Callback(hObject, eventdata, handles)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    contents = cellstr(get(hObject,'String'));
    newValue = str2double(contents{get(hObject, 'Value')});
    if newValue ~= handles.data.vPerDiv
        handles.data.vPerDiv = newValue;
        if strcmp(get(handles.startButton, 'String'), 'Start')  % if we're not running
           setLimits(handles.data, handles);
           clearAll(handles.plots, handles);
        else
           handles.data.contPlotRescale = true;                % else let dataCollect do the update
        end
    end
	guidata(hObject, handles);                                  % save change
end

%% volume slider has new value
function volumeSlider_Callback(hObject, eventdata, handles)
    setVolume(handles.signals);
end
