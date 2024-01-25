function poissonJND

  for countPeriodS = [1.0, 0.25]
    lamda = [5, 10, 15, 20, 25] + 2.5;
    for l = 1:length(lamda)
      counts = poissrnd(lamda(l) * countPeriodS, 1, 100000);
      histogram(counts);
%       pc = prctile(counts, [25, 50, 75]) ./ countPeriodS;
      meanRate = mean(counts) / countPeriodS;
      quartileRate = std(counts) / countPeriodS * 0.674;   % 0.25 probablity

      fprintf('%5.1f %5.1f\n', lamda(l), meanRate + quartileRate);
%       fprintf('rate %5.1f spikes/s, window %.2f s, 25%%-mean-75%% %04.1f-%04.1f-%04.1f, WF: %4.2f\n', ...
%         lamda(l), countPeriodS, meanRate - quartileRate, meanRate, meanRate + quartileRate, quartileRate / meanRate);
%       fprintf(' %4.1f\n',  -(quartileRate * 70.45) +480.584);
%       fprintf(' %4.2f\n',  quartileRate / meanRate);
    end
    fprintf('\n');
  end
end