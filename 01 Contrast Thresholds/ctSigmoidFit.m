function fitParams = ctSigmoidFit(app, base, hitRate)

  % get the best fitting parameters for the psychometric function
  fun = @(params, xData) 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData - params(1))));
  xData = [app.baseContrasts(base) app.testContrasts(base, :)];
  yData = [0.5 hitRate];
  x0 = [xData(ceil(length(xData) / 2)); 5];
  OLS = @(params) sum((fun(params, xData) - yData).^2);
  opts = optimset('Display', 'off', 'MaxFunEvals', 10000, 'MaxIter', 5000);
  fitParams = fminsearch(OLS, x0, opts);
  % save the computed hit rates for the fitted function
  % app.hitRates(base, :) = 0.5 + 0.5 ./ (1.0 + exp(-fitParams(2) * (xData(1:end) - fitParams(1))));
  % % save fitted curve for plotting later
  % app.fitYValues(base, :) = 0.5 + 0.5 ./ (1.0 + exp(-fitParams(2) * (app.fitXValues(base, :) - fitParams(1))));
  % % record the number of blocks in the current fit
  % app.blocksFit(base) = floor(mean(app.trialsDone(base, :)));
  % threshold = fitParams(1);
end
