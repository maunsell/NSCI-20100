function ctDrawHitRates(app, doAllBaseContrasts)
% Draw the hit rates, their CIs, and fitted pschometric function for one
% (or all) base contrast(s). This isdone at the end of each trial.

  hitRate = zeros(size(app.trialsDone));              % for all hitRate
  errNeg = zeros(size(app.trialsDone));               % for all neg CIs
  errPos = zeros(size(app.trialsDone));               % for all pos CIs
  pci = zeros(size(app.trialsDone, 1), size(app.trialsDone, 2), 2);
  if (doAllBaseContrasts) 
    basesToUpdate = 1:app.numIncrements;
  else
    basesToUpdate = app.baseIndex;
  end
  for base = 1:app.numIncrements
    [hitRate(base, :), pci(base,:,:)] = binofit(app.hits(base, :), app.trialsDone(base, :));
    errNeg(base, :) = hitRate(base, :) - pci(base, :, 1);
    errPos(base, :) = pci(base, :, 2) - hitRate(base, :);
    % update table entry for current base
    if base == app.baseIndex
      tableData = get(app.resultsTable, 'Data');        % update table, regardless
      blocksDone = floor(mean(app.trialsDone(base, :)));
      tableData{1, base} = sprintf('%.0f', blocksDone);
      % If we've just finished a block, and we have enough blocks
      if ((blocksDone > app.blocksFit(base))) && blocksDone > 3
        fitParams = ctSigmoidFit(app, base, hitRate(base, :));      % fit logistic function, update table
        % save fitted curve for plotting later
        app.fitYValues(base, :) = 0.5 + 0.5 ./ (1.0 + exp(-fitParams(2) * (app.fitXValues(base, :) - fitParams(1))));
        % record the number of blocks in the current fit
        app.blocksFit(base) = floor(mean(app.trialsDone(base, :)));


        tableData{2, base} = sprintf('%.1f%%', fitParams(1) * 100.0);
        tableData{3, base} = sprintf('%.1f%% - %.1f%%', ctConfidenceInterval(app, base));
      elseif blocksDone == 0                            % or clear table entry
        tableData{2, base} = '';
        tableData{3, base} = '';
      end
      set(app.resultsTable, 'Data', tableData);
    end
  end

  % plot points and CIs (using errorbar), then fit curves and marker lines if enough blocks have been done
  x = app.testContrasts';                             % test values for all base contrasts
  errorbar(app.axes1, x, hitRate', errNeg', errPos', 'o', 'markerfacecolor', [0.5, 0.5, 0.5], 'markersize', 8);
  hold(app.axes1, 'on');
  plot(app.axes1, [0.02, 1.0], [0.75, 0.75], 'color', [0.75, 0.75, 0.75]);  % mark threshold level
  plot(app.axes1, [0.02, 1.0], [0.5, 0.5], 'color', [0.75, 0.75, 0.75]);    % mark chance level
  set(app.axes1, 'ColorOrderIndex', 1)                % reset the color order post 2014 version
  % plot fitted functions
  plot(app.axes1, app.fitXValues', app.fitYValues', '-');
  set(app.axes1, 'ColorOrderIndex', 1);               % reset the color order post 2014 version
  % vertical lines marking the base contrasts
  plot(app.axes1, repmat(app.baseContrasts, 2, 1), repmat([0; 1], 1, app.numBases));

  %   Set up the axis scaling and labeling
  minX = 0.02;
  axis(app.axes1, [minX, 1.0, 0.0 1.0]);
  set(app.axes1, 'xGrid', 'on', 'yGrid', 'off');
  set(app.axes1, 'yTick', 0.0:0.1:1.0);
  set(app.axes1, 'yTickLabel', {'0', '', '20', '', '40', '', '60', '', '80', '', '100'});
  set(app.axes1, 'xTick', [minX; 0.03; 0.04; 0.05; 0.06; 0.07; 0.08; 0.09; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.8; 1.0]);
  set(app.axes1, 'xTickLabel', [2:10, 20:10:60, 80, 100]);
  set(app.axes1, 'xscale','log');
  xlabel(app.axes1, 'stimulus contrast (%)', 'fontSize', 14);
  ylabel(app.axes1, 'correct (%)', 'fontSize', 14);
  hold(app.axes1, 'off');
end