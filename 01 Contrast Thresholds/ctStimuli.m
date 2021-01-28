classdef ctStimuli
% Contrast threshold stimuli controller
properties (GetAccess = private)
  colorMap
  frameDurS
  fixSpotImage
  gaborBaseImages
  gaborTestImages
  hFig
  hFixSpotAxes
  hLeftGaborAxes
  hRightGaborAxes
  pixPerMM
  screenNumber
  window
  windowRectPix
end
properties (Constant)
  degPerRadian = 57.2958;
  fixSpotRadiusPix = 4;
  gaborFreqPix = 35;
  gaborOriDeg = 0;
  gaborPhaseDeg = 90.0;
  gaborRadiusPix = 100;
  gaborSigmaPix = 20;
  gaborThetaDeg = 0.0;
  mmPerInch = 25.40;
  windMarginPix = 10;
  windSidePix = 600;
end
methods
  %% ctStimuli()
  function obj = ctStimuli(app)
    imtool close all;                               % close imtool figures from Image Processing Toolbox
%     screenRectPix = get(0, 'MonitorPositions');   	% get the size of the primary screen
%     if size(screenRectPix, 1) > 1
%       screenRectPix = screenRectPix(1, :);
%     end
%     if screenRectPix(3) > 3000                  % Retina display
%       screenRectPix(3) = screenRectPix(3) / 2.0;
%     end
    obj.windowRectPix = [0, 0, obj.windSidePix, obj.windSidePix];
    obj.hFig = figure('renderer', 'painters', 'position', obj.windowRectPix, 'visible', 'off');
    obj.hFig.CloseRequestFcn = '';                % prevent user from closing the stimulus window
    movegui(obj.hFig, [-obj.windMarginPix, -obj.windMarginPix]);
    set(obj.hFig, 'menubar', 'none', 'toolbar', 'none', 'numberTitle', 'off', 'resize', 'off');
    set(obj.hFig, 'color', [0.5, 0.5, 0.5], 'name', 'NSCI 20100 Contrast Thresholds');
    axis off;
    obj.pixPerMM = java.awt.Toolkit.getDefaultToolkit().getScreenResolution() / obj.mmPerInch;
    obj.frameDurS = 0.016666;  % System() call to xrandr?
    clearScreen(obj);
    set(obj.hFig, 'visible', 'on');
    
    % make the fixSpot image and axes
    fixDiameterPix = floor(obj.fixSpotRadiusPix) * 2 + 1;
    circlePix = 1:fixDiameterPix;
    [imgCols, imgRows] = meshgrid(circlePix);
    circlePixels = (imgRows - 1 - obj.fixSpotRadiusPix).^2 + (imgCols - 1 - obj.fixSpotRadiusPix).^2 <= obj.fixSpotRadiusPix^2;
    [obj.fixSpotImage, ~] = gray2ind(circlePixels, 2);         % make an image from the circle matrix
    obj.hFixSpotAxes = axes('parent', obj.hFig, 'units', 'pixels', 'visible', 'off');
    obj.hFixSpotAxes.Position = [  obj.windowRectPix(1) + obj.windowRectPix(3) / 2 - obj.fixSpotRadiusPix, ...
                                    obj.windowRectPix(2) + obj.windowRectPix(4) / 2 - obj.fixSpotRadiusPix, ...
                                    fixDiameterPix, fixDiameterPix];   
    % make the left Gabor image and axes
    gaborDiameterPix = floor(obj.gaborRadiusPix) * 2 + 1;
%     [imgCols, imgRows] = meshgrid(1:gaborDiameterPix);

    obj.gaborBaseImages = cell(1, app.numBases);
    obj.gaborTestImages = cell(app.numBases, app.numIncrements);
    for g = 1:app.numBases
      obj.gaborBaseImages{g} = makeGabor(obj, app.baseContrasts(g));
      for i = 1:app.numIncrements
        obj.gaborTestImages{g, i} = makeGabor(obj, app.testContrasts(g, i));
      end
    end
    obj.hLeftGaborAxes = axes('parent', obj.hFig, 'units', 'pixels', 'visible', 'off');
    obj.hLeftGaborAxes.Position = [ obj.windowRectPix(1) + obj.windowRectPix(3) / 2 - obj.gaborRadiusPix - 150, ...
                                    obj.windowRectPix(2) + obj.windowRectPix(4) / 2 - obj.gaborRadiusPix, ...
                                    gaborDiameterPix, gaborDiameterPix];    

    % make the right Gabor image and axes
    obj.hRightGaborAxes = axes('parent', obj.hFig, 'units', 'pixels', 'visible', 'off');
    obj.hRightGaborAxes.Position = [obj.windowRectPix(1) + obj.windowRectPix(3) / 2 - obj.gaborRadiusPix + 150, ...
                                    obj.windowRectPix(2) + obj.windowRectPix(4) / 2 - obj.gaborRadiusPix, ...
                                    gaborDiameterPix, gaborDiameterPix];    
     obj.colorMap = zeros(256, 3, 'uint8');
     for c = 0:255
       obj.colorMap(c + 1, :) = [c, c, c];
     end
  end
   
   %%
   function clearScreen(obj)
     cla(obj.hFixSpotAxes);
     cla(obj.hLeftGaborAxes);
     cla(obj.hRightGaborAxes);
   end
   
   %%
   function delete(obj)
     close(obj.hFig);
   end
   
   %% drawFixSpot
   function drawFixSpot(obj, color)
     imshow(obj.fixSpotImage, [0.5, 0.5, 0.5; color], 'parent', obj.hFixSpotAxes);
     drawnow;
   end
   
   %% drawStimuli
   function drawStimuli(obj, baseIndex, leftIndex, rightIndex)
     if leftIndex == 0
       leftGabor = obj.gaborBaseImages{baseIndex};
     else
       leftGabor = obj.gaborTestImages{baseIndex, leftIndex};
     end
     if rightIndex == 0
       rightGabor = obj.gaborBaseImages{baseIndex};
     else
       rightGabor = obj.gaborTestImages{baseIndex, rightIndex};
     end
     imshow(leftGabor, obj.colorMap, 'parent', obj.hLeftGaborAxes);
     imshow(rightGabor, obj.colorMap, 'parent', obj.hRightGaborAxes);
     drawnow;
   end
      
   %% testStimuli -- make sure all the contrast settings are distinct from each other. If they
   % are not, the full list of possible contrasts will be dumped so
   % they can be used to make adjustments (by hand) to the multipliers
%    function testStimuli(obj, app)
%      clean = true;
%      propertiesMat = [0, obj.gaborFreqPix, obj.gaborSigmaPix, obj.gaborContrast, 1.0, 0, 0, 0];
%      obj.gaborTex = CreateProceduralGabor(obj.window, obj.gaborDimPix, obj.gaborDimPix, [], ...
%        [0.5 0.5 0.5 0.0], 1, 0.5);
%      for bIndex = 1:app.numBases
%        propertiesMat(:, 4) = [app.baseContrasts(bIndex)];
%        [lastMin, lastMax] = sampleImage(obj, app, propertiesMat);
%        for cIndex = 1:app.numIncrements
%          propertiesMat(4) = [app.testContrasts(bIndex, cIndex)];
%          [thisMin, thisMax] = sampleImage(obj, app, propertiesMat);
%          if (thisMin == lastMin && thisMax == lastMax)
%            fprintf('Screen settings for %d %d (contrast %.1f%%) same as previous value\n', ...
%              bIndex, cIndex, propertiesMat(4) * 100.0);
%            clean = false;
%          end
%          lastMin = thisMin;
%          lastMax = thisMax;
%        end
%      end
%      if ~clean
%        for contrast = 0.00:0.001:1.0
%          propertiesMat(:, 4) = contrast;
%          [thisMin, thisMax] = sampleImage(obj, app, propertiesMat);
%        end
%      end
%      clearScreen(obj);
%    end
   
  %% makeGabor
  function theGabor = makeGabor(obj, contrast)

    sinTheta = sin(obj.gaborThetaDeg / obj.degPerRadian);
    cosTheta = cos(obj.gaborThetaDeg / obj.degPerRadian);
    diameterPix = floor(obj.gaborRadiusPix) * 2 + 1;
    [x, y] = meshgrid(1:diameterPix, 1:diameterPix);
    thetaX = (x - obj.gaborRadiusPix) * cosTheta + (y - obj.gaborRadiusPix) * sinTheta;
    thetaY = -(x - obj.gaborRadiusPix) * sinTheta + (y - obj.gaborRadiusPix) * cosTheta;
    % We need a baseline incrementally greater than 0.5, because the gray2ind() function places the boundary
    % between 127 and 128 precisely at 0.5. Incrementally greater settles to 128, which is background gray
    G = (exp(-0.5 * (thetaX.^2 / obj.gaborSigmaPix^2 + thetaY.^2 / obj.gaborSigmaPix^2)) .* ...
        cos(2.0 * pi * thetaX / obj.gaborFreqPix + obj.gaborPhaseDeg / obj.degPerRadian)) / 2.0 * contrast + 0.5001;
    theGabor = gray2ind(G, 256);                    % make an image from the Gabor
  end
  
   %% sampleImage -- draw a gabor and get the min and max pixels
   function [minValue, maxValue] = sampleImage(obj, app, propertiesMat)
     drawGabors(obj, app, propertiesMat);
     %             Screen('Flip', obj.window);
     %             img = Screen('GetImage', obj.window);
     minValue = min(min(min(img)));
     maxValue = max(max(max(img)));
     fprintf('Screen Test: contrast %.1f%%, min %d, %d, delta %d\n',...
       propertiesMat(4) * 100.0, minValue, maxValue, maxValue - minValue);
   end
 end
end
            