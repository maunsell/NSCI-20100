classdef testContrastThresholds < matlab.uitest.TestCase
 % Matlab App Testing Framework approach to testing SaccadeRT
  methods (Test)

    function test_SampleSize(testCase)
      app = ContrastThresholds('test');               % launch in test mode
      testCase.addTeardown(@delete, app);             % delete app after testing is done
      % fprintf('\n==================================================================\n');
      % fprintf('===================================================================\n');
      % fprintf('testContrastThresholds: This test script exercises ContrastThresholds\n');
      % fprintf('  To enable user interactions while test is running you must enter:\n');
      % fprintf('  matlab.uitest.unlock(app.figure1), dbcont\n');
      % fprintf('  Or, to proceed without user interaction, enter:\n');
      % fprintf('  dbcont\n');
      % keyboard;
      repsInc = 5;
      repsLimit = 10;
      testCase.type(app.stimRepsText, sprintf('%d', repsInc));
      testCase.press(app.runButton);                % start data collection
%       blocksToSave = str2double(app.stopAfterText.Value);
      while true
%         blocksDone = min([app.rtDists{app.kStepTrial}.n, app.rtDists{app.kGapTrial}.n]);
        while strcmp(app.runButton.Text, 'Stop')
          pause(1);
%           fprintf('%d blocks done\n', blocksDone);
        end
        testCase.press(app.savePlotsButton);          % save the samples
        repsDone = str2double(app.stimRepsText.Value);
        testCase.type(app.stimRepsText, sprintf('%d', repsDone + repsInc))
        if (repsDone >= repsLimit)
          break;
        end
        testCase.press(app.runButton);              % start data collection
      end 
    end

  end
end