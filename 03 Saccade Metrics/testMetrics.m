 classdef testMetrics < matlab.uitest.TestCase
 % Matlab App Testing Framework approach to testing SaccadeRT
  methods (Test)

    function test_Metrics(testCase)
      app = Metrics('test');                % launch in test mode
      testCase.addTeardown(@delete, app);   % delete app after testing is done
      blockInc = 5;
      blockLimit = 1000;
      testCase.type(app.stopAfterText, sprintf('%d', blockInc));
      testCase.press(app.startButton);                % start data collection
      while true
        while strcmp(app.startButton.Text, 'Stop')
          pause(1);
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