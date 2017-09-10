function varargout = contrastThresholds(varargin)
    % CONTRASTTHRESHOLDS MATLAB code for contrastThresholds.fig
    %      CONTRASTTHRESHOLDS, by itself, creates a new CONTRASTTHRESHOLDS or raises the existing
    %      singleton*.
    %
    %      H = CONTRASTTHRESHOLDS returns the handle to a new CONTRASTTHRESHOLDS or the handle to
    %      the existing singleton*.
    %
    %      CONTRASTTHRESHOLDS('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in CONTRASTTHRESHOLDS.M with the given input arguments.
    %
    %      CONTRASTTHRESHOLDS('Property','Value',...) creates a new CONTRASTTHRESHOLDS or raises
    %      the existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before contrastThresholds_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to contrastThresholds_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help contrastThresholds

    % Last Modified by GUIDE v2.5 10-Sep-2017 16:54:07

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

function handles = drawHitRates(handles)
    baseIndex = get(handles.baseContrastMenu, 'value');
    x = handles.baseContrasts' * handles.multipliers;
    hitRate = zeros(size(handles.trialsDone));
    errNeg = zeros(size(handles.trialsDone));
    errPos = zeros(size(handles.trialsDone));
    pci = zeros(size(handles.trialsDone, 1), size(handles.trialsDone, 2), 2);
    for i = 1:(size(handles.trialsDone, 1)) 
        [hitRate(i,:), pci(i,:,:)] = binofit(handles.hits(i, :), handles.trialsDone(i, :));
        errNeg(i, :) = hitRate(i, :) - pci(i, :, 1);
        errPos(i, :) = pci(i, :, 2) - hitRate(i, :);
        % If we have enough blocks, fit a logistic functions.  Include 0.5
        % performance at base contrast
        if i == baseIndex
            blocksDone = floor(mean(handles.trialsDone(i, :)));
            tableData = get(handles.resultsTable,'Data');
            tableData{1, i} = sprintf('%.0f', blocksDone);
            if blocksDone > handles.blocksFit(i) && blocksDone > 5 
                xData = [handles.baseContrasts(i) (handles.baseContrasts(i) * handles.multipliers)];
                yData = [0.5 hitRate(i,:)];
                x0 = [xData(ceil(length(xData) / 2)); 5];
                lowBounds = [handles.baseContrasts(i); 1];
                highBounds = [5; 1000];
                fun=@(params, xData) 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData - params(1))));
                options = optimset('Display', 'off');
                [params, ~] = lsqcurvefit(fun, x0, xData, yData, lowBounds, highBounds, options);
                handles.curveFits(i, :) = 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData(2:end) - params(1))));
                handles.blocksFit(i) = blocksDone;
                tableData{2, i} = sprintf('%.1f%%', params(1) * 100.0);
                tableData{3, i} = sprintf('%.1f%%', (params(1) - handles.baseContrasts(i)) * 100.0);
                tableData{4, i} = sprintf('%.2f', (params(1) / handles.baseContrasts(i)));
            end
            set(handles.resultsTable, 'Data', tableData); 
        end
    end
    errorbar(x', hitRate', errNeg', errPos', 'o');
    hold on;
    plot(x', handles.curveFits', '-');
    plot(repmat(handles.baseContrasts, 2, 1), repmat([0; 1], 1, 4));
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
    trialsPerBlock = size(handles.trialsDone, 2);
    blocksDone = min(handles.trialsDone(baseIndex, :));
    undone = find(handles.trialsDone(baseIndex, :) == blocksDone);
    set(handles.statusText, 'string', {runString, statusString, '', ...
           sprintf('      Trial %d of %d', trialsPerBlock - length(undone) + 1, trialsPerBlock)});
    drawnow;
end

% --- Outputs from this function are returned to the command line.
function varargout = initContrastThresholds(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
    set(handles.runButton, 'String', 'Start','BackgroundColor', 'green');
end

% --- Executes just before contrastThresholds is made visible.
function openContrastThresholds(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to contrastThresholds (see VARARGIN)
    audioFiles = {'Tone0250.wav', 'Tone2000.wav', 'Tone4000.wav'};

    rng('shuffle');
    tones = [];
    for i = 1:length(audioFiles)
        [y, sampFreqHz] = audioread(char(audioFiles(i)));
        tones = [tones y(:)];
    end
    
    handles.testMode = true;
    handles.doStim = true;
    handles.sampFreqHz = sampFreqHz;
    handles.tones = tones';
%     handles.axes1 = ha;
%     handles.baseContrastMenu = baseContrastMenu;
    contrastStrings = get(handles.baseContrastMenu, 'string');
    handles.numBases = length(contrastStrings);                             % number of base contrasts from menu
    handles.baseContrasts = zeros(1, handles.numBases);                     % memory for the base contrasts
    for i = 1:handles.numBases
        handles.baseContrasts(i) = sscanf(contrastStrings{i}, '%d') / 100.0;
    end
    handles.multipliers = [1.0625 1.125 1.25 1.5 2.0];
    handles.numMultipliers = length(handles.multipliers);
    handles.trialsDone = zeros(handles.numBases, handles.numMultipliers);
    handles.hits = zeros(handles.numBases, handles.numMultipliers);
%     handles.hStatusText = hStatusText;
    handles.stimuli = ctStimuli;
    handles.output = hObject;                                                   % select default command line output

    % parameters related to plotting curve fits
    handles.blocksFit = zeros(1, handles.numBases);
    handles.curveFits = zeros(handles.numBases, handles.numMultipliers);
%     handles.resultsTable = resultsTable;
%     handles.f = f;
%     guidata(hGo, handles);

    drawStatusText(handles, 'idle')
    set(handles.figure1, 'visible', 'on');
    movegui(handles.figure1,'southeast')
    guidata(hObject, handles);                                                   % save the selection
end
% UIWAIT makes contrastThresholds wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Executes on button press in ClearDataButton.
function ClearDataButton_Callback(hObject, eventdata, handles)
    % hObject    handle to ClearDataButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
% 
end
% --- Executes on button press in runButton.
function runButton_Callback(hObject, eventdata, handles)
    % hObject    handle to runButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

%     initialize_gui(gcbf, handles, true);

    set(handles.runButton, 'enable', 'off');
    set(handles.runButton, 'string', '(esc to stop)');
    set(handles.runButton, 'string', 'Run','backgroundColor', 'red');
    drawnow;
%     handles = guidata(hObject); 

    handles
    
    
    
    stimParams.stimReps = get(handles.stimRepsTextBox, 'value');
    stimParams.stimDurS = get(handles.stimDurText, 'value');
    baseIndex = get(handles.baseContrastMenu, 'value');
    baseContrast = handles.baseContrasts(baseIndex);
    stopStimuli = false;
    while (~stopStimuli)
        % Pick a trial to do
        blocksDone = min(handles.trialsDone(baseIndex, :));
        undone = find(handles.trialsDone(baseIndex, :) == blocksDone);
        multIndex = undone(ceil(length(undone) * (rand(1, 1))));
        changeSide = floor(2 * rand(1, 1));       
        
        % Draw dark gray fixspot and wait for keystroke
        sound(handles.tones(3, :), handles.sampFreqHz);
        if handles.doStim
            doFixSpot(handles.stimuli, 0.65);
            drawStatusText(handles, 'wait')
        end
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        while (~handles.testMode && ~keyIsDown)
            [keyIsDown, ~, keyCode] = KbCheck(-1);
        end
        if keyCode(KbName('escape')) || keyCode(KbName('space'))
            stopStimuli = true;
        else
        % Draw the base stimuli with a white fixspot
            if handles.doStim
                drawStatusText(handles, 'run')
                stimParams.leftContrast = baseContrast;
                stimParams.rightContrast = baseContrast;
                doStimulus(handles.stimuli, stimParams);
            end
            [~, ~, keyCode] = KbCheck(-1);
        if keyCode(KbName('escape')) || keyCode(KbName('space'))
                stopStimuli = true;
            end
        end
        if ~stopStimuli
        % Draw the test stimuli, followed by the gray fixspot
            if (changeSide == 0)
                stimParams.leftContrast = baseContrast * handles.multipliers(multIndex);
                stimParams.rightContrast = baseContrast;
            else
                stimParams.leftContrast = baseContrast;
                stimParams.rightContrast = baseContrast * handles.multipliers(multIndex);
            end
            if handles.doStim
                doStimulus(handles.stimuli, stimParams);
                doFixSpot(handles.stimuli, 0.0);
                drawStatusText(handles, 'response')
           end
        end
        % Get reponse from subject
        if ~stopStimuli
            hit = -1;
            responsePending = true;
            if handles.testMode
                prob = 0.5 + 0.5 / (1.0 + exp(-10.0 * (handles.multipliers(multIndex) - handles.multipliers(3))));
                hit = rand(1,1) < prob;
                responsePending = false;
            end
            while responsePending
                [~, ~, keyCode] = KbCheck(-1);
                if keyCode(KbName('escape')) || keyCode(KbName('space'))
                    responsePending = false;
                    stopStimuli = true;
                else
                    if keyCode(KbName('LeftArrow'))
                        hit = changeSide == 0;
                    elseif keyCode(KbName('RightArrow'))
                        hit = changeSide == 1;
                    end
                    responsePending = false;
                end
            end
            if (hit >= 0)
                if (hit == 1)
                    handles.hits(baseIndex, multIndex) = handles.hits(baseIndex, multIndex) + hit;
                    sound(handles.tones(2, :), handles.sampFreqHz);
                else
                    sound(handles.tones(1, :), handles.sampFreqHz);
                end
                handles.trialsDone(baseIndex, multIndex) = handles.trialsDone(baseIndex, multIndex) + 1;
%                 display(sprintf('mIndex %d side %d base %f mult %f contrasts %f %f', multIndex, changeSide, ...
%                     baseContrast, handles.multipliers(multIndex), ...
%                     stimParams.leftContrast, stimParams.rightContrast));
            end
        end
        if handles.doStim
            clearScreen(handles.stimuli);
        end
        handles = drawHitRates(handles);
        % Check whether we are done with all the trials
        stimReps = get(handles.stimRepsTextBox, 'value');
        if sum(handles.trialsDone(baseIndex, :)) >= stimParams.stimReps * handles.numMultipliers
            if (~handles.testMode)                      % if we're not in test mode, we're done testing
                stopStimuli = true;
            else                                        % if we're testing, see if there are more to do
                if sum(sum(handles.trialsDone)) >=  stimParams.stimReps * handles.numMultipliers * handles.numBases
                    stopStimuli = true;
                else                                    % more to do, try the next multiplier
                    while sum(handles.trialsDone(baseIndex, :)) >= stimParams.stimReps * handles.numMultipliers
                        baseIndex = mod(baseIndex, handles.numBases) + 1;
                    end
                    set(handles.baseContrastMenu, 'value', baseIndex);
                end
            end
        end
        % Update the status text
        if (~stopStimuli)
            drawStatusText(handles, 'intertrial')
            if (~handles.testMode && handles.doStim)
                pause(get(handles.preStimTimeText, 'value'));          % interstimulus interval
            end
            [~, ~, keyCode] = KbCheck(-1);
            if keyCode(KbName('escape')) || keyCode(KbName('space'))
                stopStimuli = true;
                break;
            end
        end
    end
    if handles.doStim
        clearScreen(handles.stimuli);
    end
    drawStatusText(handles, 'idle')
    set(handles.runButton, 'string', 'Run','backgroundColor', 'green');
    set(handles.runButton, 'enable', 'on');
    drawnow;
    guidata(hObject, handles);                          % save the changes
end

% --- Executes on selection change in baseContrastMenu.
function baseContrastMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to baseContrastMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns baseContrastMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from baseContrastMenu
end

function stimRepsTextBox_Callback(hObject, eventdata, handles)
    % hObject    handle to stimRepsTextBox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of stimRepsTextBox as text
    %        str2double(get(hObject,'String')) returns contents of stimRepsTextBox as a double
end

% --- Executes during object creation, after setting all properties.
function stimRepsTextBox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to stimRepsTextBox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function stimDurText_Callback(hObject, eventdata, handles)
% hObject    handle to stimDurText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stimDurText as text
%        str2double(get(hObject,'String')) returns contents of stimDurText as a double
end

% --- Executes during object creation, after setting all properties.
function stimDurText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to stimDurText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function preStimTimeText_Callback(hObject, eventdata, handles)
    % hObject    handle to preStimTimeText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of preStimTimeText as text
    %        str2double(get(hObject,'String')) returns contents of preStimTimeText as a double
end

% --- Executes during object creation, after setting all properties.
function preStimTimeText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to preStimTimeText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes when user attempts to close figure1.
function windowCloseRequest(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Clean up the stimulus window when the GUI is closed.
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
