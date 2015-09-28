function varargout = F_linacnumcps(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Linac Number of Control Points';
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

% Query linac number of beams and control points
data = cell2mat(db.queryColumns('linac', 'numcps', 'linac', 'numbeams', ...
    'where', 'linac', 'plandate', range));

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = 50:10:200;

% Plot histogram of dates
d = histcounts(data(:,1)./data(:,2), e);
plot((e(1):0.1:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.1:e(end)), 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Number of Control Points per Beam/Arc');
ylabel('Occurrence');
box on;
grid on;

PlotBackground('vertical', [50 50 200 200]);

columns = {
    'Dataset'
    'Show'
    'Mean'
};

rows = cell(1,3);
rows{1,1} = 'Num CPs per Beam/Arc';
rows{1,2} = true;
rows{1,3} = sprintf('%0.3f', mean(data(:,1)./data(:,2)));

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;