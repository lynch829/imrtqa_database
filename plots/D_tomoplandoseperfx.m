function varargout = D_tomoplandoseperfx(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Tomo Plan Dose Per Fx';
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

% Query TomoTherapy doseperfx 
data = db.queryColumns('tomo', 'doseperfx', 'where', 'tomo', ...
    'plandate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = 0.5:1:20.5;

% Plot histogram of dates
d = histcounts(cell2mat(data(:,1)), e);
plot((e(1):0.01:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Dose Per Fraction (Gy)');
ylabel('Occurrence');
box on;
grid on;
xlim([1 20]);

PlotBackground('vertical', [1 1 20 20]);

columns = {
    'Dataset'
    'Show'
    'Mean'
    '(1,3]'
    '(3,20]'
};

rows = cell(1,5);
rows{1,1} = 'Dose per Fx';
rows{1,2} = true;
rows{1,3} = sprintf('%0.3f', mean(cell2mat(data(:,1))));
rows{1,4} = sprintf('%0.1f%%', (sum(cell2mat(data(:,1)) <= 3) - ...
    sum(cell2mat(data(:,1)) < 1)) / length(data(:,1))*100);
rows{1,5} = sprintf('%0.1f%%', sum(cell2mat(data(:,1)) > 3)...
     / length(data(:,1))*100);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;