function ax = ctLinearFits(app)

% hitRate = zeros(app.numBases, app.numIncrements); % hitRates
% ci95low = zeros(app.numBases, 1);                 % neg CIs
% ci95high = zeros(app.numBases, 1);                % pos CIs
% thresholdsPC = zeros(app.numBases, 1);
% for base = 1:app.numBases
%   [hitRate(base, :), ~] = binofit(app.hits(base, :), app.trialsDone(base, :));
%   fitParams = ctSigmoidFit(app, base, hitRate(base, :));  % fit logistic function
%   thresholdsPC(base) = (fitParams(1) - app.baseContrasts(base)) * 100.0;
%   CIPC = ctConfidenceInterval(app, base) - app.baseContrasts(base) * 100.0;
%   ci95low(base) = CIPC(1);   % error bars are relative to threshold
%   ci95high(base) = CIPC(2);
% end
% ---- Plot settings ----
markerColor = [0 0.4470 0.7410];
markerShape = 'o';
markerSize = 8;

olsColor = [0.44 0.04 0.40];  % dark magenta
wlsColor = [0.20 0.46 0.08];  % dark green

lineWidth = 2;
fontSize = 12;


% ---- Estimate standard deviation from asymmetric CIs ----
ci95low = app.ci95LowPC';                   % neg CIs
ci95high = app.ci95HighPC';                 % pos CIs
avgCI = (ci95low + ci95high) / 2;
std_est = avgCI / 1.96;
weights = 1 ./ (std_est .^ 2);  % inverse variance weights

% ---- Design matrix with intercept ----
baseContrastsPC = app.baseContrasts(:) * 100.0;
X = [ones(size(baseContrastsPC)), baseContrastsPC];

% ---- OLS Fit ----
thresholdsPC = app.thresholdsPC';
ols_beta = (X' * X) \ (X' * thresholdsPC);
yfit_ols = X * ols_beta;

% OLS stats
yresid = thresholdsPC - yfit_ols;
dof = length(thresholdsPC) - 2;
s2 = sum(yresid.^2) / dof;
covb = s2 * inv(X' * X);
se_intercept = sqrt(covb(1,1));
t_ols = ols_beta(1) / se_intercept;
p_ols = 2 * (1 - tcdf(abs(t_ols), dof));
ci95_ols_intercept = ols_beta(1) + [-1 1] * tinv(0.975, dof) * se_intercept;

% ---- WLS Fit ----
W = diag(weights);
wls_beta = (X' * W * X) \ (X' * W * thresholdsPC);
yfit_wls = X * wls_beta;

% WLS stats
yresid_w = thresholdsPC - yfit_wls;
dof_w = length(thresholdsPC) - 2;
s2_w = sum(weights .* yresid_w.^2) / dof_w;
covb_w = s2_w * inv(X' * W * X);
se_intercept_w = sqrt(covb_w(1,1));
t_wls = wls_beta(1) / se_intercept_w;
p_wls = 2 * (1 - tcdf(abs(t_wls), dof_w));
ci95_wls_intercept = wls_beta(1) + [-1 1] * tinv(0.975, dof_w) * se_intercept_w;

% ---- Plotting ----
fig = figure(10);
clf(fig);
ax = axes(fig);
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');

xlabel(ax, 'Base Contrast (%)', 'FontSize', fontSize);
ylabel(ax, 'Threshold (% Contrast)', 'FontSize', fontSize);
title(ax, 'Ordinary and Weighted Linear Fits', 'FontSize', fontSize);

% Plot error bars (not included in legend)
errorbar(baseContrastsPC, thresholdsPC, ci95low - thresholdsPC, ci95high - thresholdsPC, ...
  'LineWidth', 1.25, 'LineStyle', 'none', 'Color', markerColor);

% Plot data markers (included in legend)
h_data = plot(baseContrastsPC, thresholdsPC, markerShape, ...
  'Color', markerColor, 'MarkerSize', markerSize, 'MarkerFaceColor', markerColor);

% Force axes to include origin and CIs
xlim([0, 50]);
ylim([0, max(ci95high)] * 1.05);

% Get current axis limits to extend fit lines
xlims = xlim();
ylims = ylim();
Xfit = [ones(100,1), linspace(xlims(1), xlims(2), 100)'];

% Fit lines
yfit_ols = Xfit * ols_beta;
yfit_wls = Xfit * wls_beta;

% Plot OLS and WLS lines, capturing handles
h_ols = plot(Xfit(:,2), yfit_ols, '-', 'Color', olsColor, 'LineWidth', lineWidth);

h_wls = plot(Xfit(:,2), yfit_wls, '-', 'Color', wlsColor, 'LineWidth', lineWidth);

% Draw origin lines (not in legend)
plot([0 0], ylim, 'k--', 'LineWidth', 1);
plot(xlim, [0 0], 'k--', 'LineWidth', 1);

% Legend — only the relevant handles
legend([h_data, h_ols, h_wls], ...
  {'Thresholds (95% CI)', 'Ordinary Fit', 'Weighted Fit'}, ...
  'FontSize', fontSize, 'Location', 'north');

% ---- Add OLS and WLS text boxes inside plot area ----
olsText = {
  sprintf('Ordinary: Y = %.2f + %.2f X', ols_beta(1), ols_beta(2))
  sprintf('Intercept 95%% CI:[%.2f, %.2f]', ci95_ols_intercept(1), ci95_ols_intercept(2))
  sprintf('t = %.2f, p = %.3f', t_ols, p_ols)
  };

wlsText = {
  sprintf('Weighted: Y = %.2f + %.2f X', wls_beta(1), wls_beta(2))
  sprintf('Intercept 95%% CI:[%.2f, %.2f]', ci95_wls_intercept(1), ci95_wls_intercept(2))
  sprintf('t = %.2f, p = %.3f', t_wls, p_wls)
  };

% Text X and Y locations (in data units)
x_ols = xlims(1) + 0.025 * range(xlims);
x_wls = xlims(1) + 0.025 * range(xlims);
y_ols = ylims(1) + 0.97 * range(ylims);
y_wls = ylims(1) + 0.82 * range(ylims);

% Plot OLS and WLS text
text(x_ols, y_ols, olsText, 'FontSize', fontSize, ...
  'BackgroundColor', 'w', 'EdgeColor', 'k', 'VerticalAlignment', 'top');
text(x_wls, y_wls, wlsText, 'FontSize', fontSize, ...
  'BackgroundColor', 'w', 'EdgeColor', 'k', 'VerticalAlignment', 'top');

end
