function contrastThresholds

clear all;                      % PTB gets in trouble sometimes if you don't clear functions
% close all;
% look for existing data file and reload it

figXPix = 612;
figYPix = 792;
labelBaseY = 125;
audioFiles = {'Tone0250.wav', 'Tone2000.wav', 'Tone4000.wav'};

f = figure('visible','off','position', [0, 0, figXPix, figYPix], 'name', 'Contrast Threshold', ...
    'CloseRequestFcn', @windowCloseRequest);
set(f, 'KeyPressFcn', @(x,y)disp(get(f,'CurrentCharacter')));


labels = {'Intertrial time (s):', 'Pre-stimulus time (s):', 'Stimulus duration (s):', 'Stimulus repeats:'};
textValues = [2.0 1.0 0.25 25];

staticTextHandles = nan(1, length(labels));
textFields = nan(1, length(labels));
for i = 1:length(labels)
    staticTextHandles(i) = uicontrol('style', 'text', 'string', labels{i}, 'horizontalAlignment', 'right', ...
        'backgroundColor', [0.8 0.8 0.8], 'position', [15, figYPix - (labelBaseY - (i - 1) * 25) - 6, 100, 25]);
	textFields(i) = uicontrol('style', 'edit', 'string', num2str(textValues(i)), 'tag', sprintf('%d', i),...
        'position', [125, figYPix - (labelBaseY - (i - 1) * 25), 65, 25], 'callback', {@editCallback});
end
align(staticTextHandles, 'center', 'fixed', 6);
align(textFields, 'center', 'fixed', 6);

hGoText = uicontrol('style', 'text', 'string', 'Base contrast:', 'horizontalAlignment', 'right', ...
        'backgroundColor', [0.8 0.8 0.8], ...
        'position', [200, figYPix - labelBaseY - 6, 100, 25]);

hBaseContrast = uicontrol('Style', 'popupmenu', 'String', {'6.25%', '12.5%', '25%', '50%'}, ...
    'position', [315, figYPix - 50, 80, 25], 'callback', {@baseContrastCallback});
strings = get(hBaseContrast, 'string');
numBases = length(strings);
baseContrasts = zeros(1, numBases);
for i = 1:length(strings)
    baseContrasts(i) = sscanf(strings{i}, '%d') / 100.0;
end
hGo = uicontrol('style','pushbutton','string','Go', 'tag', 'goButton', ...
    'position', [315, figYPix - labelBaseY, 80, 25], 'callback', @(hGo, eventdata)goButtonCallback(hGo, eventdata));
hClear = uicontrol('style','pushbutton','string','Clear', 'tag', 'clearButton', ...
    'position', [315, figYPix - (labelBaseY - (i - 1) * 25), 80, 25], ...
    'callback', @(hClear, eventdata)clearButtonCallback(hClear, eventdata));
align([hClear, hGo, hBaseContrast], 'center', 'fixed', 10);

hStatusText = uicontrol(f,'style','text', 'Max', 3, 'Min', 0, 'Position', [15 (figYPix - 250) 300 150], ...
    'backgroundColor', [0.8 0.8 0.8], 'horizontalAlignment', 'left');
hTable = uitable(f, 'Position', [50, 250, 325, 90], ...
    'Data', repmat({' ---', ' ---', ' ---', ' ---'}, 4, 1), ...
    'ColumnWidth', {50}, 'columnName', strings, ...
    'rowName', {'Blocks Done', 'Threshold', 'Difference', 'Multiplier'});
        
ha = axes('Units','Pixels','Position', [50, 50, 300, 150], 'nextplot', 'replacechildren');

movegui(f,'southeast')
rng('shuffle');

tones = [];
for i = 1:length(audioFiles)
    [y, sampFreqHz] = audioread(char(audioFiles(i)));
    tones = [tones y(:)];
end

handles = guidata(hGo);
handles.testMode = true;
handles.doStim = false;
handles.sampFreqHz = sampFreqHz;
handles.tones = tones';
handles.hAxes = ha;
handles.hBaseContrast = hBaseContrast;
handles.numBases = numBases;
handles.baseContrasts = baseContrasts;
handles.multipliers = [1.0625 1.125 1.25 1.5 2.0];
handles.numMultipliers = length(handles.multipliers);
handles.trialsDone = zeros(numBases, handles.numMultipliers);
handles.hits = zeros(numBases, handles.numMultipliers);
handles.textFields = textFields;
handles.textValues = textValues;
handles.hStatusText = hStatusText;
handles.stimuli = ctStimuli;

% parameters related to plotting curve fits
handles.blocksFit = zeros(1, numBases);
handles.curveFits = zeros(numBases, handles.numMultipliers);
handles.hTable = hTable;
handles.f = f;
guidata(hGo, handles);

drawStatusText(handles, 'idle')
set(f, 'visible', 'on');
end

%Base contrast pop-up menu callback. 
function baseContrastCallback(hObject, ~)
    strings = get(hObject, 'string');
    itemString = strings{get(hObject, 'value')};
    handles = guidata(hObject);
    handles.baseContrast = sscanf(itemString, '%d') / 100.0;
    guidata(hObject, handles);
    drawStatusText(handles, 'idle');
end
   
function clearButtonCallback(hObject, ~)
    handles = guidata(hObject);
    strings = get(handles.hBaseContrast, 'string');
    itemString = strings{get(handles.hBaseContrast, 'value')};
    selection = questdlg(sprintf('Really clear data for %s contrast? (This cannot be undone).', itemString), ...
        'Clear Data', 'Yes', 'No', 'Yes');
    switch selection
        case 'Yes'
            baseIndex = get(handles.hBaseContrast, 'value');
            handles.trialsDone(baseIndex, :) = 0;
            handles.hits(baseIndex, :) = 0;
            handles.blocksFit(baseIndex) = 0;
            handles.curveFits(baseIndex, :) = 0;
            tableData = get(handles.hTable,'Data');
            tableData{1, baseIndex} = '0';
            tableData{2, baseIndex} = '--';
            tableData{3, baseIndex} = '--';
            tableData{4, baseIndex} = '--';
            set(handles.hTable, 'Data', tableData); 
            drawHitRates(handles);
            guidata(hObject, handles);
    end
end

function handles = drawHitRates(handles)
    baseIndex = get(handles.hBaseContrast, 'value');
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
            tableData = get(handles.hTable,'Data');
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
            set(handles.hTable, 'Data', tableData); 
        end
    end
    errorbar(x', hitRate', errNeg', errPos', 'o');
    hold on;
    plot(x', handles.curveFits', '-');
    plot(repmat(handles.baseContrasts, 2, 1), repmat([0; 1], 1, 4));
    axis([0.05, 1.0, 0.0 1.0]);
    set (handles.hAxes, 'xGrid', 'on', 'yGrid', 'off');
    set(handles.hAxes, 'yTick', [0.0; 0.2; 0.4; 0.6; 0.8; 1.0]);
    set(handles.hAxes, 'yTickLabel', [0; 20; 40; 60; 80; 100]);
    set(handles.hAxes, 'xTick', [0.05; 0.06; 0.07; 0.08; 0.09; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.8; 1.0]);
    set(handles.hAxes, 'xTickLabel', [5; 6; 7; 8; 9; 10; 20; 30; 40; 50; 60; 80; 100]);
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
    baseIndex = get(handles.hBaseContrast, 'value');
    trialsPerBlock = size(handles.trialsDone, 2);
    blocksDone = min(handles.trialsDone(baseIndex, :));
    undone = find(handles.trialsDone(baseIndex, :) == blocksDone);
    set(handles.hStatusText, 'string', {runString, statusString, '', ...
           sprintf('      Trial %d of %d', trialsPerBlock - length(undone) + 1, trialsPerBlock)});
    drawnow;
end

function editCallback(hObject, ~, ~)
    handles = guidata(hObject);
    i = str2double(get(hObject, 'tag'));
    input = str2double(get(hObject, 'string'));
    if isnan(input)
        errordlg('You must enter a numeric value', 'Invalid Input', 'modal');
        uiwait;
        set(hObject, 'string', num2str(handles.textValues(i)));
    else
        display(input);
        handles.textValues(i) = input;
        guidata(hObject, handles);
    end
end

function goButtonCallback(hObject, ~)
    set(hObject,'enable','off');
    set(hObject, 'string', '(esc to stop)');
    drawnow;
    handles = guidata(hObject);   
    stimParams.stimReps = handles.textValues(4);
    strings = get(handles.hBaseContrast, 'string');
    baseIndex = get(handles.hBaseContrast, 'value');
    itemString = strings{baseIndex};
    baseContrast = sscanf(itemString, '%d') / 100.0;
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
        if keyCode(KbName('Escape'))
            stopStimuli = true;
        else
        % Draw the base stimuli with a white fixspot
            if handles.doStim
                drawStatusText(handles, 'run')
                stimParams.leftContrast = baseContrast;
                stimParams.rightContrast = baseContrast;
                stimParams.stimDurS = handles.textValues(2);
                doStimulus(handles.stimuli, stimParams);
            end
            [~, ~, keyCode] = KbCheck(-1);
            if keyCode(KbName('Escape'))
                stopStimuli = true;
            end
        end
        if ~stopStimuli
        % Draw the test stimuli, followed by the gray fixspot
            stimParams.stimDurS = handles.textValues(3);
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
                if keyCode(KbName('Escape'))
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
        stimReps = get(handles.textFields(4), 'value');
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
                    set(handles.hBaseContrast, 'value', baseIndex);
                end
            end
        end
        % Update the status text
        if (~stopStimuli)
            drawStatusText(handles, 'intertrial')
            if (~handles.testMode && handles.doStim)
                pause(handles.textValues(1));          % interstimulus interval
            end
            [~, ~, keyCode] = KbCheck(-1);
            if keyCode(KbName('Escape'))
                stopStimuli = true;
                break;
            end
        end
    end
    if handles.doStim
        clearScreen(handles.stimuli);
    end
    drawStatusText(handles, 'idle')
    set(hObject, 'string', 'Go');
    set(hObject, 'enable', 'on');
    drawnow;
    guidata(hObject, handles);                          % save the changes
end

function windowCloseRequest(hObject, ~)
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
