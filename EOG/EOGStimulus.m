classdef EOGStimulus < handle
    % Contrast threshold stimuli controller
    properties
        currentOffsetPix
        tag
    end
    properties (GetAccess = private)
        frameDurS
        grayColor
        screenNumber
        topPriorityLevel
        whiteColor
        window
        windowRectPix
        xCenterPix
        yCenterPix
    end
    properties (Constant)
        pixelDepth = 32;
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
            obj.windowRectPix = [50, screenRectPix.height - 200, screenRectPix.width - 50, screenRectPix.height - 100];
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
        function drawDot(obj)
            Screen('BlendFunction', obj.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
            Screen('DrawDots', obj.window, [obj.currentOffsetPix; 0], 25, obj.whiteColor, ...
                                                        [obj.xCenterPix obj.yCenterPix], 1);
            Screen('Flip', obj.window);
        end
        function stepSign = stepStimulus(obj, offsetPix)
            stepSign = -sign(obj.currentOffsetPix);
            if stepSign == 0
                stepSign = sign(rand - 0.5);
            end
            obj.currentOffsetPix = obj.currentOffsetPix + stepSign * offsetPix;
            drawDot(obj);
        end
    end        
end
            