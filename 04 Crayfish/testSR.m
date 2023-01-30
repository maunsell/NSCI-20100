 classdef testSR < matlab.uitest.TestCase
 % Matlab App Testing Framework approach to testing SaccadeRT
  methods (Test)

    function test_SR(testCase)
      app = StretchReceptor('test');                % launch in test mode
      testCase.addTeardown(@delete, app);           % delete app after testing is done
      app.volumeSlider.Value = 4;                   % 2 is the minimum (for some reason I don't remember)
      setVolume(app.signals, app);                  % update the volume setting using the changed value
      testCase.type(app.longWindowLimitText, '50');
      testCase.type(app.longWindowMSText, '1000');
      testCase.type(app.shortWindowMSText, '250');
      testCase.press(app.singleSpikeCheckbox);
      rateHz = 20:10:30;
      numRates = length(rateHz);
      thresholds = zeros(4, numRates + 1);
      meanRates = zeros(1, numRates + 1);
      for r = 1:numRates
        app.fakeSpikeRateHz = rateHz(r) * (1 + rand() * 0.15);
        testCase.press(app.startButton);                % start data collection
        while ~strcmp(app.startButton.Text, 'Start')
          pause(2);
        end
        testCase.press(app.savePlotsButton);          % save the samples
        testCase.press(app.clearButton);
        tableData = get(app.resultsTable, 'Data');          % update table
        meanRates(r + 1) = str2double(tableData{1, 4});
        thresholds(1, r + 1) = str2double(tableData{1, 3});
        thresholds(2, r + 1) = str2double(tableData{1, 5});
        thresholds(3, r + 1) = str2double(tableData{2, 3});
        thresholds(4, r + 1) = str2double(tableData{2, 5});
        figure(1);
        clf;
        hold on;
        plot(meanRates(1:r+1), thresholds(:, 1:r+1), '-o');
        plot(meanRates(1:r+1), meanRates(1:r+1), 'k:o');
        hold off;
      end
    end

  end
end