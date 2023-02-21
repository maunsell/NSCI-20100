 classdef makeSRData < matlab.uitest.TestCase
 % Matlab App Testing Framework approach to testing SaccadeRT
  methods (Test)

    function test_SR(testCase)
      fprintf('This operation requires a LabJack U6 with DAC0 connected to ANI0\n')
      app = StretchReceptor('test');                % launch in test mode
      testCase.addTeardown(@delete, app);           % delete app after testing is done
      testCase.type(app.longWindowLimitText, '20');
      testCase.type(app.longWindowMSText, '1000');
      testCase.type(app.shortWindowMSText, '250');
      rates = 25;
      for i = 1:length(rates)
        app.fakeSpikeRateHz = rates(i);
        testCase.press(app.startButton);                % start data collection
        while ~strcmp(app.startButton.Text, 'Start')
          pause(2);
        end
        testCase.press(app.savePlotsButton);          % save the samples
      end
    end

  end
end