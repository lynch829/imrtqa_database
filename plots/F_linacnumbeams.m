function varargout = F_linacnumbeams(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Linac Number of Beams/Arcs';
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

% Query linac number of beams
data = cell2mat(db.queryColumns('linac', 'numbeams', 'where', 'linac', ...
    'plandate', range));

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = 1:max(data(:,1));

% Plot histogram of dates
d = histcounts(data(:,1), e);
plot((e(1):0.01:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.01:e(end)), 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Number of Beams/Arcs');
ylabel('Occurrence');
box on;
grid on;

PlotBackground('vertical', [1 1 3 5]);

columns = {
    'Dataset'
    'Show'
    'Mean'
    '1-2'
    '3-5'
    '>5'
};

rows = cell(1,6);
rows{1,1} = 'Num Beams';
rows{1,2} = true;
rows{1,3} = sprintf('%0.3f', mean(data(:,1)));
rows{1,4} = sprintf('%0.1f%%', sum(data(:,1) <= 2) / length(data(:,1))*100);
rows{1,5} = sprintf('%0.1f%%', (sum(data(:,1) <= 5) - sum(data(:,1) <= 2)) / ...
    length(data(:,1))*100);
rows{1,6} = sprintf('%0.1f%%', sum(data(:,1) > 5) / length(data(:,1))*100);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;