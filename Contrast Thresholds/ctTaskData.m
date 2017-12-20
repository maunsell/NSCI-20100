classdef ctTaskData < handle
    % ctTaskData: common data for Contrasts Thresholds
    properties
        baseContrasts;
        blocksFit;
        curveFits;
        doStim;
        hits;
        multIndex;
        multipliers;
        numBases;
        numMultipliers;
        output;
        resultsTable;
        sampFreqHz;
        stimStartTimeS;
        stimParams;
        taskState;
        trialsDone;
        trialStartTimeS;
        testMode;
        theKey;
        tones;
    end
    
    methods
        function obj = ctTaskData(baseContrastMenu)

            %% Object Initialization %%
            obj = obj@handle();                                            % object initialization
            %% Post Initialization %%
            
            obj.testMode = false;
            obj.doStim = true;
           
            tones = [];
            audioFiles = {'Tone0250.wav', 'Tone2000.wav', 'Tone4000.wav'};
            for i = 1:length(audioFiles)
                [y, sampFreqHz] = audioread(char(audioFiles(i)));
                tones = [tones y(:)];
            end
            obj.tones = tones';
            obj.sampFreqHz = sampFreqHz;
            contrastStrings = get(baseContrastMenu, 'string');
            obj.numBases = length(contrastStrings);                             % number of base contrasts from menu
            obj.baseContrasts = zeros(1, obj.numBases);                     % memory for the base contrasts
            for i = 1:obj.numBases
                obj.baseContrasts(i) = sscanf(contrastStrings{i}, '%f') / 100.0;
            end
            obj.multIndex = 0;
            obj.multipliers = [1.0375 1.075 1.15 1.50 2.0];
            obj.numMultipliers = length(obj.multipliers);
            obj.trialsDone = zeros(obj.numBases, obj.numMultipliers);
            obj.hits = zeros(obj.numBases, obj.numMultipliers);
            obj.blocksFit = zeros(1, obj.numBases);
            obj.curveFits = zeros(obj.numBases, obj.numMultipliers);
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

