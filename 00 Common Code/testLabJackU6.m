% testLabJackU6 A class to stand in for LabJackU6 when no hardware is
% available
%
% lbj = testLabJackU6 constructs an object that reponds to the same calls
% as LabJackU6. Only a minimal set of methods are recognized. Virtually all
% do nothing
%

classdef testLabJackU6 < handle

  properties
    numChannels;
    ResolutionADC;
    SampleRateHz;   %sampling rate is needed by internal functions
    verbose;
  end
  % Public Methods
  methods

    %% Constructor
    % return instance of labJackU6 class.
    function obj = testLabJackU6(varargin)
      if nargin > 0
        fprintf(1,'labJackU6: Initial property setting is not supported. (n=%d)\n',nargin);
      end
      fprintf('testLabJackU6/open: Operating without device in test mode\n');
    end

    %% open
    % Open connection to the LabJack device
    function open(obj, ~)
      obj.numChannels = 1;
      obj.verbose = 0;
    end

    %% Close
    % Closes the connection to a LabJack USB device.
    function close(~)
    end

    %% addChannel
    % adds a channel to the list of active channels
    function addChannel(~, ~, ~, ~)
    end

    %% removeChannel
    % removes a channel from the list of active channels
    function removeChannel(~, ~)
    end

    %% streamConfigure
    % send the streamConfigure command, which prepares LJ for streaming analog data
    function errorCode = streamConfigure(~)
      errorCode = 0;
    end

    %% startStream
    % send the command to initiate data streaming
    function errorCode = startStream(~)
      errorCode = 0;
    end

    %% stopStream
    % send the command to terminate data streaming
    function errorCode = stopStream(~)
      errorCode = 0;
    end

    %% getStreamData
    % get streaming data
    function [data, errorCode] = getStreamData(~)
      data = [];
      errorCode = 0;
    end

    %% DAC analogOut
    % set an output voltage for one of the two DAC channels
    function analogOut(~,~,~)
    end

    %% AIN analogIn
    % reads a single AIN value
    % (manual 5.2.5)
    function data = analogIn(~,~,~,~,~)
      data = [];
    end

    %% AIN analogScan
    % returns readings from all the channels in the Channel List
    %  data returned as a row vector (one column per channel, one row per scan)
    function data = analogScan(~,~)
      data = [];
    end
  end
  % % % % % % %
  % Private Methods
  methods ( Access = private )
    %% delete
    % Destructor
    function delete(obj)
      close(obj);
    end
  end
end