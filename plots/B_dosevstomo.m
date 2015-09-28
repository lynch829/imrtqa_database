function varargout = B_dosevstomo(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Dose vs. Tomo Plan Parameters';
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

% If a valid filter was provided, store its current contents
if ~isempty(stats)
    rows = get(stats, 'Data');
end

% Query Delta4 dose difference/date and TomoTherapy plan parameters
data = cell2mat(db.queryColumns('delta4', 'dosedev', 'delta4', 'measdate', ...
    'delta4', 'temperature', 'tomo', 'doseperfx', 'tomo', 'pitch', 'tomo', ...
    'fieldwidth', 'tomo', 'period', 'tomo', 'txtime', 'tomo', 'couchspeed', ...
    'where', 'delta4', 'measdate', range));

% Remove columns with NaN
data = data(~any(isnan(data),2),:);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% If the rows column is the same size, loop through to see if any variables
% should be excluded from analysis
if size(rows, 1) == size(data, 2)-1
    for i = 1:size(data, 2)-1
        if ~rows{i,2}
            data(:,i+1) = zeros(size(data, 1), 1);
        end
    end
end

% Fit linear model to data
try
    m = fitlm(data(:,2:end), data(:,1), 'linear', 'RobustOpts', ...
        'bisquare');
catch err
    Event(err.message, 'WARN');
    warndlg(err.message);
    return;
end

% Define columns
columns = {
    'Predictor'
    'Include'
    'N'
    'R^2'
    'Slope'
    'SE'
    'T-Stat'
    'P-Value'
};

% Create new rows array
rows = cell(size(data,2)-1, 8);
rows(:,1) = {'Measured Date'
    'Phantom Temp'
    'Fraction Dose'
    'Pitch'
    'Field Width'
    'Gantry Period'
    'Treatment Time'
    'Couch Speed'
};

% Plot residuals data
plot(data(:,1), m.Residuals.Standardized, '.', 'MarkerSize', 30);
ylabel('Standardized Residual');
xlabel('Dose Deviation (%)');
box on;
grid on;

% Add colored background
PlotBackground('vertical', [-3 -2 2 3]);

% Report regression statistics
for i = 1:size(data, 2)-1
    if any(data(:,i+1))
        rows{i,2} = true;
    else
        rows{i,2} = false;
    end
    rows{i,3} = sprintf('%i', m.NumObservations);
    if ~isnan(m.Coefficients{i+1,4})
        rows{i,4} = sprintf('%0.3f', m.Rsquared.Ordinary);
        rows{i,5} = sprintf('%0.3f', m.Coefficients{i+1,1});
        rows{i,6} = sprintf('%0.3f', m.Coefficients{i+1,2});
        rows{i,7} = sprintf('%0.3f', m.Coefficients{i+1,3});
        rows{i,8} = sprintf('%0.3f', m.Coefficients{i+1,4});
    else
        rows{i,4} = '';
        rows{i,5} = '';
        rows{i,6} = '';
        rows{i,7} = '';
        rows{i,8} = '';
    end
end

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e rows columns;