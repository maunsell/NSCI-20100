function testFigure

    clc;                                % Clear the command window.
    close all;                          % Close all figures (except those of imtool.)
    imtool close all;                   % Close all imtool figures if you have the Image Processing Toolbox.
    clear;                              % Erase all existing variables. Or clearvars if you want.

    screenRect = get(0, 'MonitorPositions');
    offsetPix = 10;
    windowHeightPix = 60;                      % must be at least this 44 for 'tight' borders to work
    windowWidthPix = screenRect(3) - 2 * offsetPix;
    spotRadiusPix = 10;
    stepPix = windowWidthPix / 10 / 2;
    rawSteps = floor(windowWidthPix / stepPix);
    steps = rawSteps - (mod(rawSteps, 2) == 0);                 % force an odd number of steps
    stepOffsetPix = (-floor(steps / 2):floor(steps / 2)) * stepPix + floor(windowWidthPix / 2 - stepPix / 2);

    hFig = figure('Renderer', 'painters', 'Position', [offsetPix, offsetPix, windowWidthPix, windowHeightPix]);
    set(hFig, 'menubar', 'none', 'toolbar', 'none', 'NumberTitle', 'off', 'resize', 'off');
    set(hFig, 'color', [0.5, 0.5, 0.5]);
    set(hFig, 'Name', 'NSCI 20100 Saccadic Reaction Time', 'NumberTitle', 'Off');
    axis off;
    hold on;
    % restore the window position if it has moved
    t = get(hFig, 'Position');
    if t(1) ~= offsetPix || t(2) ~= offsetPix
        set(hFig, 'Position', [offsetPix, offsetPix, windowWidthPix, windowHeightPix]);
    end
    % create the image and get drawing axes
%     fpos = get(hFig, 'position');
%     axOffset = (fpos(3:4) - [size(circleImg, 2) size(circleImg, 1)]) / 2;
%     make some images the same size as the window
%      windowMat = ones(windowHeightPix, stepPix) * 255;
%     [windowImage, ~] = gray2ind(windowMat, 2);
    images = makeSpotImages(stepPix, spotRadiusPix);
    % draw the images
    ha = axes('Parent', hFig, 'units', 'pixels', 'position',...
                        [0, windowHeightPix / 2 - spotRadiusPix, stepPix * 2, spotRadiusPix * 2], 'visible', 'off');
    tocVector = zeros(1, steps);
    for pos = 1:steps
        tocVector(pos) = showImage(ha, images{mod(pos, 4) + 1}, stepOffsetPix(pos));
    end
	fprintf('latency mean %f std %f min %f max %f\n', mean(tocVector), std(tocVector), min(tocVector), max(tocVector));
	tocVector = zeros(1, 10000);
    tCounter = 1;
    longPauseS = 0.5;
    shortPauseS = 0.2;
    for rep = 1:5
        tocVector(tCounter) = showImage(ha, images{2}, stepOffsetPix(5));
        tCounter = tCounter + 1;
        pause(longPauseS);
        tocVector(tCounter) = showImage(ha, images{3}, stepOffsetPix(5));
        tCounter = tCounter + 1;
        pause(longPauseS);
    end
	for rep = 1:5
        tocVector(tCounter) = showImage(ha, images{2}, stepOffsetPix(8));
     	tCounter = tCounter + 1;
        pause(longPauseS);
        tocVector(tCounter) = showImage(ha, images{1}, stepOffsetPix(8));
     	tCounter = tCounter + 1;
        pause(shortPauseS);
        tocVector(tCounter) = showImage(ha, images{3}, stepOffsetPix(8));
     	tCounter = tCounter + 1;
        pause(longPauseS);
        tocVector(tCounter) = showImage(ha, images{1}, stepOffsetPix(8));
     	tCounter = tCounter + 1;
        pause(shortPauseS);
   end
	for rep = 1:5
        tocVector(tCounter) = showImage(ha, images{2}, stepOffsetPix(11));
     	tCounter = tCounter + 1;
        pause(longPauseS);
        tocVector(tCounter) = showImage(ha, images{4}, stepOffsetPix(11));
     	tCounter = tCounter + 1;
        pause(shortPauseS);
        tocVector(tCounter) = showImage(ha, images{3}, stepOffsetPix(11));
     	tCounter = tCounter + 1;
        pause(longPauseS);
        tocVector(tCounter) = showImage(ha, images{4}, stepOffsetPix(11));
     	tCounter = tCounter + 1;
        pause(shortPauseS);
    end
    tocVector = tocVector(1:tCounter - 1);
	fprintf('latency mean %f std %f min %f max %f\n', mean(tocVector), std(tocVector), min(tocVector), max(tocVector));
end

%%
function tocResult = showImage(ha, theImage, xOffset)
    
    tic
    ha.Position(1) = xOffset;
    imshow(theImage, [0.5, 0.5, 0.5; 1.0, 1.0, 1.0], 'parent', ha);
    drawnow;
    tocResult = toc;    
end

%%
    
% Create a logical image of a circle with specified
% diameter, center, and image size.
% First create the image.
function [images] = makeSpotImages(stepPix, radiusPix)
    % make a circleImage
    diameterPix = radiusPix * 2;
    circlePix = 1:diameterPix;
    [imgCols, imgRows] = meshgrid(circlePix, circlePix);
    circlePixels = (imgRows - radiusPix).^2 + (imgCols - radiusPix).^2 <= radiusPix^2;
%     grayMat = ones(diameterPix, 'uint8') * foreColor;   % matrix for circle
%     grayMat(circlePixels == 0) = backColor;             % load back color
    [circleImg, ~] = gray2ind(circlePixels, 2);         % make an image from the circle matrix
    % make the background rectangle
    imageSet = zeros(4, diameterPix, stepPix * 2, 'uint8');   % images will be the height of the circle
    leftCenterPix = floor(0.5 * stepPix);               % image is 2 * stepPix so circles are at 0.5 and 1.5 stepPix
    rightCenterPix = floor(1.5 * stepPix);
    heightCenterPix = floor(diameterPix / 2);
    pRange = circlePix - radiusPix;
    images = cell(1, 4);
    for i = 1:4                                         % four images, one for each possible mix of dot/no-dot
        index = i - 1;
        if mod(index, 2) == 1                         	% needs a right hand dot
            imageSet(i, heightCenterPix + pRange, rightCenterPix + pRange) = circleImg(circlePix, circlePix);
        end
        if index >= 2                                   % needs a left hand dot
            imageSet(i, heightCenterPix + pRange, leftCenterPix + pRange) = circleImg(circlePix, circlePix);
        end
        images{i} = squeeze(imageSet(i, :, :));         % save the image in a cell array
    end
end
