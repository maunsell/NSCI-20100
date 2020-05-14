function handles = ctDrawHitRates(app, handles, doAllBaseContrasts)

  baseIndex = find(contains(get(app.baseContrastMenu, 'items'), get(app.baseContrastMenu, 'value')));
  hitRate = zeros(size(handles.data.trialsDone));             % for all hitRates
  errNeg = zeros(size(handles.data.trialsDone));              % for all neg CIs
  errPos = zeros(size(handles.data.trialsDone));              % for all pos CIs
  pci = zeros(size(handles.data.trialsDone, 1), size(handles.data.trialsDone, 2), 2);
  for i = 1:(size(handles.data.trialsDone, 1))                % for each base
    [hitRate(i,:), pci(i,:,:)] = binofit(handles.data.hits(i, :), handles.data.trialsDone(i, :));
    errNeg(i, :) = hitRate(i, :) - pci(i, :, 1);
    errPos(i, :) = pci(i, :, 2) - hitRate(i, :);
    if doAllBaseContrasts || i == baseIndex                 % for current block (or when all are requested
      blocksDone = floor(mean(handles.data.trialsDone(i, :)));
      tableData = get(handles.resultsTable, 'Data');      % update table, regardless
      tableData{1, i} = sprintf('%.0f', blocksDone);
      % If we've just finished a block, and we have enough blocks, fit a logistic function.
      % We force 0.5 performance at the base contrast.
      if (doAllBaseContrasts || (blocksDone > handles.data.blocksFit(i))) && blocksDone > 3
        fun = @(params, xData) 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData - params(1))));
        xData = [app.baseContrasts(i) handles.data.testContrasts(i, :)];
        yData = [0.5 hitRate(i,:)];
        x0 = [xData(ceil(length(xData) / 2)); 5];
        OLS = @(params) sum((fun(params, xData) - yData).^2);
        opts = optimset('Display', 'off', 'MaxFunEvals', 10000, 'MaxIter', 5000);
        params = fminsearch(OLS, x0, opts);
        handles.data.curveFits(i, :) = 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData(1:end) - params(1))));
        handles.data.blocksFit(i) = blocksDone;         % update block count and table
        tableData{2, i} = sprintf('%.1f%%', params(1) * 100.0); % threshold contrast
        %                 tableData{3, i} = sprintf('%.1f%%', (params(1) - handles.data.baseContrasts(i)) * 100.0); % difference
        %                 tableData{4, i} = sprintf('%.2f', params(1) / handles.data.baseContrasts(i) - 1); % Weber fraction
      elseif blocksDone == 0
        tableData{2, i} = '';
      end
      set(handles.resultsTable, 'Data', tableData);
    end
  end
  % plot points and CIs (using errorbar), then fit curves and marker lines if enough blocks have been done
  vStr = version('-release');
  post2015 = str2double(vStr(1:4)) >= 2014;
  x = handles.data.testContrasts';                             % test values for all base contrasts
  errorbar(handles.axes1, x, hitRate', errNeg', errPos', 'o', 'markerfacecolor', [0.5, 0.5, 0.5], 'markersize', 8);
  hold(handles.axes1, 'on');
  if (post2015)
    set(handles.axes1, 'ColorOrderIndex', 1)                % reset the color order post 2014 version
  end
  newx = [app.baseContrasts' handles.data.testContrasts]'; % include the base contrasts
  plot(handles.axes1, newx, handles.data.curveFits', '-');
  sprintf('set');
  if (post2015)
    set(handles.axes1, 'ColorOrderIndex', 1);               % reset the color order post 2014 version
  end
  % plot vertical lines marking the base contrasts
  plot(handles.axes1, repmat(app.baseContrasts, 2, 1), repmat([0; 1], 1, app.numBases));
  %                             repmat([0; 1], 1, size(handles.data.baseContrasts, 2)));
  %   Set up the axis scaling and labeling
  axis(handles.axes1, [0.02, 1.0, 0.0 1.0]);
  set(handles.axes1, 'xGrid', 'on', 'yGrid', 'off');
  set(handles.axes1, 'yTick', [0.0; 0.2; 0.4; 0.6; 0.8; 1.0]);
  set(handles.axes1, 'yTickLabel', [0; 20; 40; 60; 80; 100]);
  set(handles.axes1, 'xTick', [0.02; 0.03; 0.04; 0.05; 0.06; 0.07; 0.08; 0.09; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.8; 1.0]);
  set(handles.axes1, 'xTickLabel', [2; 3; 4; 5; 6; 7; 8; 9; 10; 20; 30; 40; 50; 60; 80; 100]);
  set(handles.axes1, 'xscale','log');
  xlabel(handles.axes1, 'stimulus contrast (%)', 'fontSize', 14);
  ylabel(handles.axes1, 'correct (%)', 'fontSize', 14);
  hold(handles.axes1, 'off');
end