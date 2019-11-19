 classdef RTConstants
    properties(Constant = true)         % force readonly
        kCenteringTrial = 0             % trial types
        kGapTrial = 1
        kStepTrial = 2
        kOverlapTrial = 3
        kTrialTypes = 3
        
        kBlankStim = 1                  % stimulus images
        kLeftStim = 2
        kRightStim = 3
        kBothStim = 4
        kStimTypes = 4
        
        kLeft = -1
        kRight = 1
    end
 end