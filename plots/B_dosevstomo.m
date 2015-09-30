function varargout = B_dosevstomo(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Dose vs. Tomo Parameters';
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
data = db.queryColumns('delta4', 'dosedev', 'delta4', 'measdate', ...
    'delta4', 'phantom', 'delta4', 'temperature', 'tomo', 'machine', 'tomo', 'doseperfx', ...
    'tomo', 'pitch', 'tomo', 'fieldwidth', 'tomo', 'period', 'tomo', ...
    'txtime', 'tomo', 'couchspeed', ...
    'where', 'delta4', 'measdate', range);

% Convert phantom column into numbers
phantoms = unique(data(:,3));
d = zeros(size(data,1),1);
for i = 1:length(phantoms)
    d = d + strcmp(data(:,3), phantoms{i}) * i;
end
data(:,3) = num2cell(d);

% Convert machine column into numbers
machines = unique(data(:,5));
d = zeros(size(data,1),1);
for i = 1:length(machines)
    d = d + strcmp(data(:,5), machines{i}) * i;
end
data(:,5) = num2cell(d);

% Convert to matrix
data = cell2mat(data);

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

vars = {
    'Date'
    'Phantom'
    'Temperature'
    'Machine'
    'Fx Dose'
    'Pitch'
    'Field Width'
    'Period'
    'Tx Time'
    'Couch Speed'
};

% Remove unselected parameters
for i = 1:length(vars)
    if size(rows,1) >= i && strcmp(rows{i,1}, vars{i}) && ...
            ~isempty(rows{i,2}) && ~rows{i,2}
        data(:,i+1) = zeros(size(data,1),1);
    end
end

% Perform N-way ANOVA
try
    [~, t, s] = anovan(data(:,1), data(:,2:end), ...
        'varnames', vars, 'continuous', [1 3 5 6 7 8 9 10], ...
        'display', 'off', 'model', 'linear');
    m = fitlm(data(:,2:end), data(:,1), 'quadratic', 'RobustOpts', ...
        'bisquare', 'PredictorVars', vars);
catch err
    Event(err.message, 'WARN');
    warndlg(err.message);
    return;
end

% Add show column
t = horzcat(t(:,1), cell(size(t,1),1), t(:,2:end));
for i = 2:size(t,1)
    if size(rows,1) >= i-1 && strcmp(rows{i-1,1}, t{i,1}) && ...
            ~isempty(rows{i-1,2}) && ~rows{i-1,2} && i-1 <= length(vars)
        t{i,2} = false;
    else
        t{i,2} = true;
    end
end
t{1,2} = 'Include';

% Plot linear model effects
subplot(2,2,[2,4]);
plotEffects(m);
set(gca, 'YTickLabels', m.PredictorNames);
box on;
grid on;
PlotBackground('vertical', [-10 -10 10 10]);

% Plot residuals
subplot(2,2,[1 2]);
plot(data(:,1), s.resid, '.', 'MarkerSize', 30);
ylabel('Residual');
xlabel('Dose Deviation (%)');
box on;
grid on;
PlotBackground('horizontal', [-3 -2 2 3]);

% Plot residual histogram
subplot(2,2,3);
[c, e] = histcounts(s.resid);
plot((e(1):0.01:e(end)), interp1(e(1:end-1), c, ...
    (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
ylabel('Occurrence');
xlabel('Residual');
box on;
grid on;
PlotBackground('vertical', [-3 -2 2 3]);

% Plot linear model effects
subplot(2,2,4);
plotEffects(m);
set(gca, 'YTickLabels', m.PredictorNames);
box on;
grid on;
PlotBackground('vertical', [-100 -100 100 100]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', t(2:end,:));
    set(stats, 'ColumnName', t(1,:));
end

% Clear temporary variables
clear data d e rows columns;