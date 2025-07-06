function plotRates

  figure(1);
  clf;
  meanRates = [5.6, 10.8, 14.8, 22.6, 25.9, 34.1];
  negLong = [5.1, 10.3, 14.1, 21.8, 24.9, 33.3];
  posLong = [6.0, 11.2, 15.5, 23.4, 26.9, 34.9];
  negShort = [4.2, 9.3, 13.4, 20.7, 24.1, 32.3];
  posShort = [6.9, 12.2, 16.3, 24.5, 27.7, 35.8];
  
  subplot(2, 2, 1)
  plot([0, 35], [0, 35], 'k:');
  axis([0, 40, 0, 40]);
  hold on;
  errorbar(meanRates, meanRates, meanRates - negShort, posShort - meanRates, 'bo', 'LineWidth', 1.0);
  title('Short window');

  subplot(2, 2, 2)
  plot([0, 35], [0, 35], 'k:');
  axis([0, 40, 0, 40]);
  hold on;
  errorbar(meanRates, meanRates, meanRates - negLong, posLong - meanRates, 'bo', 'LineWidth', 1.0);
  title('Long window');

  meanRates = [5.6, 10.8, 14.8, 22.6, 25.6, 25.9, 27.1, 34.1];
  negLong = [5.1, 10.3, 14.1, 21.8, 24.1, 24.9, 25.2, 33.3];
  posLong = [6.0, 11.2, 15.5, 23.4, 27.0, 26.9, 29.0, 34.9];
  negShort = [4.2, 9.3, 13.4, 20.7, 23.6, 24.1, 24.7, 32.3];
  posShort = [6.9, 12.2, 16.3, 24.5, 27.6, 27.7, 29.5, 35.8];

  subplot(2, 2, 3)
  plot([0, 35], [0, 35], 'k:');
  axis([0, 40, 0, 40]);
  hold on;
  errorbar(meanRates, meanRates, meanRates - negShort, posShort - meanRates, 'bo', 'LineWidth', 1.0);
  title('Short window -- Didn''t exclude drifting data');

  subplot(2, 2, 4)
  plot([0, 35], [0, 35], 'k:');
  axis([0, 40, 0, 40]);
  hold on;
  errorbar(meanRates, meanRates, meanRates - negLong, posLong - meanRates, 'bo', 'LineWidth', 1.0);
  title('Long window -- Didn''t exclude drifting data');
end