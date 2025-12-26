function CIs = ctConfidenceInterval(app, base)

% Use a bootstrap to find the confidence interval for one base contrast
% threshold
  numBoot = 100;
  thresholds = zeros(numBoot, 1);
  hits = app.hits(base, :);
  n = app.trialsDone(base, :);
  for rep = 1:numBoot
    bootRate = binornd(n, hits ./ n) ./ n;
    fitParams = ctSigmoidFit(app, base, bootRate);
    thresholds(rep) = fitParams(1) * 100.0;
  end
  CIs = prctile(thresholds, [2.5, 97.5]);
end
