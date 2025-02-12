classdef MetricsFits < handle
  % MetricsAmpDur Handle saccade-duration data for EOG
  %   Accumulates and plots amplitude-duration relationships
  
  properties
    fitData
    fitsValid = false;
    tableData               % local data to load into GUI table
    minForFit = 3;
  end
  
  methods
    function obj = MetricsFits(app)      
      %% Object Initialization %%
      % Call superclass constructor before accessing object
      % You cannot conditionalize this statement
      %          obj = obj@handle(args{:});
      obj = obj@handle();
      
      %% Post Initialization %%
      app.fitTable.ColumnName = {'Fit Value'; 'Intercept'; sprintf('r%c', 178); 'p'; 'F'};
      app.fitTable.RowName = {'Speed'; 'Accel.'};

      s = uistyle('HorizontalAlignment', 'center');
      addStyle(app.fitTable, s, 'table', '');
      clearAll(obj, app);
    end

    %% doFits
    function doFits(obj, app)
      if min(app.ampDur.n) < obj.minForFit
        return;
      end
      x = abs(app.offsetsDeg);
      y = app.medians;
      TSS = (length(y) - 1) * var(y);

      % fit to speed
      p = polyfit([x, -x], [y, -y], 1);           % to force intercept of 0
      speedSlope = 1000.0 / p(1);
      speedIntercept = p(2);
      speedSSR = sum((y - polyval(p, x)).^2);
      speedR2 = 1 - speedSSR / TSS;
      if speedR2 < 0
          fprintf('\nnegative R2\n')
          fprintf('speedSSR %.1f, TSS %.1f R2 %.2f', speedSSR, TSS, speedR2);
          fprintf('mean y: %.1f\n', mean(y))
          fprintf('y values: %.1f  %.1f  %.1f  %.1f  %.1f  %.1f  %.1f  %.1f  %.1f %.1f\n\n', y)
      end
      obj.tableData{1, 1} = sprintf('%.0f%c/s', speedSlope, 176);
      obj.tableData{1, 2} = sprintf('%.0f ms', speedIntercept);
      obj.tableData{1, 3} = sprintf('%.2f', speedR2);

      % fit to acceleration
      p = polyfit([x, -x], [y.^2, -(y.^2)], 1);
      accSlope = 4 / p(1) * 1000000;          % convert from deg/ms^2 to deg/s^2 and acc to acc/dec
      accIntercept = sqrt(p(2));
      accSSR = sum((y - sqrt(abs(polyval(p, x)))).^2);
      accR2 = 1 - accSSR / TSS;
      obj.tableData{2, 1} = sprintf('%.0f%c/s%c', accSlope, 176, 178);
      obj.tableData{2, 2} = sprintf('%.0f ms', accIntercept);
      obj.tableData{2, 3} = sprintf('%.2f', accR2);

      F = accSSR / speedSSR;
      df = app.numOffsets - 1;
      prob = fcdf(F, df, df);               % one-tailed test
      if prob >= 0.01
        formats = {'%.3f', '%.2f'};
      elseif prob >= 0.001
        formats = {'%.4f', '%.2f'};
      else
        formats = {'%.1e', '%.2f'};
      end
      obj.tableData{2, 4} = sprintf(formats{1}, prob);          % acceleration p-value
      obj.tableData{2, 5} = sprintf('%.3f', F);                 % acceleration F-statistic
      
      % load output table values
      app.fitTable.Data = obj.tableData;        % transfer local table to GUI
      obj.fitData{2, 1} = 'Speed';              % add row names to export table
      obj.fitData{3, 1} = 'Accel.';      
      for row = 2:3                             
        for col = 2:5
            obj.fitData{row, col} = obj.tableData{row - 1, col - 1};
        end
      end
      obj.fitData{2, 6} = sprintf('%.1f', speedSSR);
      obj.fitData{3, 6} = sprintf('%.1f', accSSR);
      obj.fitData{3, 7} = obj.tableData{2, 5};                  % F statistic
      obj.fitData{2, 8} = sprintf('%.1f mV/deg', 1000 / app.saccades.degPerV);    % eye calibration (mv/deg)
      obj.fitsValid = true;
      app.ampDur.accFit = accSlope;
      app.ampDur.speedFit = speedSlope;
    end

    %% clearAll
    function clearAll(obj, app)
      obj.fitsValid = false;
      obj.fitData = cell(3, 8);
      [obj.fitData{1, :}] = deal(' ', 'Fit Value', 'Intercept', 'r^2', 'p', 'Sum Squares', 'F', 'Calibration');
      obj.tableData = {'', '', '', '', ''; '', '', '', '', ''};      % contents of fit table
      app.fitTable.Data = obj.tableData;
      app.ampDur.accFit = -1;
      app.ampDur.speedFit = -1;
    end
    
    %% writeFitData
    % return a cell array suitable for creating an Excel spreadsheet reporting the ampDur statistics
    function writeFitData(obj, app, timeString)
      if ~obj.fitsValid
          % fprintf('writeFitData -- not writing because fit is not valid\n');
        return;
      end
      if nargin < 3
        timeString = string(datetime('now', 'Format', 'MMM-dd-HHmmss'));
      end
      fPath = [app.folderPath, 'Fits'];
      if ~isfolder(fPath)
        mkdir(fPath);
      end
      filePath = fullfile(fPath, ['MT-', timeString, '.xlsx']);
      writecell(obj.fitData, filePath, 'writeMode', 'replacefile', 'autoFitWidth', 1);
      backupFile(filePath, '~/Desktop', '~/Documents/Respository');     % save backup in repository directory
    end
  end
end

