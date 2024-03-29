classdef RTStimulus < handle
  % SaccadeRT stimuli controller
  properties
    finalStim
    gapStim
  end
  properties (Constant)
    marginPix = 10;
  end
  properties (GetAccess = private)
    currentOffsetIndex              % offset of for displayed image count (left edges of images, effectively)
    currentImageIndex
    hAxes
    hFig
    pixPerMM
    g
    images
    imagePosPix                     % locations for putting the images in the window
    numPos
    spotRadiusPix
    stepSizePix
    viewDistanceMM
    windRectPix
  end
  methods (Static)
  end
  methods
    function obj = RTStimulus(app)
      imtool close all;                               % close imtool figures from Image Processing Toolbox
      screenRectPix = get(0, 'MonitorPositions');   	% get the size of the primary screen
      if size(screenRectPix, 1) > 1
        screenRectPix = screenRectPix(1, :);
      end
      obj.currentImageIndex = 0;
      obj.currentOffsetIndex = 1;
      obj.finalStim = 0;
      obj.gapStim = 0;
      obj.images = cell(1, 4);
      obj.spotRadiusPix = 10;
      obj.viewDistanceMM = 0;
      windHeightPix = 60;
      dockPix = 75;
      windWidthPix = screenRectPix(3) - 2 * obj.marginPix;
      obj.windRectPix = [obj.marginPix, obj.marginPix + dockPix, windWidthPix, windHeightPix];
      obj.hFig = figure('Renderer', 'painters', 'Position', [obj.marginPix, obj.marginPix, ...
        windWidthPix, windHeightPix]);
      set(obj.hFig, 'menubar', 'none', 'toolbar', 'none', 'NumberTitle', 'off', 'resize', 'off');
      set(obj.hFig, 'color', [0.5, 0.5, 0.5]);
      set(obj.hFig, 'Name', 'NSCI 20100 Saccadic Reaction Time', 'NumberTitle', 'Off');
      axis off;
      obj.hAxes = axes('Parent', obj.hFig, 'units', 'pixels', 'visible', 'off');
      obj.pixPerMM = java.awt.Toolkit.getDefaultToolkit().getScreenResolution() / app.mmPerInch;
    end
        
    %% atStepRangeLimit -- Report whether a step is beyond the usable range
    function atLimit = atStepRangeLimit(obj, app)
      atLimit = (obj.currentOffsetIndex == 1 && obj.currentImageIndex == app.kLeftStim) || ...
        (obj.currentOffsetIndex == obj.numPos - 1 && obj.currentImageIndex == app.kRightStim);
    end
    
    %% currentOffsetDeg -- offset of the spot from screen center in degrees
    function offsetPix = currentOffsetPix(obj)
      offsetPix = obj.imagePosPix(obj.currentOffsetIndex);
    end
    
    %%
    function pix = degToPix(obj, app, deg)
      assert(obj.viewDistanceMM > 0, 'RTStimulus, degToPix: viewDistanceMM has not yet been set');
      pix = round(tan(deg / app.degPerRadian) * obj.viewDistanceMM * obj.pixPerMM);
    end
    
    %%
    function delete(obj)
      close(obj.hFig);
    end
    
    %%
    function drawCenterStimulus(obj, app)
      obj.currentOffsetIndex = ceil(obj.numPos / 2);
      drawImage(obj, app.kLeftStim);
    end
    
    %% drawImage -- draw the dot at the currently specified pixel offset
    function drawImage(obj, imageIndex)
      obj.hAxes.Position(1) = obj.imagePosPix(obj.currentOffsetIndex);
      imshow(obj.images{imageIndex}, [0.5, 0.5, 0.5; 1.0, 1.0, 1.0], 'parent', obj.hAxes);
      drawnow;
      obj.currentImageIndex = imageIndex;
    end
    
%     %% maxDeg -- maximum extent of the display in degrees (left edge to right edge)
%     function limitDeg = maxDeg(obj, app)
%       limitDeg = pixToDeg(obj, app, obj.viewDistanceMM);
%     end
    
    %% makeImages.  Each image has the height of a spot and the width of stepSizeDeg*2.  The spots, if they appear
    % are centered at 0.5 and 1.5 stepSizeDeg horizontally.  A set of four images is created, one for each possible
    % occupancy of the two spot locations
    
    function makeImages(obj, app)
      % make a circleImage
      diameterPix = floor(obj.spotRadiusPix) * 2;
      circlePix = 1:diameterPix;
      [imgCols, imgRows] = meshgrid(circlePix, circlePix);
      circlePixels = (imgRows - obj.spotRadiusPix).^2 + (imgCols - obj.spotRadiusPix).^2 <= obj.spotRadiusPix^2;
      [circleImg, ~] = gray2ind(circlePixels, 2);         % make an image from the circle matrix
      % make the background rectangle
      obj.stepSizePix  = degToPix(obj, app, app.stepSizeDeg);
      obj.hAxes.Position(2) = (obj.windRectPix(4) - diameterPix) / 2;
      obj.hAxes.Position(3) = obj.stepSizePix  * 2;
      obj.hAxes.Position(4) = diameterPix;
      
      imageSet = zeros(4, diameterPix, obj.stepSizePix  * 2, 'uint8');   % images will be the height of the circle
      leftCenterPix = floor(0.5 * obj.stepSizePix);               % image is 2 * stepSizePix  so circles are at 0.5 and 1.5 stepSizePix
      rightCenterPix = floor(1.5 * obj.stepSizePix);
      heightCenterPix = floor(diameterPix / 2);
      pRange = circlePix - obj.spotRadiusPix;
      for i = app.kBlankStim:app.kBothStim                           	% four images, one for each possible mix of dot/no-dot
        if i == app.kRightStim || i == app.kBothStim       	% needs a right hand dot
          imageSet(i, heightCenterPix + pRange, rightCenterPix + pRange) = circleImg(circlePix, circlePix);
        end
        if i == app.kLeftStim || i == app.kBothStim        	% needs a left hand dot
          imageSet(i, heightCenterPix + pRange, leftCenterPix + pRange) = circleImg(circlePix, circlePix);
        end
        obj.images{i} = squeeze(imageSet(i, :, :));     % save the image in a cell array
      end
      obj.images{app.kTestStim} = ones(obj.windRectPix(4), obj.stepSizePix, 'uint8'); % test image (white rect)
      % update the image position values.
      obj.numPos = floor(obj.windRectPix(3) / 2 / obj.stepSizePix);   % number of full steps left or right of center
      centerIndex = obj.numPos + 1;                          % index for the center position
      obj.numPos = obj.numPos * 2 + 1;                       % numPos must be odd
      obj.imagePosPix = zeros(1, obj.numPos);
      obj.imagePosPix(centerIndex) = floor(obj.windRectPix(3) / 2 - 0.5 * obj.stepSizePix);
      for p = 1:floor(obj.numPos / 2)
        obj.imagePosPix(centerIndex - p) = obj.imagePosPix(centerIndex - p + 1) - obj.stepSizePix;
        obj.imagePosPix(centerIndex + p) = obj.imagePosPix(centerIndex + p - 1) + obj.stepSizePix;
      end
    end
    
    %%
    function degrees = pixToDeg(obj, app, pix)
      assert(obj.viewDistanceMM > 0, 'RTStimulus, pixToDeg: viewDistanceMM has not yet been set');
      degrees = atan2(pix / obj.pixPerMM, obj.viewDistanceMM) * app.degPerRadian;
    end
    
    %% prepareImages -- set up the images that will be needed for the upcoming trial
    function prepareImages(obj, app)
      % first offset the image position if the current position won't accommodate the left or right step.
      % we don't need to do anything for a centering trial because that will be a different image location
      if app.trialType == app.kCenteringTrial
        drawImage(obj, obj.currentImageIndex);                    % draw for trial equivalence
        obj.gapStim = app.kLeftStim;
        obj.finalStim = obj.gapStim;
      else
        if app.stepSign == app.kLeft                              % going to step left
          if obj.currentImageIndex == app.kLeftStim
            obj.currentOffsetIndex = obj.currentOffsetIndex - 1;	% shift one position leftward
          end
          drawImage(obj, app.kRightStim);                  	      % draw same spot with new image
          obj.finalStim = app.kLeftStim;
        else
          if obj.currentImageIndex == app.kRightStim              % going to step right
            obj.currentOffsetIndex = obj.currentOffsetIndex + 1;  % shift one position leftward
          end
          drawImage(obj, app.kLeftStim);
          obj.finalStim = app.kRightStim;
        end
        % set up the gap stimuli
        switch app.trialType
          case app.kStepTrial
            obj.gapStim = obj.finalStim;
          case app.kGapTrial
            obj.gapStim = app.kBlankStim;
          case app.kOverlapTrial
            obj.gapStim = app.kBothStim;
        end
      end
    end
    
    %% prepareTimingImages -- set up the images that will are used for timing tests
    function prepareTimingImages(obj, app, trialType)
      obj.currentOffsetIndex = ceil(obj.numPos / 2);                      % always at center location
      drawImage(obj, app.kBlankStim);                             % blank anything there
      if trialType == app.kGapTrial
        obj.gapStim = app.kBlankStim;
      else
        obj.gapStim = app.kTestStim;
      end
      obj.finalStim = app.kTestStim;
      obj.hAxes.Position(2) = 0;
      obj.hAxes.Position(4) = obj.windRectPix(4);
    end
    
    %% positionWindow -- put the window back to where it belongs if it has been moved
    function positionWindow(obj)
      t = get(obj.hFig, 'Position');
      if t(1) ~= obj.marginPix || t(2) ~= obj.marginPix
        set(obj.hFig, 'Position', obj.windRectPix);
      end
    end
    
    %% setViewDistanceCM -- set the viewing distance, build the visual stimuli
    function setViewDistanceCM(obj, app, newValueCM)
      if obj.viewDistanceMM ~= newValueCM
        obj.viewDistanceMM = newValueCM * 10.0;
        makeImages(obj, app);                                       % make new spot images
        obj.currentOffsetIndex = ceil(obj.numPos / 2);            	% center position
        drawImage(obj, app.kLeftStim);                              % draw the center spot
      end
    end
  end
end
