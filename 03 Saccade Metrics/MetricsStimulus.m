classdef MetricsStimulus < handle
  % Contrast threshold stimuli controller
  properties
%     tag
  end
  properties (Constant)
    marginPix = 10;
    pixelDepth = 32;
  end
  properties (GetAccess = private)
    blankImage
    currentOffsetPix
    doStimDisplay
    hAxes                     % axes for drawing/erasing dots
    hFig
    pixPerMM
    spotImage
    spotRadiusPix
    viewDistanceMM
    window
    windRectPix
  end
  methods (Static)
  end
  methods
    function obj = MetricsStimulus(app, doStimDisplay)
      obj.doStimDisplay = doStimDisplay;
      if obj.doStimDisplay
        imtool close all;                               % close imtool figures from Image Processing Toolbox
        obj.spotRadiusPix = 10;
%         obj.stepSizeDeg = stepSizeDeg;
        dockPix = 75;
        windHeightPix = 60;
        screenRectPix = get(0, 'MonitorPositions');   	% get the size of the primary screen
        windWidthPix = screenRectPix(3) - 2 * obj.marginPix;
        obj.windRectPix = [obj.marginPix, obj.marginPix + dockPix, windWidthPix, windHeightPix];
        obj.hFig = figure('Renderer', 'painters', 'Position', obj.windRectPix);
        set(obj.hFig, 'menubar', 'none', 'toolbar', 'none', 'numberTitle', 'off', 'resize', 'off');
        set(obj.hFig, 'color', [0.5, 0.5, 0.5]);
        set(obj.hFig, 'name', 'NSCI 20100 Saccadic Metrics');
        obj.hFig.CloseRequestFcn = '';
        axis off;
        obj.hAxes = axes('Parent', obj.hFig, 'units', 'pixels', 'visible', 'off');
        obj.pixPerMM = java.awt.Toolkit.getDefaultToolkit().getScreenResolution() / MetricsConstants.mmPerInch;
        setViewDistanceCM(obj, app);                    % setting distance, make images, draw center stimulus
      else
        obj.windRectPix = [0, 0, 2000, 100];
        obj.pixPerMM = 3;
      end
    end
    
    %%
    function centerStimulus(obj)
%       drawImage(obj, obj.blankImage);
      cla(obj.hAxes);
      obj.currentOffsetPix = 0;
      drawImage(obj, obj.spotImage);
    end
    
    %%
    function pix = degToPix(obj, deg)
      assert(obj.viewDistanceMM > 0, 'Metrics degToPix: viewDistanceMM has not yet been set');
      pix = round(tan(deg / MetricsConstants.degPerRadian) * obj.viewDistanceMM * obj.pixPerMM);
    end   
    
    %% delete the window
    function delete(obj)
%       close(obj.hFig);
      delete(obj.hFig);
    end
       
    %% currentOffsetDeg -- offset of the spot from screen center in degrees
    function offsetDeg = currentOffsetDeg(obj)
      offsetMM = obj.currentOffsetPix / obj.pixPerMM;
      offsetDeg = atan2(offsetMM, obj.viewDistanceMM) * 57.2958;
    end
    
     %% drawImage -- draw the dot at the currently specified pixel offset
    function drawImage(obj, theImage)
      obj.hAxes.Position(1) = obj.currentOffsetPix + obj.marginPix + obj.windRectPix(3) / 2.0 - obj.spotRadiusPix;
      imshow(theImage, [0.5, 0.5, 0.5; 1.0, 1.0, 1.0], 'parent', obj.hAxes);
      drawnow;
    end
    
    %% maxDeg -- maximum extent of the display in degrees (left edge to right edge)
    function limitDeg = maxDeg(obj)
      limitDeg = atan2((obj.windRectPix(3) / 2.0 - obj.marginPix) / obj.pixPerMM, obj.viewDistanceMM) * 57.2958;
    end
    
    %% maxViewDistance -- the largest viewing distance that keeps all the stimuli on the screen
    function limitDistCM = maxViewDistanceCM(obj, maxDeg)
      limitDistCM = (obj.windRectPix(3) / 2.0 - obj.marginPix) / obj.pixPerMM / tan(maxDeg / 57.2958) / 10.0;
    end
    
   %% makeImages.  Each image has the height and width of a spot
    function makeImages(obj)
      % make a circleImage
      diameterPix = floor(obj.spotRadiusPix) * 2;
      circlePix = 1:diameterPix;
      [imgCols, imgRows] = meshgrid(circlePix);
      circlePixels = (imgRows - obj.spotRadiusPix).^2 + (imgCols - obj.spotRadiusPix).^2 <= obj.spotRadiusPix^2;
      [obj.spotImage, ~] = gray2ind(circlePixels, 2);         % make an image from the circle matrix
      [obj.blankImage, ~] = gray2ind(zeros(obj.spotRadiusPix, obj.spotRadiusPix), 1);
      % make the background rectangle
      obj.hAxes.Position(2) = (obj.windRectPix(4) - diameterPix) / 2;
      obj.hAxes.Position(3) = diameterPix;
      obj.hAxes.Position(4) = diameterPix;
    end
        
    %% stepOutOfRange -- Report whether a step would move the target offscreen
    function outOfRange = stepOutOfRange(obj, offsetDeg)
      outOfRange = abs(currentOffsetDeg(obj) + offsetDeg) > maxDeg(obj);
    end
    
    %% positionWindow -- put the window back to where it belongs if it has been moved
    function positionWindow(obj)
      t = get(obj.hFig, 'Position');
      if t(1) ~= obj.windRectPix(1) || t(2) ~= obj.windRectPix(2)
        set(obj.hFig, 'Position', obj.windRectPix);
      end
    end
    
    %% setViewDistanceCM -- set the viewing distance
    function setViewDistanceCM(obj, app)
      newViewMM = str2double(app.viewDistanceText.Value) * 10.0;
      if isempty(obj.viewDistanceMM) || obj.viewDistanceMM ~= newViewMM
        obj.viewDistanceMM = newViewMM;
        makeImages(obj);                                              % make new spot images
        centerStimulus(obj);
      end
    end
    
    %% stepStimulus -- Step the stimulus
    function stepStimulus(obj, offsetDeg)
      drawImage(obj, obj.blankImage);                               % erase the current image
      newOffsetDeg = currentOffsetDeg(obj) + offsetDeg;
      newOffsetMM = obj.viewDistanceMM * tan(newOffsetDeg / 57.2958);
      obj.currentOffsetPix = newOffsetMM * obj.pixPerMM;
      drawImage(obj, obj.spotImage);
    end
  end
end
