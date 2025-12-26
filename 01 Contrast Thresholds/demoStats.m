function demoStats
% Draw the hit rates, their CIs, and fitted pschometric function for one
% (or all) base contrast(s). This isdone at the end of each trial.

  numPoints = 100;                                % number of points to display
  numSamples = 25;                                % number of samples per point
  hitSums = sum(randi([0, 1], numSamples, numPoints));
  [hitRates, pci] = binofit(hitSums, numSamples);
  figure(1);
  clf;
  errBars = hitRates - pci(:, 1:2)';
  ax = errorbar(1:1:numPoints, hitRates, errBars(1, :), errBars(2, :), ...
              'o', 'markerfacecolor', 'b', 'markersize', 6, 'LineWidth', 1.5);
  hold on;
  plot([-2, numPoints + 2], [0.5, 0.5], 'k', 'LineWidth', 1);
  ylim([0.0, 1.0]);
  xlim([-2.0, numPoints + 2]);
  xticks([]);
  yticks([0.0, 0.5, 1.0]);
  yticklabels({'0.0', '0.5', '1.0'});
  ax.Parent.FontSize = 16;
  % % plot points and CIs (using errorbar), then fit curves and marker lines if enough blocks have been done
  % x = app.testContrasts';                             % test values for all base contrasts
  % errorbar(app.axes1, x, hitRate', errNeg', errPos', 'o', 'markerfacecolor', [0.5, 0.5, 0.5], 'markersize', 8);
  % hold(app.axes1, 'on');
  % plot(app.axes1, [0.02, 1.0], [0.75, 0.75], 'color', [0.75, 0.75, 0.75]);  % mark threshold level
  % plot(app.axes1, [0.02, 1.0], [0.5, 0.5], 'color', [0.75, 0.75, 0.75]);    % mark chance level
  % set(app.axes1, 'ColorOrderIndex', 1)                % reset the color order post 2014 version
  % % plot fitted functions
  % plot(app.axes1, app.fitXValues', app.fitYValues', '-');
  % set(app.axes1, 'ColorOrderIndex', 1);               % reset the color order post 2014 version
  % % vertical lines marking the base contrasts
  % plot(app.axes1, repmat(app.baseContrasts, 2, 1), repmat([0; 1], 1, app.numBases));

  % %   Set up the axis scaling and labeling
  % minX = 0.02;
  % axis(app.axes1, [minX, 1.0, 0.0 1.0]);
  % set(app.axes1, 'xGrid', 'on', 'yGrid', 'off');
  % set(app.axes1, 'yTick', 0.0:0.2:1.0);
  % % set(app.axes1, 'yTick', [0.0; 0.2; 0.4; 0.6; 0.8; 1.0]);
  % % set(app.axes1, 'yTickLabel', [0; 20; 40; 60; 80; 100]);
  % set(app.axes1, 'yTickLabel', 0:20:100);
  % set(app.axes1, 'xTick', [minX; 0.03; 0.04; 0.05; 0.06; 0.07; 0.08; 0.09; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.8; 1.0]);
  % % set(app.axes1, 'xTickLabel', [2; 3; 4; 5; 6; 7; 8; 9; 10; 20; 30; 40; 50; 60; 80; 100]);
  % set(app.axes1, 'xTickLabel', [2:10, 20:10:60, 80, 100]);
  % set(app.axes1, 'xscale','log');
  % xlabel(app.axes1, 'stimulus contrast (%)', 'fontSize', 14);
  % ylabel(app.axes1, 'correct (%)', 'fontSize', 14);
  % hold(app.axes1, 'off');
end