function varargout = C_phantomtemperature(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Phantom Temperature';
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

% Query phantom temperature, dose diff, and pass rate
data = cell2mat(db.queryColumns('delta4', 'temperature', 'delta4', 'dosedev', ...
    'delta4', 'gammapassrate', 'where', 'delta4', 'measdate', range));

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Plot histogram of dates
subplot(2,2,1);
[d, e] = histcounts(data(:,1));
plot((e(1):0.01:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('Phantom Temperature (C)');
ylabel('Occurrence');
box on;
grid on;
PlotBackground('vertical', [21 22 25 26]);

% Plot dose diff as a function of temperature
subplot(2,2,2);
plot(data(:,1), data(:,2), '.', 'MarkerSize', 30);
xlabel('Phantom Temperature (C)');
ylabel('Dose Difference (%)');
box on;
grid on;
PlotBackground('vertical', [21 22 25 26]);

% Plot gamma pass rate as a function of temperature
subplot(2,2,3);
plot(data(:,1), data(:,3), '.', 'MarkerSize', 30);
xlabel('Phantom Temperature (C)');
ylabel('Gamma Pass Rate (%)');
box on;
grid on;
PlotBackground('vertical', [21 22 25 26]);

% Define columns
columns = {
    'Response'
    'Show'
    'N'
    'R^2'
    'Slope'
    'SE'
    'T-Stat'
    'P-Value'
    '95% CI'
};

% Create new rows array
rows = cell(size(data,2)-1, 9);
rows(:,1) = {
    'Dose Diff'
    'Gamma Pass Rate'
};

% If a valid filter was provided, store its current contents
if ~isempty(stats)
    prev = get(stats, 'Data');
end

% Loop through variables
subplot(2,2,4);
hold on;
l = cell(0);
for i = 1:size(data,2)-1
    
    if size(prev,1) >= i && strcmp(prev{i,1}, rows{i,1}) && ~prev{i,2}
        rows{i,2} = false;
    else
        rows{i,2} = true;
    end
    
    % Fit linear model to data
    try
        m = fitlm(data(:,1), data(:,i+1), 'linear', 'RobustOpts', 'bisquare');
        ci = coefCI(m, 0.05);
    catch err
        Event(err.message, 'WARN');
        warndlg(err.message);
        return;
    end
    
    rows{i,3} = sprintf('%i', m.NumObservations);
    rows{i,4} = sprintf('%0.3f', m.Rsquared.Ordinary);
    rows{i,5} = sprintf('%0.3f%%/C', m.Coefficients{2,1});
    rows{i,6} = sprintf('%0.3f', m.Coefficients{2,2});
    rows{i,7} = sprintf('%0.3f', m.Coefficients{2,3});
    rows{i,8} = sprintf('%0.3f', m.Coefficients{2,4});
    rows{i,9} = sprintf('[%0.3f%%, %0.3f%%]', ci(2,:));
    
    if rows{i,2}
        l{length(l)+1} = rows{i,1};
        [c, e] = histcounts(m.Residuals.Standardized);
        plot((e(1):0.01:e(end)), interp1(e(1:end-1), c, ...
            (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
            'LineWidth', 2);
    end
end
hold off;
if length(l) > 1
    legend(l);
end
ylabel('Occurrence');
xlabel('Standardized Residual');
box on;
grid on;
PlotBackground('vertical', [-3 -2 2 3]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e m oldrows i;