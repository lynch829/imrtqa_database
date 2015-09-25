function varargout = C_absolutedosepassrate(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Absolute Dose Pass Rate';
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

% Query phantom temperature
data = db.queryColumns('delta4', 'abspassrate', 'delta4', 'measdate');

% Remove dates outside of range range
data = data(cell2mat(data(:,2)) > range(1), 1:2);
data = data(cell2mat(data(:,2)) < range(2), 1:2);

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Plot histogram of dates
[d, e] = histcounts(cell2mat(data(:,1)));
plot((e(1):0.01:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Absolute Dose Criterion Pass Rate (%)');
ylabel('Occurrence');
box on;
grid on;

% Add colored background
PlotBackground('vertical', [0 0 100 100]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', {});
    set(stats, 'ColumnName', {});
end

% Clear temporary variables
clear data d e;