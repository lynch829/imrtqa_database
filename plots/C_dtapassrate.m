function varargout = C_dtapassrate(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'DTA Pass Rate';
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

% Query phantom dta pass rate and gamma pass rate
data = cell2mat(db.queryColumns('delta4', 'dtapassrate', 'delta4', ...
    'gammapassrate', 'where', 'delta4', 'measdate', range));

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Update column names to this plot's statistics
columns = {
    'Comparison'
    'Show'
    'N'
    'R^2'
    'Slope'
    'SE'
    'T-Stat'
    'P-Value'
    '95% CI'
};

% Plot histogram of DTA pass rates
subplot(2,2,1);
[d, e] = histcounts(data(:,1), 20);
plot((e(1):0.01:e(end)), interp1(e(1:end-1), d, ...
    (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
xlabel('DTA Criterion Pass Rate (%)');
ylabel('Occurrence');
box on;
grid on;
xlim([min(data(:,1)) 100]);
PlotBackground('vertical', [0 0 100 100]);

% Plot DTA pass rate vs gamma pass rate
subplot(2,2,2);
plot(data(:,1), data(:,2), '.', 'MarkerSize', 30);
xlabel(' Criterion Pass Rate (%)');
ylabel('Gamma Index Pass Rate (%)');
box on;
grid on;
p = patch([20 100 100], [0 0 80], 'yellow');
p.EdgeAlpha = 0;
p.FaceAlpha = 0.05;
p = patch([0 80 0], [20 100 100], 'yellow');
p.EdgeAlpha = 0;
p.FaceAlpha = 0.05;
p = patch([0 20 100 100 80 0], [0 0 80 100 100 20], 'green');
p.EdgeAlpha = 0;
p.FaceAlpha = 0.05;
xlim([min(data(:,1)) max(data(:,1))]);
ylim([min(data(:,2)) max(data(:,2))]);

try
    m = fitlm(data(:,1), data(:,2), 'linear', 'RobustOpts', 'bisquare');
    ci = coefCI(m, 0.05);
catch err
    Event(err.message, 'WARN');
    warndlg(err.message);
    return;
end

% Plot residuals
subplot(2,2,3);
plot(data(:,1), m.Residuals.Standardized, '.', 'MarkerSize', 30);
ylabel('Standardized Residual');
xlabel('DTA Criterion Pass Rate (%)');
box on;
grid on;
PlotBackground('horizontal', [-3 -2 2 3]);

% Plot residual histogram
subplot(2,2,4);
[c, e] = histcounts(m.Residuals.Standardized);
plot((e(1):0.01:e(end)), interp1(e(1:end-1), c, ...
    (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
    'LineWidth', 2);
ylabel('Occurrence');
xlabel('Standardized Residual');
box on;
grid on;
PlotBackground('vertical', [-3 -2 2 3]);
xlim([e(1) e(end)]);

rows = cell(1,9);
rows{1,1} = 'Gamma Pass Rate';
rows{1,2} = true;
rows{1,3} = sprintf('%i', size(data,1));
rows{1,4} = sprintf('%0.3f', m.Rsquared.Ordinary);
rows{1,5} = sprintf('%0.3f', m.Coefficients{2,1});
rows{1,6} = sprintf('%0.3f', m.Coefficients{2,2});
rows{1,7} = sprintf('%0.3f', m.Coefficients{2,3});
rows{1,8} = sprintf('%0.3f', m.Coefficients{2,4});
rows{1,9} = sprintf('[%0.3f, %0.3f]', ci(2,:));
    
% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data d e;