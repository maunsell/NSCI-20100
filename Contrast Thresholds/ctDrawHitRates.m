
function handles = ctDrawHitRates(handles)
    baseIndex = get(handles.baseContrastMenu, 'value');
    x = handles.data.baseContrasts' * handles.data.multipliers;
    hitRate = zeros(size(handles.data.trialsDone));
    errNeg = zeros(size(handles.data.trialsDone));
    errPos = zeros(size(handles.data.trialsDone));
    pci = zeros(size(handles.data.trialsDone, 1), size(handles.data.trialsDone, 2), 2);
    for i = 1:(size(handles.data.trialsDone, 1)) 
        [hitRate(i,:), pci(i,:,:)] = binofit(handles.data.hits(i, :), handles.data.trialsDone(i, :));
        errNeg(i, :) = hitRate(i, :) - pci(i, :, 1);
        errPos(i, :) = pci(i, :, 2) - hitRate(i, :);
        % If we have enough blocks, fit a logistic functions.  Include 0.5
        % performance at base contrast
        if i == baseIndex
            blocksDone = floor(mean(handles.data.trialsDone(i, :)));
            tableData = get(handles.resultsTable,'Data');
            tableData{1, i} = sprintf('%.0f', blocksDone);
            if blocksDone > handles.data.blocksFit(i) && blocksDone > 5 
                xData = [handles.data.baseContrasts(i) (handles.data.baseContrasts(i) * handles.data.multipliers)];
                yData = [0.5 hitRate(i,:)];
                x0 = [xData(ceil(length(xData) / 2)); 5];
                lowBounds = [handles.data.baseContrasts(i); 1];
                highBounds = [5; 1000];
                fun=@(params, xData) 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData - params(1))));
                options = optimset('Display', 'off');
                [params, ~] = lsqcurvefit(fun, x0, xData, yData, lowBounds, highBounds, options);
                handles.data.curveFits(i, :) = 0.5 + 0.5 ./ (1.0 + exp(-params(2) * (xData(2:end) - params(1))));
                handles.data.blocksFit(i) = blocksDone;
                tableData{2, i} = sprintf('%.1f%%', params(1) * 100.0);
                tableData{3, i} = sprintf('%.1f%%', (params(1) - handles.data.baseContrasts(i)) * 100.0);
                tableData{4, i} = sprintf('%.2f', (params(1) / handles.data.baseContrasts(i)));
            end
            set(handles.resultsTable, 'Data', tableData); 
        end
    end
    errorbar(x', hitRate', errNeg', errPos', 'o');
    hold on;
    plot(x', handles.data.curveFits', '-');
    plot(repmat(handles.data.baseContrasts, 2, 1), repmat([0; 1], 1, 4));
    axis([0.05, 1.0, 0.0 1.0]);
    set (handles.axes1, 'xGrid', 'on', 'yGrid', 'off');
    set(handles.axes1, 'yTick', [0.0; 0.2; 0.4; 0.6; 0.8; 1.0]);
    set(handles.axes1, 'yTickLabel', [0; 20; 40; 60; 80; 100]);
    set(handles.axes1, 'xTick', [0.05; 0.06; 0.07; 0.08; 0.09; 0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.8; 1.0]);
    set(handles.axes1, 'xTickLabel', [5; 6; 7; 8; 9; 10; 20; 30; 40; 50; 60; 80; 100]);
    set(handles.axes1,'xscale','log');
    xlabel(handles.axes1, 'stimulus contrast', 'fontSize', 14);
    ylabel(handles.axes1, 'percent correct', 'fontSize', 14);
    hold off;
end