classdef EOGStimulus < handle
    % Contrast threshold stimuli controller
    properties
        currentOffsetPix
        tag
    end
    properties (GetAccess = private)
        frameDurS
        grayColor
        pixPerMM
        screenNumber
        topPriorityLevel
        viewDistanceMM
        whiteColor
        window
        windowRectPix
        xCenterPix
        yCenterPix
    end
    properties (Constant)
        marginPix = 50;
        pixelDepth = 32;
    end
    methods (Static)
    end
    methods
        function obj = EOGStimulus()
            Screen('CloseAll');
            PsychDefaultSetup(2);
            obj.screenNumber = max(Screen('Screens'));
            obj.whiteColor = WhiteIndex(obj.screenNumber);
            obj.grayColor = obj.whiteColor / 2;
            obj.currentOffsetPix = 0;
            screenRectPix = Screen('Resolution', obj.screenNumber);
            obj.windowRectPix = [obj.marginPix, screenRectPix.height - 200, ...
                                            screenRectPix.width - obj.marginPix, screenRectPix.height - 100];
            [widthMM, ~] = Screen('DisplaySize', obj.screenNumber);
            obj.pixPerMM = obj.windowRectPix(3) / widthMM;
            [obj.window, obj.windowRectPix] = PsychImaging('OpenWindow', obj.screenNumber, obj.grayColor, ...
                obj.windowRectPix, obj.pixelDepth, 2, [], [], kPsychNeed32BPCFloat);
            obj.topPriorityLevel = MaxPriority(obj.window);
            [obj.xCenterPix, obj.yCenterPix] = RectCenter(obj.windowRectPix);
            obj.frameDurS = Screen('GetFlipInterval', obj.window);
            drawDot(obj);
        end
        
        function centerStimulus(obj)
            obj.currentOffsetPix = 0;
            drawDot(obj);
        end
        
        function cleanup(obj)
            sca;
        end
        
        function clearScreen(obj)
            Screen('Flip', obj.window);
        end
        
        %% currentOffsetDeg -- offset of the spot from screen center in degrees
        function offsetDeg = currentOffsetDeg(obj)
            offsetMM = obj.currentOffsetPix / obj.pixPerMM;
            offsetDeg = atan2(offsetMM, obj.viewDistanceMM) * 57.2958;
        end
        
        %% drawDot -- draw the dot at the currently specified pixel offset
        function drawDot(obj)
            Screen('BlendFunction', obj.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
            Screen('DrawDots', obj.window, [obj.currentOffsetPix; 0], 16 , obj.whiteColor, ...
                                                        [obj.xCenterPix obj.yCenterPix], 1);
            Screen('Flip', obj.window);
        end
        
        %% maxDeg -- maximum extent of the display in degrees (left edge to right edge)
        function limitDeg = maxDeg(obj)
            limitDeg = atan2((obj.windowRectPix(3) / 2.0 - obj.marginPix) / obj.pixPerMM, obj.viewDistanceMM) * 57.2958;
        end
        
        function limitDistCM = maxViewDistanceCM(obj, maxDeg)
            limitDistCM = (obj.windowRectPix(3) / 2.0 - obj.marginPix) / obj.pixPerMM / tan(maxDeg / 57.2958) / 10.0;
        end
        
        %% stepOutOfRange -- Report whether a step would move the target offscreen       
        function outOfRange = stepOutOfRange(obj, offsetDeg)
            outOfRange = abs(currentOffsetDeg(obj) + offsetDeg) > maxDeg(obj);
        end
  
        %% setViewDistanceCM -- set the viewing distance
        
        function setViewDistanceCM(obj, newValueCM)
            obj.viewDistanceMM = newValueCM * 10.0;
        end
        
        %% stepStimulus -- Step the stimulus
 
        function stepSign = stepStimulus(obj, offsetDeg)
%             stepSign = -sign(obj.currentOffsetPix);
%             if stepSign == 0
%                 stepSign = sign(rand - 0.5);
%             end
%             newOffsetDeg = currentOffsetDeg + stepSign  * offsetDeg;
            newOffsetDeg = currentOffsetDeg(obj) + offsetDeg;
            newOffsetMM = obj.viewDistanceMM * tan(newOffsetDeg / 57.2958);
            obj.currentOffsetPix = newOffsetMM * obj.pixPerMM;
            drawDot(obj);
        end
    end        
end
            