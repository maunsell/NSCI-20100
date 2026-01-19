classdef RTStats < handle
  % MetricsAmpDur Handle saccade-duration data for EOG
  %   Accumulates and plots amplitude-duration relationships
  
  properties
    statsValid;
    tableData               % local data to load into GUI table
    tStat;
    minForStats = 3;
  end
  
  methods
    function obj = RTStats(app)      
      %% Object Initialization %%
      % Call superclass constructor before accessing object
      % You cannot conditionalize this statement
      %          obj = obj@handle(args{:});
      obj = obj@handle();
      
      %% Post Initialization %%
      s = uistyle('HorizontalAlignment', 'center');
      addStyle(app.statsTable, s, 'table', '');
      s = uistyle('FontWeight','bold');
      addStyle(app.statsTable, s, 'column', 1);
      clearAll(obj, app);
    end

    %% clearAll
    function clearAll(obj, app)
      obj.statsValid = false;
      obj.tStat = 0;
      obj.tableData = {'Gap', '0', '', '', '', ''; 'Step', '0', '', '', '', ''};      % contents of fit table
      app.statsTable.Data = obj.tableData;
    end
    
    %% doStats
    function doStats(obj, app)
      for type = app.kGapTrial:app.kStepTrial
        typeDist = app.rtDists{type};
        obj.tableData{type, 2} = typeDist.n;
        obj.tableData{type, 3} = '';
        obj.tableData{type, 4} = '';
        obj.tableData{type, 5} = '';
        obj.tableData{type, 6} = '';
        if typeDist.n >= 1
          obj.tableData{type, 3} = sprintf('%.0f', mean(typeDist.reactTimesMS(1:typeDist.n)));  % mean RT
          obj.tableData{type, 4} = sprintf('%.0f', std(typeDist.reactTimesMS(1:typeDist.n)));   % std for RT
          if typeDist.n >= 2
            obj.tableData{type, 5} = sprintf('%.1f', std(typeDist.reactTimesMS(1:typeDist.n)) / sqrt(typeDist.n));
          end
        end         
      end
      if obj.tableData{app.kGapTrial, 2} > obj.minForStats && obj.tableData{app.kStepTrial, 2} > obj.minForStats
        [~, pValue, ~, stats] = ttest2(app.rtDists{app.kGapTrial}.reactTimesMS(1:obj.tableData{app.kGapTrial, 2}), ...
                             app.rtDists{app.kStepTrial}.reactTimesMS(1:obj.tableData{app.kStepTrial, 2}), ...
                            'Tail', 'both');
        obj.tStat = stats.tstat;
        if pValue >= 1e-3
          form = '%.3f';
        else
          form = '%.1e';
        end
        obj.tableData{app.kGapTrial, 6} = sprintf(form, pValue);
        obj.statsValid = true;
      end
      app.statsTable.Data = obj.tableData;
      obj.statsValid = true;
    end

    %% writestatsData
    % return a cell array suitable for creating an Excel spreadsheet reporting the ampDur statistics
    function writeStatsData(obj, app, timeString)
      if ~obj.statsValid
        return;
      end
      if nargin < 3
        timeString = string(datetime('now', 'Format', 'MMM-dd-HHmmss'));
      end
      fPath = [dataRoot(), '/RTData/Stats'];
      if ~isfolder(fPath)
        mkdir(fPath);
      end
      filePath = fullfile(fPath, "RT-" + timeString + ".xlsx");

      statsData = cell(3, 8);
      statsData(1, 1:8) = {' ', 'n', 'Mean', 'SD', 'SEM', 'p', 't statistic', 'Calibration'};
      statsData(2:3, 1:6) = obj.tableData(1:2, 1:6);
      statsData{2, 7} = sprintf('%.2f', obj.tStat);
      statsData{2, 8} = sprintf('%.1f deg/V', app.saccades.degPerV);
      writecell(statsData, filePath, 'writeMode', 'replacefile', 'autoFitWidth', 1);
      backupFile(filePath);     % save backup in repository directory
    end
  end
end

