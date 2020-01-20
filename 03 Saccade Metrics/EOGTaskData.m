classdef EOGTaskData < handle
    % EOGTaskData
    %   Support for processing eye traces and detecting saccades in EOG
    
    properties
        absStepIndex
        blocksDone;
        calTrialsDone;
        centeringTrial;
        dataState;
        doFilter;
        doStimDisplay;
        filterLP;
        filter60Hz;
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
        saccHalfTimeS;
        stepSign;
        stimStartPixel;
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
             obj = obj@handle();                                    % object initialization

             %% Post Initialization %%
            obj.offsetsDeg = [5 10 15 20 -5 -10 -15 -20];
            obj.numChannels = numChannels;
            obj.numOffsets = length(obj.offsetsDeg);
            obj.offsetIndex = 1;
            obj.absStepIndex = 1;
            obj.stepSign = 1;
            obj.saccadeTraceS = 0.250;                              % duratoin of saccade trace
            obj.trialDurS = max(1.0, 2 * obj.saccadeTraceS);
            obj.prestimDurS = min(obj.trialDurS / 4, 0.250);
            obj.taskState = TaskState.taskStarttrial;
            obj.dataState = DataState.dataIdle;
            obj.trialStartTimeS = 0;
            obj.samplesRead = 0;
%             obj.startStimS = 0;
            obj.stimTimeS = 0;
            obj.testMode = false;                                  % testMode is set in EOG, not here
            obj.voltage = 0;
            obj.doFilter = false;
            setSampleRateHz(obj, sampleRateHz);
        end

        %% clearAll
        function clearAll(obj)
            obj.blocksDone = 0;
            obj.calTrialsDone = 0;
            obj.numSummed = zeros(1, obj.numOffsets);
            obj.offsetsDone = zeros(1, obj.numOffsets);
            obj.posTrace = zeros(obj.trialSamples, 1);                      % trial EOG position trace
            obj.posSummed = zeros(obj.saccadeSamples, obj.numOffsets);  % summed position traces
            obj.posAvg = zeros(obj.saccadeSamples, obj.numOffsets);     % averaged position traces
            obj.rawData = zeros(obj.trialSamples, obj.numChannels);         % raw data
            obj.saccadeDurS = zeros(1, obj.numOffsets);                     % average saccade durations
            obj.velTrace = zeros(obj.trialSamples, 1);                      % trial EOG velocity trace
            obj.velSummed = zeros(obj.saccadeSamples, obj.numOffsets);  % summed position traces
            obj.velAvg = zeros(obj.saccadeSamples, obj.numOffsets);     % averaged position traces
        end
        
        %% setSampleRate
        function setSampleRateHz(obj, rateHz)
            obj.sampleRateHz = rateHz;
            obj.saccadeSamples = floor(obj.saccadeTraceS * obj.sampleRateHz);
            obj.trialSamples = floor(obj.trialDurS * obj.sampleRateHz);
            nyquistHz = obj.sampleRateHz / 2.0;
            % create a 60 Hz bandstop filter  for the sample rate
            obj.filter60Hz = design(fdesign.bandstop('Fp1,Fst1,Fst2,Fp2,Ap1,Ast,Ap2', ...
                55 / nyquistHz, 59 / nyquistHz, 61 / nyquistHz, 65 / nyquistHz, 1, 60, 1), 'butter');
            obj.filter60Hz.persistentmemory = false;    % no piecemeal filtering of trace
            obj.filter60Hz.states = 1;                      % uses scalar expansion.
            % create a low pass filter for filtering the velocity trace
            obj.filterLP = design(fdesign.lowpass('Fp,Fst,Ap,Ast', 30 / nyquistHz, 120 / nyquistHz, 0.1, 40), 'butter');
            obj.filterLP.persistentmemory = false;      % no piecemeal filtering of trace
            obj.filterLP.states = 1;                      % uses scalar expansion.
            clearAll(obj);                              % clear -- and also re-size buffers
        end
       
        %% set60HzFilter
        function set60HzFilter(obj, state)
            obj.doFilter = state;
        end
   end   
end

