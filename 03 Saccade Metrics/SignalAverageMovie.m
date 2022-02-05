% Demo to create a movie file demonstrating signal averaging
function SignalAverageMovie
  %==============================================================================================
  % Initialization code
  clc;
  workspace;
  hFigure = figure;
  set(hFigure, 'units', 'inches', 'position', [20, 5, 12, 9]);

  % Set up the movie structure.
  % Preallocate movie, which will be an array of structures.
  % Cell array with all the frames.
  nSpeedSteps = 6; % number of speed steps
  nSpeedFrames = 2^(nSpeedSteps - 1); % number of frames displayed for each sample increment
  totalFrames = 256 * nSpeedSteps;
  allTheFrames = cell(totalFrames, 1);
  vidHeight = 344;
  vidWidth = 446;
  allTheFrames(:) = {zeros(vidHeight, vidWidth, 3, 'uint8')};
  % Next get a cell array with all the colormaps.
  allTheColorMaps = cell(totalFrames, 1);
  allTheColorMaps(:) = {zeros(256, 3)};
  % Now combine these to make the array of structures.
  myMovie = struct('cdata', allTheFrames, 'colormap', allTheColorMaps);
  % Create a VideoWriter object to write the video out to a new, different file.
  % writerObj = VideoWriter('problem_3.avi');
  % open(writerObj);
  % Need to change from the default renderer to zbuffer to get it to work right.
  % openGL doesn't work and Painters is way too slow.
  set(gcf, 'renderer', 'zbuffer');

  %==============================================================================================
  % Create the movie.  
  noiseAmp = 5;
  width = 200;
  signal = zeros(1, width);
  sum = zeros(1, width);
  halfWidth = width / 2;
  signal(halfWidth - 10:halfWidth) = -1;
  signal(halfWidth + 1:halfWidth + 10) = 1;
  % After this loop starts, BE SURE NOT TO RESIZE THE WINDOW AS IT'S SHOWING THE FRAMES, or else you won't be able to save it.
  n = 0;
  frameCount = 0;
  frameDisplay = 1;
  [signalNoise, n, sum] = addTrace(signal, noiseAmp, width, n, sum);
  for frameIndex = 1:totalFrames
    cla reset;
    plot(signalNoise, 'color', [0.5, 0.5, 0.5], 'LineWidth', 1.5);
    hold on;
    plot(sum / n, 'b-', 'LineWidth', 2);
    axis('tight')
    caption = sprintf('n = %d', frameDisplay);
    text(0.05, 0.925, caption, 'units', 'normalized', 'FontSize', 32);
    axis([0, width, -noiseAmp * 0.75, noiseAmp * 0.75]);
    drawnow;
    thisFrame = getframe(gca);
    myMovie(frameIndex) = thisFrame;
    frameCount = frameCount + 1;
    if frameCount >= nSpeedFrames
      [signalNoise, n, sum] = addTrace(signal, noiseAmp, width, n, sum);
      frameCount = 0;
      frameDisplay = frameDisplay + 1;
    end
    if mod(frameIndex, 256) == 0
      nSpeedFrames = nSpeedFrames / 2;
    end
  end
  
  %==============================================================================================
  % See if they want to replay the movie.
  message = sprintf('Done creating movie\nDo you want to play it?');
  button = questdlg(message, 'Continue?', 'Yes', 'No', 'Yes');
  drawnow;	% Refresh screen to get rid of dialog box remnants.
  close(hFigure);
  if strcmpi(button, 'Yes')
    hFigure = figure;
    % set(gcf, 'Units', 'Normalized', 'Outerposition', [0, 0, 1, 1]); % full screen
    title('Playing the movie we created', 'FontSize', 15);
    % Get rid of extra set of axes that it makes for some reason.
    axis off;
    % Play the movie.
    movie(myMovie);
    close(hFigure);
  end
  
  %==============================================================================================
  % See if they want to save the movie to an avi file on disk.
  promptMessage = sprintf('Do you want to save this movie to disk?');
  titleBarCaption = 'Continue?';
  button = questdlg(promptMessage, titleBarCaption, 'Yes', 'No', 'Yes');
  if strcmpi(button, 'yes')
    % Get the name of the file that the user wants to save.
    % Note, if you're saving an image you can use imsave() instead of uiputfile().
  % 	startingFolder = pwd;
    defaultFileName = {'*.mp4';'*.avi';'*.mj2'}; %fullfile(startingFolder, '*.avi');
    [baseFileName, folder] = uiputfile(defaultFileName, 'Specify a file');
    if baseFileName == 0
	    return;		        % Cancel button.
    end
    fullFileName = fullfile(folder, baseFileName);
    % Create a video writer object with that file name.
    % The VideoWriter object must have a profile input argument, otherwise you get jpg.
    % Determine the format the user specified:
    [folder, ~, ext] = fileparts(fullFileName);
    switch lower(ext)
	    case '.jp2'
		    profile = 'Archival';
	    case '.mp4'
		    profile = 'MPEG-4';
	    otherwise
		    % Either avi or some other invalid extension.
		    profile = 'Uncompressed AVI';
    end
    writerObj = VideoWriter(fullFileName, profile);
    open(writerObj);
    % Write out all the frames.
    totalFrames = length(myMovie);
    for frameNumber = 1 : totalFrames 
       writeVideo(writerObj, myMovie(frameNumber));
    end
    close(writerObj);
    % Display the current folder panel so they can see their newly created file.
    cd(folder);
    filebrowser;
    message = sprintf('Finished creating movie file\n      %s.\n\nDone with demo!', fullFileName);
    uiwait(helpdlg(message));
  end
end

%%=============================================================================================

function [signalNoise, n, sum] = addTrace(signal, noiseAmp, width, n, sum)
  noise = rand(1, width) * noiseAmp - noiseAmp / 2;
  signalNoise = signal + noise;
  sum = sum + signalNoise;
  n = n + 1;
end


