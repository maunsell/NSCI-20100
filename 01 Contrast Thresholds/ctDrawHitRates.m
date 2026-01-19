function ctDrawHitRates(app, drawOnly)
% Draw the hit rates, their CIs, and fitted pschometric function for
% or all base contrasts. This is done at the end of each trial.

% Compute the values needed for plotting
  hitRate = zeros(app.numBases, app.numIncrements);     % hitRates
  errNeg = zeros(app.numBases, app.numIncrements);      % neg CIs
  errPos = zeros(app.numBases, app.numIncrements);      % pos CIs
  pci = zeros(app.numBases, app.numIncrements, 2);
  for base = 1:app.numBases
    [hitRate(base, :), pci(base,:,:)] = binofit(app.hits(base, :), app.trialsDone(base, :));
    errNeg(base, :) = hitRate(base, :) - pci(base, :, 1);
    errPos(base, :) = pci(base, :, 2) - hitRate(base, :);
  end

  % If we are actively collecting data, update the current base contrasts as needed
  if ~drawOnly
    blocksDone = floor(mean(app.trialsDone(app.baseIndex, :)));
    % If we're collecting and hit a block boundary, update the fits
    if blocksDone > app.blocksFit(app.baseIndex) && blocksDone > 3
      base = app.baseIndex;
      fitParams = ctSigmoidFit(app, base, hitRate(base, :)); % fit logistic function, update table
      % save fitted curve for plotting later
      app.fitYValues(base, :) = 0.5 + 0.5 ./ (1.0 + exp(-fitParams(2) * (app.fitXValues(base, :) - fitParams(1))));
      % record the number of blocks in the current fit
      app.blocksFit(base) = floor(mean(app.trialsDone(base, :)));
      app.thresholdsPC(base) = (fitParams(1) - app.baseContrasts(base)) * 100.0;
      CIs = ctConfidenceInterval(app, base);
      app.ci95LowPC(base) = CIs(1) - app.baseContrasts(base) * 100.0;
      app.ci95HighPC(base) = CIs(2) - app.baseContrasts(base) * 100.0;
      loadTable(app, base);
    else
      % If we're running and not hit a block, just update the number of
      % blocks
      tableData = get(app.resultsTable, 'Data');        % update table
      tableData{1, app.baseIndex} = sprintf('%.0f', blocksDone);
      set(app.resultsTable, 'Data', tableData);
    end
  else
    loadTable(app, 1:app.numBases);
  end
    % tableData = get(app.resultsTable, 'Data');        % update table, regardless
    % tableData{1, base} = sprintf('%.0f', blocksDone);
    % % If we're at the end of enough blocks, recompute the fit
    % if ((blocksDone > app.blocksFit(base))) && blocksDone > 3
    %   fitParams = ctSigmoidFit(app, base, hitRate(base, :));      % fit logistic function, update table
    %   % save fitted curve for plotting later
    %   app.fitYValues(base, :) = 0.5 + 0.5 ./ (1.0 + exp(-fitParams(2) * (app.fitXValues(base, :) - fitParams(1))));
    %   % record the number of blocks in the current fit
    %   app.blocksFit(base) = floor(mean(app.trialsDone(base, :)));
    %   app.thresholdsPC(base) = (fitParams(1) - app.baseContrasts(base)) * 100.0;
    %   CIs = ctConfidenceInterval(app, base);
    %   app.ci95LowPC(base) = CIs(1) - app.baseContrasts(base) * 100.0;
    %   app.ci95HighPC(base) = CIs(2) - app.baseContrasts(base) * 100.0;
    %   tableData{2, base} = sprintf('%.1f%%', app.thresholdsPC(base));
    %   tableData{3, base} = sprintf('%.1f%% - %.1f%%', app.ci95LowPC(base), app.ci95HighPC(base));
    % elseif blocksDone == 0                            % or clear table entry
    %   tableData{2, base} = '';
    %   tableData{3, base} = '';
    % end
    % set(app.resultsTable, 'Data', tableData);

  % plot points and CIs (using errorbar), then fit curves and marker lines if enough blocks have been done
  x = app.testContrasts';                             % test values for all base contrasts
  errorbar(app.axes1, x, hitRate', errNeg', errPos', 'o', 'LineWidth', 1.0, 'markerfacecolor', [0.5, 0.5, 0.5], ...
    'MarkerSize', 8);
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
  xlabel(app.axes1, 'stimulus contrast (%)', 'fontSize', 14);
  ylabel(app.axes1, 'hit rate (%)', 'fontSize', 14);
  set(app.axes1, 'xscale','log');
  hold(app.axes1, 'off');
end

  function loadTable(app, base)

  tableData = get(app.resultsTable, 'Data');        % update table
  for b = base
    blocksDone = floor(mean(app.trialsDone(b, :)));
    tableData{1, b} = sprintf('%.0f', blocksDone);
    if blocksDone > 0
      tableData{2, b} = sprintf('%.1f%%', app.thresholdsPC(b));
      tableData{3, b} = sprintf('%.1f%% - %.1f%%', app.ci95LowPC(b), app.ci95HighPC(b));
    else                         % or clear table entry
      tableData{2, b} = '';
      tableData{3, b} = '';
    end
  end
  set(app.resultsTable, 'Data', tableData);
end