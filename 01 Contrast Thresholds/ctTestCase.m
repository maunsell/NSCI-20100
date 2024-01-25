classdef ctTestCase < matlab.uitest.TestCase
 % Matlab App Testing Framework approach to testing ContrastThreholds
 % This test is initiated by selecting this file in the editor pane of Matlab and then
 % pressing the "Run Tests" button in the Matlab Editor toolbar
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
      matlab.uitest.unlock(app.figure1);            % allow user interaction during run
      repsInc = 5;
      repsLimit = 50;
      intertrialDurS = 0.25;
      prestimDurS = 0.25;
      stimDurS = 0.25;
      testCase.type(app.stimRepsText, sprintf('%d', repsInc));
      testCase.type(app.intertrialDurText, sprintf('%.1f', intertrialDurS));
      testCase.type(app.prestimDurText, sprintf('%.1f', prestimDurS));
      testCase.type(app.stimDurText, sprintf('%.1f', stimDurS));
      testCase.press(app.runButton);                % start data collection
      while ~strcmp(app.runButton.Text, 'Stop')     % wait for run to start
      end
      while true
        while strcmp(app.runButton.Text, 'Stop')    % wait for end of a block
          pause(1);
        end
        testCase.press(app.savePlotsButton);        % save the data
        repsDone = str2double(app.stimRepsText.Value);
        testCase.type(app.stimRepsText, sprintf('%d', repsDone + repsInc))
        if (repsDone >= repsLimit)
          break;
        end
        testCase.press(app.runButton);                % start data collection
        while ~strcmp(app.runButton.Text, 'Stop')     % wait for run to start
        end
      end 
    end

  end
end