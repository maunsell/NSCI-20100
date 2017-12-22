classdef EOGTaskData < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
        blocksDone;
        calTrialsDone;
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
            obj.offsetsDeg = [5 10 15 20];
            obj.numChannels = numChannels;
            obj.numOffsets = length(obj.offsetsDeg);
            obj.offsetIndex = 1;
            obj.stepSign = 1;
            obj.saccadeTraceS = 0.250;                                      % duratoin of saccade trace
            obj.trialDurS = max(1.0, 2 * obj.saccadeTraceS);
            obj.prestimDurS = min(obj.trialDurS / 4, 0.250);
            obj.taskState = TaskState.taskStarttrial;
            obj.dataState = DataState.dataIdle;
            obj.trialStartTimeS = 0;
            obj.samplesRead = 0;
            obj.startStimS = 0;
            obj.stimTimeS = 0;
            obj.testMode = false;
            obj.voltage = 0;

            setSampleRateHz(obj, sampleRateHz);
        end

        %% clearAll
        function clearAll(obj)
            obj.blocksDone = 0;
            obj.calTrialsDone = 0;
            obj.numSummed = zeros(1, obj.numOffsets);
            obj.offsetsDone = zeros(1, obj.numOffsets);
            obj.posTrace = zeros(obj.trialSamples, 1);                    % trial EOG position trace
            obj.posSummed = zeros(obj.saccadeSamples, obj.numOffsets);    % summed position traces
            obj.posAvg = zeros(obj.saccadeSamples, obj.numOffsets);       % averaged position traces
            obj.rawData = zeros(obj.trialSamples, obj.numChannels);       % raw data
            obj.saccadeDurS = zeros(1, obj.numOffsets);                   % average saccade durations
            obj.velTrace = zeros(obj.trialSamples, 1);                    % trial EOG velocity trace
            obj.velSummed = zeros(obj.saccadeSamples, obj.numOffsets);    % summed position traces
            obj.velAvg = zeros(obj.saccadeSamples, obj.numOffsets);       % averaged position traces
        end
        
        function setSampleRateHz(obj, rateHz)
            obj.sampleRateHz = rateHz;
            obj.saccadeSamples = floor(obj.saccadeTraceS * obj.sampleRateHz);
            obj.trialSamples = floor(obj.trialDurS * obj.sampleRateHz);
            clearAll(obj);                                                % clear -- and also re-size buffers
       end
    end
    
end

