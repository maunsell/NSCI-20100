classdef MetricsFits < handle
  % MetricsAmpDur Handle saccade-duration data for EOG
  %   Accumulates and plots amplitude-duration relationships
  
  properties
    fitData
    fitsValid = false;
    tableData
    statsData
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
      app.fitTable.ColumnName = {'Fit Value'; 'Intercept'; sprintf('r%c', 178); 'Res. Sum Sq.'};
      app.fitTable.RowName = {'Speed'; 'Accel.'};

      s = uistyle('HorizontalAlignment','center');
      addStyle(app.fitTable, s, 'table', '');
      addStyle(app.statsTable, s, 'table', '');
      clearAll(obj, app);
    end

    %% doFits
    function doFits(obj, app)
      if min(app.ampDur.n) < obj.minForFit
        return;
      end
      x = abs(app.offsetsDeg);
      y = app.medians;

      p = polyfit([x, -x], [y, -y], 1);
      speedSlope = 1000.0 / p(1);
      speedIntercept = p(2);
      speedSS = sum(([y, -y] - polyval(p, [x, -x])).^2);
      totalSS = (length([y, -y]) - 1) * var([y, -y]);
      speedR2 = 1 - speedSS / totalSS;
      obj.tableData{1, 1} = sprintf('%.0f%c/s', speedSlope, 176);
      obj.tableData{1, 2} = sprintf('%.0f ms', speedIntercept);
      obj.tableData{1, 3} = sprintf('%.2f', speedR2);
      obj.tableData{1, 4} = sprintf('%.0f', speedSS);

      p = polyfit([x, -x], [y.^2, -(y.^2)], 1);
      accSlope = 4 / p(1) * 1000000;
      accIntercept = sqrt(p(2));
      accSS = sum((sqrt(abs([y.^2, -(y.^2)])) - sqrt(abs(polyval(p, [x, -x])))).^2);
      accR2 = 1 - accSS/ totalSS;
      obj.tableData{2, 1} = sprintf('%.0f%c/s%c', accSlope, 176, 178);
      obj.tableData{2, 2} = sprintf('%.0f ms', accIntercept);
      obj.tableData{2, 3} = sprintf('%.2f', accR2);
      obj.tableData{2, 4} = sprintf('%.0f', accSS);
      app.fitTable.Data = obj.tableData;

      F = accSS / speedSS;
      df = app.numOffsets - 1;
      prob = 1.0 - fcdf(F, df, df);
      obj.statsData = cell(1, 2);
      obj.statsData{1} = sprintf('%.2f', F);
      obj.statsData{2} = sprintf('%.2g', prob);
      set(app.statsTable, 'Data', obj.statsData);
      
      % load table values
      for row = 2:3
      obj.fitData{2, 1} = 'Speed';
      obj.fitData{3, 1} = 'Accel.';
        for col = 2:5
            obj.fitData{row, col} = obj.tableData{row - 1, col - 1};
        end
      end
      obj.fitData{2, 6} = obj.statsData{1};
      obj.fitData{2, 7} = obj.statsData{2};
      obj.fitsValid = true;
      app.ampDur.accFit = accSlope;
      app.ampDur.speedFit = speedSlope;
    end

    %% clearAll
    function clearAll(obj, app)
      obj.fitsValid = false;
      obj.fitData = cell(3, 7);
      [obj.fitData{1, :}] = deal(' ', 'Fit Value', 'Intercept', 'r^2', 'Sum Squares', 'F', 'p');
      obj.tableData = {'', '', '', ''; '', '', '', ''};      % contents of fit table
      app.fitTable.Data = obj.tableData;
      % set(app.fitTable, 'Data', obj.tableData);
      obj.statsData = {'', ''};
      app.statsTable.Data = obj.statsData;
      % set(app.statsTable, 'Data', obj.statsData);
      app.ampDur.accFit = -1;
      app.ampDur.speedFit = -1;
    end
    
    %% writeFitData
    % return a cell array suitable for creating an Excel spreadsheet reporting the ampDur statistics
    function writeFitData(obj, app, timeString)
      if ~obj.fitsValid
          fprintf('writeFitData -- not writing because fit is not valid\n');
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
      fprintf('writeFitData -- writing fit %s\n', filePath);
      writecell(obj.fitData, filePath, 'writeMode', 'replacefile', 'autoFitWidth', 1);
      backupFile(filePath, '~/Desktop', '~/Documents/Respository');     % save backup in repository directory
    end
  end
end

