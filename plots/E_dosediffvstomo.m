function varargout = E_dosediffvstomo(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Dose Diff vs. Tomo Plan Parameters';
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

% Query Delta4 dose difference/date and TomoTherapy plan parameters
data = cell2mat(db.queryColumns('delta4', 'dosedev', 'delta4', 'measdate', ...
    'tomo', 'doseperfx', 'tomo', 'pitch', 'tomo', 'fieldwidth', 'tomo', ...
    'period', 'tomo', 'txtime', 'tomo', 'couchspeed', ...
    'where', 'delta4', 'measdate', range));

% Remove columns with NaN
data = data(~any(isnan(data),2),:);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Fit linear model to data
try
    m = fitlm(data(:,2:end), data(:,1), 'interactions', 'RobustOpts', ...
        'bisquare');
catch err
    Event(err.message, 'WARN');
    warndlg(err.message);
    return;
end

% Define columns
columns = {
    'Predictor'
    'Show'
    'N'
    'R^2'
    'Slope'
    'P-Value'
};

% Define rows
rows = cell(6, size('data', 2)-1);
rows{:,1} = {
    'Measured Date'
    'Fraction Dose'
    'Pitch'
    'Field Width'
};

% Plot residuals data
for i = 2:size('data', 2)
    
end

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;