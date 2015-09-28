function varargout = D_tomoplangantryperiod(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Tomo Plan Gantry Period';
    return;
else
    stats = [];
    for i = 1:2:nargin
        if strcmp(varargin{i}, 'db')
            db = varargin{i+1};
        elseif strcmp(varargin{i}, 'stats')
            stats = varargin{i+1};
        elseif strcmp(varargin{i}, 'range')
            range = varargin{i+1};
        elseif strcmp(varargin{i}, 'nodatamsg')
            nodatamsg = varargin{i+1};
        end
    end
end

% Query TomoTherapy gantry period and date
data = db.queryColumns('tomo', 'period', 'where', 'tomo', 'plandate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = 10:2:60;

% Plot histogram of dates
d = histcounts(cell2mat(data(:,1)), e);
plot((e(1):0.01:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Gantry Period (sec)');
ylabel('Occurrence');
box on;
grid on;
xlim([10 60]);

PlotBackground('vertical', [15 20 60 60]);

columns = {
    'Dataset'
    'Show'
    'Mean'
    '< 20 sec'
    '>= 20 sec'
};

rows = cell(1,5);
rows{1,1} = 'Period';
rows{1,2} = true;
rows{1,3} = sprintf('%0.3f', mean(cell2mat(data(:,1))));
rows{1,4} = sprintf('%0.1f%%', sum(cell2mat(data(:,1)) < 20) / ...
    length(data(:,1))*100);
rows{1,5} = sprintf('%0.1f%%', sum(cell2mat(data(:,1)) >= 20) / ...
    length(data(:,1))*100);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;