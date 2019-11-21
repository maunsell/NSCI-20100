 classdef RTConstants
    properties(Constant)
        
        degPerRadian = 57.2958;
        maxViewDistCM = 100;
        mmPerInch = 25.40;
        
        kNormal = 0;                    % task modes
        kDebug = 1;
        kTiming = 2;
        
        kCenteringTrial = 0;             % trial types
        kGapTrial = 1;
        kStepTrial = 2;
        kOverlapTrial = 3;
        kTrialTypes = 3;
        
        kBlankStim = 1;                  % stimulus images
        kLeftStim = 2;
        kRightStim = 3;
        kBothStim = 4;
        kTestStim = 5;
        
        kLeft = -1;
        kRight = 1;
    end
 end