classdef RTStimulus < handle
    % Contrast threshold stimuli controller
    % This is the first stimulus for which we've cut loose from Psychtoolbox
    properties
%         currentOffsetPix
      	finalStim
        gapStim
        tag
    end
    properties (GetAccess = private)
        currentOffsetIndex              % offset of for displayed image count (left edges of images, effectively)
        currentImageIndex
        degPerRadian
        frameDurS
        hAxes
        grayColor
        pixPerMM
        g
        images
        imagePosPix                     % locations for putting the images in the window
        nextImageIndex
        numPos
        spotRadiusPix
        stepSizeDeg
        stepSizePix
        viewDistanceMM
        whiteColor
        windRectPix
        xCenterPix
        yCenterPix
    end
    properties (Constant)
%         marginPix = 50;
%         pixelDepth = 32;
    end
    methods (Static)
    end
    methods
        function obj = RTStimulus(stepDeg)
            %Screen('CloseAll');
            imtool close all;                               % close imtool figures from Image Processing Toolbox
%             PsychDefaultSetup(2);
            screenRectPix = get(0, 'MonitorPositions');        % get the size of the primary screen
%             obj.screenNumber = max(Screen('Screens'));
%             obj.whiteColor = WhiteIndex(obj.screenNumber);
%             obj.grayColor = obj.whiteColor / 2;
            obj.currentImageIndex = 0;
%             obj.currentOffsetPix = 0;
            obj.currentOffsetIndex = 1;
            obj.degPerRadian = 57.2958;
%             screenRectPix = Screen('Resolution', obj.screenNumber);
            obj.finalStim = 0;
            obj.gapStim = 0;
            obj.images = cell(1, 4);
            obj.nextImageIndex = 0;
            obj.spotRadiusPix = 10;
            obj.stepSizeDeg = stepDeg;
            obj.viewDistanceMM = 0;
            windHeightPix = 60;
            marginPix = 10;
            windWidthPix = screenRectPix(3) - 2 * marginPix;
            obj.windRectPix = [marginPix, marginPix, windWidthPix, windHeightPix];
%             obj.windRectPix = [obj.marginPix, screenRectPix.height - 200, ...
%                                             screenRectPix.width - obj.marginPix, screenRectPix.height - 100];
            hFig = figure('Renderer', 'painters', 'Position', [marginPix, marginPix, windWidthPix, windHeightPix]);
            set(hFig, 'menubar', 'none', 'toolbar', 'none', 'NumberTitle', 'off', 'resize', 'off');
            set(hFig, 'color', [0.5, 0.5, 0.5]);
            set(hFig, 'Name', 'NSCI 20100 Saccadic Reaction Time', 'NumberTitle', 'Off');
            axis off;
            obj.hAxes = axes('Parent', hFig, 'units', 'pixels', 'visible', 'off');

%             [widthMM, ~] = Screen('DisplaySize', obj.screenNumber);
%             obj.pixPerMM = obj.windRectPix(3) / widthMM;
            mmPerInch = 25.40;
            obj.pixPerMM = java.awt.Toolkit.getDefaultToolkit().getScreenResolution() / mmPerInch;
%             [obj.window, obj.windRectPix] = PsychImaging('OpenWindow', obj.screenNumber, obj.grayColor, ...
%                 obj.windRectPix, obj.pixelDepth, 2, [], [], kPsychNeed32BPCFloat);
%             obj.topPriorityLevel = MaxPriority(obj.window);
%             [obj.xCenterPix, obj.yCenterPix] = RectCenter(obj.windRectPix);
%             obj.frameDurS = Screen('GetFlipInterval', obj.window);
%             drawDot(obj);
        end
        
       	%% atStepRangeLimit -- Report whether a step is beyond the usable range       
        function atLimit = atStepRangeLimit(obj)
            atLimit = obj.currentOffsetIndex == 1 || obj.currentOffsetIndex == length(obj.imagePosPix);
        end
  
        %%
        function cleanup(~)
            sca;
        end
        
        %%
        function clearScreen(~)
%             Screen('Flip', obj.window);
        end
        
        %% currentOffsetDeg -- offset of the spot from screen center in degrees
        function offsetPix = currentOffsetPix(obj)
            offsetPix = obj.imagePosPix(obj.currentOffsetIndex);
        end

        %%
        function pix = degToPix(obj, deg)
            assert(obj.viewDistanceMM > 0, 'RTStimulus, degToPix: viewDistanceMM has not yet been set');
            pix = round(tan(deg / obj.degPerRadian) * obj.viewDistanceMM * obj.pixPerMM);
        end
        
        %%
        function drawCenterStimulus(obj)
            c = RTConstants;
            obj.currentOffsetIndex = ceil(obj.numPos / 2);
            drawImage(obj, c.kLeftStim);
        end
        
        %% drawImage -- draw the dot at the currently specified pixel offset
        function drawImage(obj, imageIndex)
            obj.hAxes.Position(1) = obj.imagePosPix(obj.currentOffsetIndex);
            fprintf(' hAxes position %d %d %d %d\n', ...
                round(obj.hAxes.Position(1)), round(obj.hAxes.Position(2)), ...
                round(obj.hAxes.Position(3)), round(obj.hAxes.Position(4)));
            imshow(obj.images{imageIndex}, [0.5, 0.5, 0.5; 1.0, 1.0, 1.0], 'parent', obj.hAxes);
            drawnow;
            fprintf('drawing image %d at currentIndex %d, x = %d\n', imageIndex, obj.currentOffsetIndex, obj.imagePosPix(obj.currentOffsetIndex))
            obj.currentImageIndex = imageIndex;
       end
        
        %% maxDeg -- maximum extent of the display in degrees (left edge to right edge)
        function limitDeg = maxDeg(obj)
            limitDeg = pixToDeg(obj, obj.viewDistanceMM);
        end

        %% limitDistCM -- return the maximum allowed viewing distance
        function limitDistCM = maxViewDistanceCM(~)
            limitDistCM = 100;
        end
        
        %% makeSpotImages.  Each image has the height of a spot and the width of stepSizeDeg*2.  The spots, if they appear
        % are centered at 0.5 and 1.5 stepSizeDeg horizontally.  A set of four images is created, one for each possible
        % occupancy of the two spot locations

        function makeSpotImages(obj)
            % make a circleImage
            c = RTConstants;
            diameterPix = floor(obj.spotRadiusPix) * 2;
            circlePix = 1:diameterPix;
            [imgCols, imgRows] = meshgrid(circlePix, circlePix);
            circlePixels = (imgRows - obj.spotRadiusPix).^2 + (imgCols - obj.spotRadiusPix).^2 <= obj.spotRadiusPix^2;
            [circleImg, ~] = gray2ind(circlePixels, 2);         % make an image from the circle matrix
            % make the background rectangle
            obj.stepSizePix  = degToPix(obj, obj.stepSizeDeg);
            obj.hAxes.Position(2) = (obj.windRectPix(4) - diameterPix) / 2;
            obj.hAxes.Position(3) = obj.stepSizePix  * 2;
            obj.hAxes.Position(4) = diameterPix;

            imageSet = zeros(4, diameterPix, obj.stepSizePix  * 2, 'uint8');   % images will be the height of the circle
            leftCenterPix = floor(0.5 * obj.stepSizePix);               % image is 2 * stepSizePix  so circles are at 0.5 and 1.5 stepSizePix 
            rightCenterPix = floor(1.5 * obj.stepSizePix);
            heightCenterPix = floor(diameterPix / 2);
            pRange = circlePix - obj.spotRadiusPix;
            for i = 1:c.kStimTypes                           	% four images, one for each possible mix of dot/no-dot
                if i == c.kRightStim || i == c.kBothStim       	% needs a right hand dot
                    imageSet(i, heightCenterPix + pRange, rightCenterPix + pRange) = circleImg(circlePix, circlePix);
                end
                if i == c.kLeftStim || i == c.kBothStim        	% needs a left hand dot
                    imageSet(i, heightCenterPix + pRange, leftCenterPix + pRange) = circleImg(circlePix, circlePix);
                end
                obj.images{i} = squeeze(imageSet(i, :, :));     % save the image in a cell array
            end
            % update the image position values
            obj.numPos = floor(obj.windRectPix(3) / obj.stepSizePix);
            obj.numPos = obj.numPos - (1 - mod(obj.numPos, 2)); % numPos must be odd
            centerIndex = ceil(obj.numPos / 2);
            obj.imagePosPix = zeros(1, obj.numPos);
            obj.imagePosPix(centerIndex) = floor(obj.windRectPix(3) / 2 - 0.5 * obj.stepSizePix);
            for p = 1:floor(obj.numPos / 2)
                obj.imagePosPix(centerIndex - p) = obj.imagePosPix(centerIndex - p + 1) - obj.stepSizePix;
                obj.imagePosPix(centerIndex + p) = obj.imagePosPix(centerIndex + p - 1) + obj.stepSizePix;
            end
        end    

        %%
        function degrees = pixToDeg(obj, pix)
            assert(obj.viewDistanceMM > 0, 'RTStimulus, pixToDeg: viewDistanceMM has not yet been set');
            degrees = atan2(pix / obj.pixPerMM, obj.viewDistanceMM) * obj.degPerRadian;
        end
        
        %% 
        function prepareImages(obj, trialType, stepDirection)
            c = RTConstants;
            % first offset the image position if the current position won't accommodate the left or right step. 
            % we don't really need to do anything for a centering trial
            if trialType == c.kCenteringTrial
                drawImage(obj, obj.currentImageIndex);                  % must draw for trial equivalence
            else
                if stepDirection == c.kLeft                           	% going to step left
                    if obj.currentImageIndex == c.kLeftStim
                        obj.currentOffsetIndex = obj.currentOffsetIndex - 1;    % shift one position leftward
                    end
                    drawImage(obj, c.kRightStim);                         % draw same spot with new image
                    obj.finalStim = c.kLeftStim;
                else
                    if obj.currentImageIndex == c.kRightStim             % going to step right
                        obj.currentOffsetIndex = obj.currentOffsetIndex + 1; % shift one position leftward
                    end
                    drawImage(obj, c.kLeftStim);
                    obj.finalStim = c.kRightStim;
               end
            end
            % set up the gap stimuli 
            switch trialType
                case c.kCenteringTrial
                    obj.gapStim = obj.finalStim;
                case c.kStepTrial
                    obj.gapStim = obj.finalStim;
                case c.kGapTrial
                    obj.gapStim = c.kBlankStim;
                case c.kOverlapTrial
                    obj.gapStim = c.kBothStim;
            end
        end
        
        %% setViewDistanceCM -- set the viewing distance, build the visual stimuli
        function setViewDistanceCM(obj, newValueCM)
            if obj.viewDistanceMM ~= newValueCM
                obj.viewDistanceMM = newValueCM * 10.0;
                makeSpotImages(obj);                                        % make new spot images
                obj.currentOffsetIndex = ceil(obj.numPos / 2);            	% center position
                c = RTConstants;
                drawImage(obj, c.kLeftStim);                               % draw the center spot
            end
        end

        %% stepStimulus -- Step the stimulus
%         function stepSign = stepStimulus(obj, offsetDeg)
%     %             stepSign = -sign(obj.currentOffsetPix);
%     %             if stepSign == 0
%     %                 stepSign = sign(rand - 0.5);
%     %             end
%     %             newOffsetDeg = currentOffsetDeg + stepSign  * offsetDeg;
%             newOffsetDeg = currentOffsetDeg(obj) + offsetDeg;
%             newOffsetMM = obj.viewDistanceMM * tan(newOffsetDeg / 57.2958);
%             obj.currentOffsetPix = newOffsetMM * obj.pixPerMM;
%             drawDot(obj);
%         end
    end        
end
            