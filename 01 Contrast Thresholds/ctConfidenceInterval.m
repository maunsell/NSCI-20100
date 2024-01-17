function CIs = ctConfidenceInterval(app, i)

  tstart = tic;
  numBoot = 100;
  thresholds = zeros(numBoot, 1);
  hits = app.hits(i, :);
  n = app.trialsDone(i, :);
  for rep = 1:numBoot
    bootRate = binornd(n, hits ./ n) ./ n;
    thresholds(rep) = ctSigmoidFit(app, i, bootRate);
  end
  CIs = prctile(thresholds, [2.5, 97.5]);
end
