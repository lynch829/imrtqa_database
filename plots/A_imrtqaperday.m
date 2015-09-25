function varargout = A_imrtqaperday(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'IMRT QA per Day';
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

% Query measured dates for Delta4 records
data = cell2mat(db.queryColumns('delta4', 'measdate'));

% Remove dates outside of range range
data = data(data > range(1));
data = data(data < range(2));

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Plot histogram of dates
c = histcounts(data, floor(range(1)):ceil(range(2)));
c(c == 0) = [];
[d, e] = histcounts(c, 0:max(c));
plot((0:0.01:e(end)), interp1(e(1:end-1), d, ...
    0:0.01:e(end), 'nearest', 'extrap'), 'LineWidth', 2);
xlabel('Number of IMRT QA plans per day');
ylabel('Occurrence');
box on;
grid on;

% Add colored background
PlotBackground('vertical', [0 0 5 10]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', {});
    set(stats, 'ColumnName', {});
end

% Clear temporary variables
clear data c d e p;