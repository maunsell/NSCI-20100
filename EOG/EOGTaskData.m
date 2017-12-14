classdef EOGTaskData < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
        blocksDone;
        dataState;
        numChannels;
        numOffsets;
        numSummed;
        offsetIndex;
     	offsetsDeg;
        offsetsDone;
        posAvg;
        posSummed;
        posTrace;
        prestimDurS;
        rawData;
        sampleRateHz;
        samplesRead;
        saccadeDurS;
        saccadeSamples;
        saccadeTraceS;
        startStimS;
        stepSign;
        stimTimeS;
        trialDurS;
        trialSamples;
        taskState;
        testMode;
        trialStartTimeS;
        velTrace;
        velSummed;
        velAvg;
        voltage;
    end
    
    methods
        function obj = EOGTaskData(numChannels, sampleRateHz)

             %% Object Initialization %%
             obj = obj@handle();                                            % object initialization

             %% Post Initialization %%
            obj.offsetsDeg = [4 8 12 16];
            obj.numOffsets = length(obj.offsetsDeg);
            obj.stepSign = 1;
            obj.offsetIndex = 1;
            obj.offsetsDone = zeros(1, obj.numOffsets);
            obj.blocksDone = 0;
            obj.sampleRateHz = sampleRateHz;
            obj.saccadeDurS = zeros(1, obj.numOffsets);                     % average saccade durations
            obj.saccadeTraceS = 0.250;                                      % duratoin of saccade trace
            obj.saccadeSamples = floor(obj.saccadeTraceS * obj.sampleRateHz);
            obj.trialDurS = max(0.50, 2 * obj.saccadeTraceS);
            obj.trialSamples = floor(obj.trialDurS * obj.sampleRateHz);
            obj.prestimDurS = min(obj.trialDurS / 4, 0.250);
            obj.taskState = TaskState.taskStarttrial;
            obj.dataState = DataState.dataIdle;
            obj.trialStartTimeS = 0;
            obj.samplesRead = 0;
            obj.startStimS = 0;
            obj.stimTimeS = 0;
            obj.numSummed = zeros(1, obj.numOffsets);
            obj.numChannels = numChannels;
            obj.rawData = zeros(obj.trialSamples, numChannels);             % raw data
            obj.posTrace = zeros(obj.trialSamples, 1);                     	% trial EOG position trace
            obj.posSummed = zeros(obj.saccadeSamples, obj.numOffsets);      % summed position traces
            obj.posAvg = zeros(obj.saccadeSamples, obj.numOffsets);         % averaged position traces
            obj.testMode = false;
            obj.velTrace = zeros(obj.trialSamples, 1);                      % trial EOG velocity trace
            obj.velSummed = zeros(obj.saccadeSamples, obj.numOffsets);      % summed position traces
            obj.velAvg = zeros(obj.saccadeSamples, obj.numOffsets);         % averaged position traces
            obj.voltage = 0;
        end

        %% clearAll
        function clearAll(obj)
            obj.offsetsDone = zeros(1, obj.numOffsets);
            obj.blocksDone = 0;
            obj.numSummed = zeros(1, obj.numOffsets);
            obj.rawData = zeros(obj.trialSamples, obj.numChannels);       % raw data
            obj.posTrace = zeros(obj.trialSamples, 1);                    % trial EOG position trace
            obj.posSummed = zeros(obj.saccadeSamples, obj.numOffsets);    % summed position traces
            obj.posAvg = zeros(obj.saccadeSamples, obj.numOffsets);       % averaged position traces
            obj.velTrace = zeros(obj.trialSamples, 1);                    % trial EOG velocity trace
            obj.velSummed = zeros(obj.saccadeSamples, obj.numOffsets);    % summed position traces
            obj.velAvg = zeros(obj.saccadeSamples, obj.numOffsets);       % averaged position traces
        end
    end
    
end

