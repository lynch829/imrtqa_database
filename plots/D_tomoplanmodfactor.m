function varargout = D_tomoplanmodfactor(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'TomoTherapy Plan Mod Factor';
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

% Query TomoTherapy gantry mode and date
data = db.queryColumns('tomo', 'planmod', ...
    'where', 'tomo', 'plandate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = 1:0.25:5;

% Plot histogram of dates
d = histcounts(cell2mat(data(:,1)), e);
plot((e(1):0.001:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.001:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Plan Modulation Factor');
ylabel('Occurrence');
box on;
grid on;

PlotBackground('vertical', [1.5 1.8 3 4]);

columns = {
    'Dataset'
    'Show'
    'Mean'
    '(1,2]'
    '(2,3]'
    '(3,4]'
    '(4,5]'
};

rows = cell(1,7);
rows{1,1} = 'Mod Factor';
rows{1,2} = true;
rows{1,3} = sprintf('%0.3f', mean(cell2mat(data(:,1))));
rows{1,4} = sprintf('%0.1f%%', (sum(cell2mat(data(:,1)) <= 2) - ...
    sum(cell2mat(data(:,1)) < 1)) / length(data(:,1))*100);
rows{1,5} = sprintf('%0.1f%%', (sum(cell2mat(data(:,1)) <= 3) - ...
    sum(cell2mat(data(:,1)) < 2)) / length(data(:,1))*100);
rows{1,6} = sprintf('%0.1f%%', (sum(cell2mat(data(:,1)) <= 4) - ...
    sum(cell2mat(data(:,1)) < 3)) / length(data(:,1))*100);
rows{1,7} = sprintf('%0.1f%%', (sum(cell2mat(data(:,1)) <= 5) - ...
    sum(cell2mat(data(:,1)) < 4)) / length(data(:,1))*100);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;