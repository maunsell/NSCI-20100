function threshold = ctSigmoidFit(app, i, hitRate)

  fun = @(params, xData) 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData - params(1))));
  xData = [app.baseContrasts(i) app.testContrasts(i, :)];
  yData = [0.5 hitRate];
  x0 = [xData(ceil(length(xData) / 2)); 5];
  OLS = @(params) sum((fun(params, xData) - yData).^2);
  opts = optimset('Display', 'off', 'MaxFunEvals', 10000, 'MaxIter', 5000);
  params = fminsearch(OLS, x0, opts);
  app.curveFits(i, :) = 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData(1:end) - params(1))));
  app.blocksFit(i) = floor(mean(app.trialsDone(i, :))); % update block count and table
  threshold = params(1) * 100.0;                        % threshold contrast
end
