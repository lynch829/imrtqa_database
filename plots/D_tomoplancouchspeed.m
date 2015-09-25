function varargout = D_tomoplancouchspeed(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'TomoTherapy Plan Couch Speed';
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

% Query TomoTherapy couch speed and date
data = cell2mat(db.queryColumns('tomo', 'couchspeed', 'where', 'tomo', ...
    'plandate', range));

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = 0:0.01:0.5;

% Plot histogram of speeds
d = histcounts(data(:,1), e);
plot((e(1):0.001:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.001:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Couch Speed (cm/sec)');
ylabel('Occurrence');
box on;
grid on;

PlotBackground('vertical', [0 0 0.5 0.5]);

columns = {
    'Dataset'
    'Show'
    'Mean'
};

rows = cell(1,3);
rows{1,1} = 'Couch Speed';
rows{1,2} = true;
rows{1,3} = sprintf('%0.3f', mean(data(:,1)));

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;