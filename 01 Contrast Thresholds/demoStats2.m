function demoStats2()

numA = 100;
aOffset = 0.25;
aFactor = 1.5;
numB = 100;
bOffset = 1.25;
bFactor = 1.25;

a1 = randn(numA, 1) + aOffset;
a2 = randn(numA, 1) + aOffset * aFactor;
b1 = randn(numB, 1) + bOffset;
b2 = randn(numB, 1) + bOffset * bFactor;

[~, pA] = ttest(a1, a2);
[~, pB] = ttest(b1, b2);

semA1 = std(a1) / sqrt(numA);
semA2 = std(a2) / sqrt(numA);
semB1 = std(b1) / sqrt(numB);
semB2 = std(b2) / sqrt(numB);

diff = bOffset / aOffset;
fprintf('A: Means %.1f %.1f, SEM %.2f %.2f, p = %f\n', mean(a1), mean(a2), semA1, semA2, pA);
fprintf('A*: Means %.1f %.1f, SEM %.2f %.2f, p = %f\n', mean(a1) * diff, mean(a2) * diff, semA1 * diff, semA2 * diff, pA);
fprintf('B: Means %.1f %.1f, SEM %.2f %.2f, p = %f\n', mean(b1), mean(b2), semB1, semB2, pB);
end