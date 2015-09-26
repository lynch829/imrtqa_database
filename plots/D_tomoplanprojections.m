function varargout = D_tomoplanprojections(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'TomoTherapy Plan Projections';
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
data = cell2mat(db.queryColumns('tomo', 'numprojections', 'where', 'tomo', ...
    'plandate', range));

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = 0:250:8000;

% Plot histogram of dates
d = histcounts(data(:,1), e);
plot((e(1):1:e(end)), interp1(e(1:end-1), d, ...
    (e(1):1:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Number of Projections');
ylabel('Occurrence');
box on;
grid on;
xlim([0 8000]);

PlotBackground('vertical', [0 0 10000 10000]);

columns = {
    'Dataset'
    'Show'
    'Mean'
    'Min'
    'Max'
};

rows = cell(1,5);
rows{1,1} = 'Projections';
rows{1,2} = true;
rows{1,3} = sprintf('%0.1f', mean(data(:,1)));
rows{1,4} = sprintf('%0.1f', min(data(:,1)));
rows{1,5} = sprintf('%0.1f', max(data(:,1)));

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;