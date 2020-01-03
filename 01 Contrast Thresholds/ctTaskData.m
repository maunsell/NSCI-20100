classdef ctTaskData < handle
    % ctTaskData: common data for Contrasts Thresholds
    properties
        baseContrasts;
        blocksFit;
        curveFits;
        doStim;
        doStimDisplay;
        hits;
        numBases;
        numIncrements;
        output;
        resultsTable;
        sampFreqHz;
        stimStartTimeS;
        stimParams;
        taskState;
        testContrasts;
        testIndex;
        testMode;
        trialsDone;
        trialStartTimeS;
        theKey;
        tones;
    end
    
    methods
        %% ctTaskData
        function obj = ctTaskData(baseContrastMenu)

            %% Object Initialization %%
            obj = obj@handle();                                             % object initialization
            %% Post Initialization %%
            
            obj.testMode = false;
            obj.doStimDisplay = true;                                       % for PsychToolbox not working
            obj.doStim = true;                                              % for faster debugging
           
            tones = [];
            audioFiles = {'Tone0250.wav', 'Tone2000.wav', 'Tone4000.wav'};
            for i = 1:length(audioFiles)
                [y, sampFreqHz] = audioread(char(audioFiles(i)));
                tones = [tones y(:)];
            end
            obj.tones = tones';
            obj.sampFreqHz = sampFreqHz;
%             obj.multipliers = [1.0375 1.075 1.15 1.50 2.0];
            obj.baseContrasts = [0.03 0.058 0.12 0.24 0.48];
            obj.numBases = length(obj.baseContrasts);
            obj.testContrasts = [0.032	0.034 0.045 0.052 0.060;...
                0.062 0.071 0.084 0.096 0.121;...
                0.126 0.133 0.140 0.180 0.238;...
                0.249 0.260 0.271 0.357 0.480;...
                0.495 0.514 0.550 0.718 0.961];
            obj.numIncrements = size(obj.testContrasts, 2);
            contrastStrings = cell(1, obj.numBases);
            for i = 1:obj.numBases
                contrastStrings{i} = sprintf('%.0f%%', obj.baseContrasts(i) * 100.0);
%                 obj.baseContrasts(i) = sscanf(contrastStrings{i}, '%f') / 100.0;
            end
            set(baseContrastMenu, 'string', contrastStrings);
            obj.testIndex = 0;
            obj.trialsDone = zeros(obj.numBases, obj.numIncrements);
            obj.hits = zeros(obj.numBases, obj.numIncrements);
            obj.blocksFit = zeros(1, obj.numBases);
            obj.curveFits = zeros(obj.numBases, obj.numIncrements + 1);
            obj.taskState = ctTaskState.taskStopped;
            obj.trialStartTimeS = 0;
            obj.theKey = '';
            obj.stimParams = struct;
        end

        %% clearAll
        function clearAll(obj, baseContrastMenu, resultsTable)
            baseIndex = get(baseContrastMenu, 'value');
            obj.trialsDone(baseIndex, :) = 0;
            obj.hits(baseIndex, :) = 0;
            obj.blocksFit(baseIndex) = 0;
            obj.curveFits(baseIndex, :) = 0;
            tableData = get(resultsTable,'Data');
            tableData{1, baseIndex} = '0';
            for i = 2:4
                tableData{i, baseIndex} = {'--'};
            end
            set(obj.resultsTable, 'Data', tableData); 
        end
    end
    
end

