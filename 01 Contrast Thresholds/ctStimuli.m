classdef ctStimuli
    % Contrast threshold stimuli controller
    properties (GetAccess = private)
        allRects
        blackColor
        frameDurS
        gaborTex
        grayColor
        screenNumber
        topPriorityLevel
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
        gaborOriDeg = 0;
        gaborContrast = 0.5;
        gaborPhaseDeg = 0;
        gaborCycles = 4;
        gaborFreqPix = 4 / 300;
        gaborShiftPix = 240;
    end
    methods
        function obj = ctStimuli()
%             oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', [0]);
            Screen('CloseAll');
            PsychDefaultSetup(2);
            obj.screenNumber = max(Screen('Screens'));
            obj.whiteColor = WhiteIndex(obj.screenNumber);
            obj.blackColor = BlackIndex(obj.screenNumber);
            obj.grayColor = obj.whiteColor / 2;
            screenRectPix = Screen('Resolution', obj.screenNumber);
%             obj.windowRectPix = [screenRectPix.width - 500, 50, screenRectPix.width - 50, 550];
            obj.windowRectPix = [screenRectPix.width - 1250, 50, screenRectPix.width - 50, 980];
            [obj.window, obj.windowRectPix] = PsychImaging('OpenWindow', obj.screenNumber, obj.grayColor, ...
                obj.windowRectPix, obj.pixelDepth, 2, [], [], kPsychNeed32BPCFloat);
            obj.topPriorityLevel = MaxPriority(obj.window);
            [obj.xCenterPix, obj.yCenterPix] = RectCenter(obj.windowRectPix);
            obj.frameDurS = Screen('GetFlipInterval', obj.window);
            obj.xPosPix = [obj.xCenterPix - obj.gaborShiftPix obj.xCenterPix + obj.gaborShiftPix];
            obj.yPosPix = [obj.yCenterPix obj.yCenterPix];
            baseRect = [0 0 obj.gaborDimPix obj.gaborDimPix];
            obj.allRects = nan(4, obj.numGabors);
            for i = 1:obj.numGabors
                obj.allRects(:, i) = CenterRectOnPointd(baseRect, obj.xPosPix(i), obj.yPosPix(i));
            end
            obj.gaborTex = CreateProceduralGabor(obj.window, obj.gaborDimPix, obj.gaborDimPix, [], ...
                [0.5 0.5 0.5 0.0], 1, 0.5);        
%             Screen('Preference','SuppressAllWarnings',oldEnableFlag);            
        end
        function cleanup(obj)
            sca;
        end
        function clearScreen(obj)
            Screen('Flip', obj.window);
        end
        function doFixSpot(obj, color)
            drawFixSpot(obj, color);
            Screen('Flip', obj.window);
        end
        function doStimulus(obj, stimParams)
            Priority(obj.topPriorityLevel);
            propertiesMat = repmat([NaN, obj.gaborFreqPix, obj.gaborSigma, obj.gaborContrast, 1.0, 0, 0, 0], ...
                obj.numGabors, 1);
            propertiesMat(:, 1) = [0; 180];
            propertiesMat(:, 4) = [stimParams.leftContrast; stimParams.rightContrast];
            stimFrames = stimParams.stimDurS / obj.frameDurS;
            drawGabors(obj, propertiesMat);
            drawFixSpot(obj, obj.whiteColor);
            vbl = Screen('Flip', obj.window);
            for frame = 1:stimFrames - 1
                drawGabors(obj, propertiesMat);
                drawFixSpot(obj, obj.whiteColor);
                vbl = Screen('Flip', obj.window, vbl + 0.5 * obj.frameDurS);
            end
            Priority(0);
        end
        function drawFixSpot(obj, color)
            Screen('BlendFunction', obj.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
            Screen('DrawDots', obj.window, [obj.xCenterPix; obj.yCenterPix], 10, color, [], 2);
        end
        function drawGabors(obj, propertiesMat)
        	Screen('BlendFunction', obj.window, 'GL_ONE', 'GL_ZERO');
            Screen('DrawTextures', obj.window, obj.gaborTex, [], obj.allRects, obj.gaborOriDeg, [], [], [], [],...
                    kPsychDontDoRotation, propertiesMat');
        end
    end
end
            