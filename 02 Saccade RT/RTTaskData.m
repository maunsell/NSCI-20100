classdef RTTaskData < handle
    % RTTaskData
    %   Support for processing eye traces and detecting saccades in RT
    
    properties
        absStepIndex
        blocksDone;
        calTrialsDone;
        dataState;
        doFilter;
        filterLP;
        filter60Hz;
        numChannels;
        numTrialTypes;
        numSummed;
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
        stepDirection;
        stepSizeDeg;
        stimStartPixel;
        stimTimeS;
        trialDurS;
        trialSamples;
        taskState;
        testMode;
        trialStartTimeS;
        trialType;
        trialTypesDone;
        velTrace;
        velSummed;
        velAvg;
        voltage;
    end
    
    methods
        function obj = RTTaskData(numChannels, sampleRateHz)

             %% Object Initialization %%
             obj = obj@handle();                                    % object initialization

             %% Post Initialization %%
            c = RTConstants;
            obj.numChannels = numChannels;
            obj.numTrialTypes = c.kTrialTypes;
            obj.absStepIndex = 1;
            obj.saccadeTraceS = 0.250;                              % duratoin of saccade trace
            obj.trialDurS = max(1.0, 2 * obj.saccadeTraceS);
            obj.prestimDurS = min(obj.trialDurS / 4, 0.250);
            obj.taskState = RTTaskState.taskStarttrial;
            obj.dataState = RTDataState.dataIdle;
            obj.trialStartTimeS = 0;
            obj.samplesRead = 0;
%             obj.startStimS = 0;
            obj.stepDirection = 0;
            obj.stepSizeDeg = 5.0;
            obj.stimTimeS = 0;
            obj.testMode = false;                                  % testMode is set in RT, not here
            obj.voltage = 0;
            obj.doFilter = false;
            setSampleRateHz(obj, sampleRateHz);
        end

        %% clearAll
        function clearAll(obj)
            obj.blocksDone = 0;
            obj.calTrialsDone = 0;
            obj.numSummed = zeros(1, obj.numTrialTypes);
            obj.posTrace = zeros(obj.trialSamples, 1);                      % trial RT position trace
            obj.posSummed = zeros(obj.saccadeSamples, obj.numTrialTypes);   % summed position traces
            obj.posAvg = zeros(obj.saccadeSamples, obj.numTrialTypes);      % averaged position traces
            obj.rawData = zeros(obj.trialSamples, obj.numChannels);         % raw data
            obj.saccadeDurS = zeros(1, obj.numTrialTypes);                	% average saccade durations
            obj.trialTypesDone = zeros(1, obj.numTrialTypes);               % table of completed trials in block
            obj.velTrace = zeros(obj.trialSamples, 1);                      % trial RT velocity trace
            obj.velSummed = zeros(obj.saccadeSamples, obj.numTrialTypes);	% summed position traces
            obj.velAvg = zeros(obj.saccadeSamples, obj.numTrialTypes);      % averaged position traces
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
