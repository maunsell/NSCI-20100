classdef SRData < handle
    % SRTaskData
    % Support for global data for StretchReceptor
    
    properties
        contMSPerDiv;               % ms/division in continuous plot
        contPlotRescale;            % flag for rescale needed on continuous plot
        contSamples;                % number of samples in the continuous plot
        contTimeDivs;               % number of time divisions in continuous plot
        fH;                         % pointer to GUI handles
        filter;                     % pointer to filter in use
        filters;                    % pointer to all the filters we have made
        filteredTrace;              % filtered version of samples
        inSpike;                    % flag showing that spike finding routine is in middle of a spike
        lastSpikeIndex;             % index of last triggered spike
        maxContSamples;             % allocate large buffers to avoid auto-lengthening.
        rawData;                    % most recent raw snippet of sampled data
        rawTrace;                   % raw version of samples
        sampleRateHz;               % sampling rate
        samplesRead;                % number of samples read in the continuous trace
        singleTrace;                % flag for displaying a single continous trace
        spikeIndices;               % indices for unplotted spikes in continuous trace
        thresholdV;                 % used by signals and plots
        testMode;                   % flag for testing mode
        vDivs;                      % number of voltage (y) divisions
        vPerDiv;                    % volts per division
    end
    
    methods
        %% SRData -- instantiate and initialize
       function obj = SRData(handles)
             % Object Initialization %%
             obj = obj@handle();                                    % object initialization

             % Post Initialization %%
            obj.fH = handles;
            obj.sampleRateHz = handles.lbj.SampleRateHz;
            contents = get(handles.contMSPerDivButton, 'string');
            obj.contMSPerDiv = str2double(contents{get(handles.contMSPerDivButton, 'Value')});
            obj.contTimeDivs = 20;
            contents = cellstr(get(handles.contMSPerDivButton,'String'));
            maxMSPerDiv = str2double(contents{end});
            obj.maxContSamples = obj.contTimeDivs * maxMSPerDiv / 1000.0 * obj.sampleRateHz;
            obj.vDivs = 6;
            obj.contPlotRescale = false;
            % make filters, usings the values in the filter menu
            filterStrings = get(handles.filterMenu, 'string');
            obj.filters = cell(length(filterStrings), 1);
            for f = 1:length(filterStrings)
                cutOffHz = str2double(filterStrings{f});
                filter = design(fdesign.highpass('Fst,Fp,Ast,Ap', 0.5 * cutOffHz / obj.sampleRateHz, ...
                    2 * cutOffHz / obj.sampleRateHz, 60, 1), 'butter');
                filter.persistentmemory = true;         % piecemeal filtering of trace
                filter.states = 1;                      % uses scalar expansion.
                obj.filters{f} = filter;
            end
            selectFilter(obj);
            obj.singleTrace = false;
            obj.inSpike = false;
            obj.testMode = false;                                           % testMode is set in SR, not here
            obj.thresholdV = 1.0;
            obj.vPerDiv = 1.0;
            obj.rawData = zeros(obj.maxContSamples, 1);                    % raw data
            obj.rawTrace = zeros(obj.maxContSamples, 1);                   % continuous voltage trace
            obj.filteredTrace = zeros(obj.maxContSamples, 1);              % filtered voltage trace
            setLimits(obj, handles)
        end

        %% clearAll
        function clearAll(obj)
            obj.spikeIndices = [];
            obj.inSpike = false;
            obj.samplesRead = 0;
            obj.lastSpikeIndex = 2 * obj.maxContSamples;                    % flag start with invalid index
        end
        
        %% selectFilter -- used when filter selection changes
        function selectFilter(obj)
            obj.filter = obj.filters{get(obj.fH.filterMenu, 'value')};
        end

        %% setLimits -- used when plot scaling changes
        function setLimits(obj, handles)
            obj.samplesRead = 0;
            obj.spikeIndices = [];
            obj.contSamples = obj.contMSPerDiv / 1000.0 * obj.sampleRateHz * obj.contTimeDivs;
            vLimit = obj.vPerDiv * obj.vDivs / 2.0;
            threshV = get(handles.thresholdSlider, 'value');
            threshV = max(-vLimit * 0.9, min(vLimit * 0.9, threshV));
            set(handles.thresholdSlider, 'value', threshV);
            obj.thresholdV = threshV;
            set(handles.thresholdSlider, 'max', vLimit);
            set(handles.thresholdSlider, 'min', -vLimit);
        end
    end
end

