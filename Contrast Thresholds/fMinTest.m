function fMinTest

fun = @(params, xData) 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData - params(1))));
xData = [0.0600    0.0638    0.0675    0.0750    0.0900    0.1200];
yData = [0.5000    0.5000    0.7500    0.7500    1.0000    1.0000];
x0 = [0.0675 5.0000];
OLS = @(params) sum((fun(params, xData) - yData).^2);
opts = optimset('Display', 'on', 'MaxFunEvals', 10000, 'MaxIter', 2500);
params = fminsearch(OLS, x0)
end
