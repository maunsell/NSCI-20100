classdef ctStimuli
  % Contrast threshold stimuli controller
  properties (GetAccess = private)
    allRects
    blackColor
    frameDurS
    gaborTex
    grayColor
    hAxes
    hFig
    pixPerMM
    screenNumber
%     topPriorityLevel
    whiteColor
    window
    windowRectPix
    xCenterPix
    xPosPix
    yCenterPix
    yPosPix
  end
  properties (Constant)
    pixelDepth = 32;
    numGabors = 2;
    gaborDimPix = 300;
    gaborSigma = 300 / 7;
    gaborFreqPix = 4 / 300;
    gaborShiftPix = 240;
    %         gaborDimPix = 500;
    %         gaborSigma = 500 / 7;
    %         gaborFreqPix = 3 / 500;
    %         gaborShiftPix = 400;
    gaborOriDeg = 0;
    gaborContrast = 0.5;
    gaborPhaseDeg = 0;
    gaborCycles = 4;
  end
methods
  %% ctStimuli()
  function obj = ctStimuli()
    imtool close all;                               % close imtool figures from Image Processing Toolbox
    screenRectPix = get(0, 'MonitorPositions');   	% get the size of the primary screen
    if size(screenRectPix, 1) > 1
      screenRectPix = screenRectPix(1, :);
    end
    if screenRectPix(3) > 3000                  % Retina display
      screenRectPix(3) = screenRectPix(3) / 2.0;
    end
    %      windHeightPix = 60;
    windWidthPix = 600;
    windHeightPix = 600;
    windMarginPix = 10;
%     obj.windowRectPix = [screenRectPix(3) - windMarginPix - windWidthPix, screenRectPix(4) - windMarginPix - windHeightPix,...
%         windWidthPix, windHeightPix];
    obj.windowRectPix = [0, 0, windWidthPix, windHeightPix];
    %      dockPix = 75;
    %      windWidthPix = screenRectPix(3) - 2 * obj.marginPix;
    %      obj.windRectPix = [obj.marginPix, obj.marginPix + dockPix, windWidthPix, windHeightPix];
    obj.hFig = figure('renderer', 'painters', 'position', obj.windowRectPix, 'visible', 'off');
    movegui(obj.hFig, [-windMarginPix, -windMarginPix]);
    set(obj.hFig, 'menubar', 'none', 'toolbar', 'none', 'numberTitle', 'off', 'resize', 'off');
    set(obj.hFig, 'color', [0.5, 0.5, 0.5], 'name', 'NSCI 20100 Contrast Thresholds');
    axis off;
    obj.hAxes = axes('parent', obj.hFig, 'units', 'pixels', 'visible', 'off');
    obj.pixPerMM = java.awt.Toolkit.getDefaultToolkit().getScreenResolution() / RTConstants.mmPerInch;
    clearScreen(obj);
    set(obj.hFig, 'visible', 'on');
    
    %             obj.topPriorityLevel = MaxPriority(obj.window);
    %             [obj.xCenterPix, obj.yCenterPix] = RectCenter(obj.windowRectPix);
    %             obj.frameDurS = Screen('GetFlipInterval', obj.window);
    %      obj.xPosPix = [obj.xCenterPix - obj.gaborShiftPix obj.xCenterPix + obj.gaborShiftPix];
    %      obj.yPosPix = [obj.yCenterPix obj.yCenterPix];
    %      baseRect = [0 0 obj.gaborDimPix obj.gaborDimPix];
    %      obj.allRects = nan(4, obj.numGabors);
    %      for i = 1:obj.numGabors
    %        obj.allRects(:, i) = CenterRectOnPointd(baseRect, obj.xPosPix(i), obj.yPosPix(i));
    %      end
    %      obj.gaborTex = CreateProceduralGabor(obj.window, obj.gaborDimPix, obj.gaborDimPix, [], ...
    %        [0.5 0.5 0.5 0.0], 1, 0.5);
    %             Screen('Preference','SuppressAllWarnings',oldEnableFlag);
    
    
    obj.frameDurS = 0.016666;
    
    
  end
   
   %    %% cleanup
   %    function cleanup(obj)
   %      close(obj.hFig);
   %    end
   %%
   function clearScreen(obj)
     cla(obj.hAxes);
   end
 
   %%
   function delete(obj)
      close(obj.hFig);
   end
   
   %% doFixSpot
   function doFixSpot(obj, color)
   drawFixSpot(obj, color);
   %             Screen('Flip', obj.window);
   end
   
   %% doStimulus
   function doStimulus(obj, stimParams)
%      Priority(obj.topPriorityLevel);
     propertiesMat = repmat([NaN, obj.gaborFreqPix, obj.gaborSigma, obj.gaborContrast, 1.0, 0, 0, 0], ...
       obj.numGabors, 1);
     propertiesMat(:, 1) = [0; 180];
     propertiesMat(:, 4) = [stimParams.leftContrast; stimParams.rightContrast];
     stimFrames = stimParams.stimDurS / obj.frameDurS;
     drawGabors(obj, propertiesMat);
     drawFixSpot(obj, obj.whiteColor);
     %             vbl = Screen('Flip', obj.window);
     for frame = 1:stimFrames - 1
       drawGabors(obj, propertiesMat);
       drawFixSpot(obj, obj.whiteColor);
       %                 vbl = Screen('Flip', obj.window, vbl + 0.5 * obj.frameDurS);
     end
     %             Priority(0);
   end
   
   % drawFixSpot
   function drawFixSpot(obj, color)
     %             Screen('BlendFunction', obj.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
     %             Screen('DrawDots', obj.window, [obj.xCenterPix; obj.yCenterPix], 10, color, [], 2);
   end
   
   %% drawGabors
   function drawGabors(obj, propertiesMat)
     %         	Screen('BlendFunction', obj.window, 'GL_ONE', 'GL_ZERO');
     %             Screen('DrawTextures', obj.window, obj.gaborTex, [], obj.allRects, obj.gaborOriDeg, [], [], [], [],...
     %                     kPsychDontDoRotation, propertiesMat');
   end
   
   %% testStimuli -- make sure all the contrast settings are distinct from each other. If they
   % are not, the full list of possible contrasts will be dumped so
   % they can be used to make adjustments (by hand) to the multipliers
   function testStimuli(obj, handles)
     clean = true;
     propertiesMat = [0, obj.gaborFreqPix, obj.gaborSigma, obj.gaborContrast, 1.0, 0, 0, 0];
     obj.gaborTex = CreateProceduralGabor(obj.window, obj.gaborDimPix, obj.gaborDimPix, [], ...
       [0.5 0.5 0.5 0.0], 1, 0.5);
     for bIndex = 1:handles.data.numBases
       propertiesMat(:, 4) = [handles.data.baseContrasts(bIndex)];
       [lastMin, lastMax] = sampleImage(obj, propertiesMat);
       for cIndex = 1:handles.data.numIncrements
         propertiesMat(4) = [handles.data.testContrasts(bIndex, cIndex)];
         [thisMin, thisMax] = sampleImage(obj, propertiesMat);
         if (thisMin == lastMin && thisMax == lastMax)
           fprintf('Screen settings for %d %d (contrast %.1f%%) same as previous value\n', ...
             bIndex, cIndex, propertiesMat(4) * 100.0);
           clean = false;
         end
         lastMin = thisMin;
         lastMax = thisMax;
       end
     end
     if ~clean
       for contrast = 0.00:0.001:1.0
         propertiesMat(:, 4) = contrast;
         [thisMin, thisMax] = sampleImage(obj, propertiesMat);
       end
     end
     clearScreen(obj);
   end
   
   %% sampleImage -- draw a gabor and get the min and max pixels
   function [minValue, maxValue] = sampleImage(obj, propertiesMat)
     drawGabors(obj, propertiesMat);
     %             Screen('Flip', obj.window);
     %             img = Screen('GetImage', obj.window);
     minValue = min(min(min(img)));
     maxValue = max(max(max(img)));
     fprintf('Screen Test: contrast %.1f%%, min %d, %d, delta %d\n',...
       propertiesMat(4) * 100.0, minValue, maxValue, maxValue - minValue);
   end
 end
end
            