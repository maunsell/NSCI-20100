function testStimuli
        pixelDepth = 32;
        numGabors = 2;
%         gaborDimPix = 300;
        gaborDimPix = 500;
%         gaborSigma = 300 / 7;
        gaborSigma = 500 / 7;
        gaborOriDeg = 0;
        gaborContrast = 0.5;
        gaborPhaseDeg = 0;
        gaborCycles = 4;
%         gaborFreqPix = 4 / 300;
        gaborFreqPix = 3 / 500;
%         gaborShiftPix = 240;
        gaborShiftPix = 400;
%     end
%     methods
        %% ctStimuli()
%             oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', [0]);
        pixelDepth = 32;
        numGabors = 1;
        gaborDimPix = 300;
        gaborSigma = 300 / 7;
        gaborOriDeg = 0;
        gaborContrast = 0.5;
        gaborPhaseDeg = 0;
        gaborCycles = 4;
        gaborFreqPix = 4 / 300;
        gaborShiftPix = 240;

        PsychDefaultSetup(2);

        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma'); 

        obj.screenNumber = max(Screen('Screens'));
        obj.whiteColor = WhiteIndex(obj.screenNumber);
        obj.grayColor = obj.whiteColor / 2;
        screenRectPix = Screen('Resolution', obj.screenNumber);
        obj.windowRectPix = [screenRectPix.width - 1250, 50, screenRectPix.width - 50, 980];
        [obj.window, obj.windowRectPix] = PsychImaging('OpenWindow', obj.screenNumber, obj.grayColor, ...
            obj.windowRectPix, pixelDepth, 2, [], [], kPsychNeed32BPCFloat);
        PsychColorCorrection('SetEncodingGamma', obj.window, 1/2.2);
        obj.topPriorityLevel = MaxPriority(obj.window);
        [obj.xCenterPix, obj.yCenterPix] = RectCenter(obj.windowRectPix);
        obj.frameDurS = Screen('GetFlipInterval', obj.window);
        xPosPix = [obj.xCenterPix - gaborShiftPix obj.xCenterPix + gaborShiftPix];
        yPosPix = [obj.yCenterPix obj.yCenterPix];
        baseRect = [0 0 gaborDimPix gaborDimPix];
        obj.allRects = nan(4, numGabors);
        for i = 1:numGabors
            obj.allRects(:, i) = CenterRectOnPointd(baseRect, xPosPix(i), yPosPix(i));
        end
        Priority(obj.topPriorityLevel);
        propertiesMat = repmat([NaN, gaborFreqPix, gaborSigma, gaborContrast, 1.0, 0, 0, 0], ...
            numGabors, 1);
        propertiesMat(:, 1) = [0];
        obj.gaborTex = CreateProceduralGabor(obj.window, gaborDimPix, gaborDimPix, [], ...
            [0.5 0.5 0.5 0.0], 1, 0.5);
        lastMin = -1;
        lastMax = -1;
        counter = 1;
        for contrast = 0.00:0.001:1.0
            propertiesMat(:, 4) = contrast;
            drawGabors(obj, propertiesMat);
            Screen('Flip', obj.window);
            img = Screen('GetImage', obj.window);
            thisMin = min(min(min(img)));
            thisMax = max(max(max(img)));
            if (thisMin ~= lastMin || thisMax ~= lastMax)
                fprintf('Level %d: contrast %.2f%%, min %d max %d\n', counter, contrast * 100, thisMin, thisMax);
                lastMax = thisMax;
                lastMin = thisMin;
                counter = counter + 1;
           end
        end
        Priority(0);
end

        function drawGabors(obj, propertiesMat)
        	Screen('BlendFunction', obj.window, 'GL_ONE', 'GL_ZERO');
            Screen('DrawTextures', obj.window, obj.gaborTex, [], obj.allRects, 0.0, [], [], [], [],...
                    kPsychDontDoRotation, propertiesMat');
        end
