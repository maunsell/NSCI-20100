classdef testSaccadeRT < matlab.uitest.TestCase
 % Matlab App Testing Framework approach to testing SaccadeRT
  methods (Test)

    function test_SampleSize(testCase)
      app = SaccadeRT('test');              % launch in test mode
      testCase.addTeardown(@delete, app);   % delete app after testing is done
%       fprintf('\n==================================================================\n');
%       fprintf('===================================================================\n');
%       fprintf('testSaccadeRT: This test script exercises SaccadeRT\n');
%       fprintf('  To enable user interactions while test is running you must enter:\n');
%       fprintf('  matlab.uitest.unlock(app.figure1), dbcont\n');
%       fprintf('  Or, to proceed without user interaction, enter:\n');
%       fprintf('  dbcont\n');
%       keyboard;
      blockInc = 10;
      blockLimit = 50;
      speedThresholdDPS = 150;
      testCase.type(app.stopAfterText, sprintf('%d', blockInc));
      testCase.type(app.thresholdDPSText, sprintf('%d', speedThresholdDPS));
      testCase.press(app.SpeedButton);
      testCase.press(app.startButton);                % start data collection
%       blocksToSave = str2double(app.stopAfterText.Value);
      while true
%         blocksDone = min([app.rtDists{app.kStepTrial}.n, app.rtDists{app.kGapTrial}.n]);
        while strcmp(app.startButton.Text, 'Stop')
          pause(1);
%           fprintf('%d blocks done\n', blocksDone);
        end
        testCase.press(app.savePlotsButton);          % save the samples
        blocksDone = str2double(app.stopAfterText.Value);
        testCase.type(app.stopAfterText, sprintf('%d', blocksDone + blockInc))
        if (blocksDone >= blockLimit)
          break;
        end
        testCase.press(app.startButton);              % start data collection
      end 
    end

  end
end