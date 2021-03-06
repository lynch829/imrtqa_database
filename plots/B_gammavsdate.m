function varargout = B_gammavsdate(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Gamma vs. Date';
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

% Query gamma pass rate, by machine
data = db.queryColumns('delta4', 'gammapassrate', 'delta4', 'measdate', ...
    'delta4', 'machine', 'delta4', 'phantom', 'where', 'delta4', ...
    'measdate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Extract unique list of machines
machines = unique(data(:,3));

% Extract unique list of phantoms
phantoms = unique(data(:,4));
phantoms = phantoms(~strcmp(phantoms, 'Unknown'));

% Update column names to this plot's statistics
columns = {
    'Dataset'
    'Show'
    'N'
    'R^2'
    'Slope'
    'SE'
    'T-Stat'
    'P-Value'
    '95% CI'
};

% Loop through machines, plotting gamma pass rate over time
subplot(2,1,1);
hold on;
for i = 1:length(machines)

    d = cell2mat(data(strcmp(data(:,3), machines{i}), 1:2));
    rows{i,1} = machines{i};
    rows{i,3} = sprintf('%i', size(d,1));

    if size(d,1) > 1
        try
            m = fitlm(d(:,2), d(:,1), 'linear', 'RobustOpts', ...
                'bisquare', 'Intercept', false);
            ci = coefCI(m, 0.05);
        catch err
            Event(err.message, 'WARN');
            warndlg(err.message);
            return;
        end
        rows{i,4} = sprintf('%0.3f', m.Rsquared.Ordinary);
        rows{i,5} = sprintf('%0.3f%%/day', m.Coefficients{1,1});
        rows{i,6} = sprintf('%0.3f', m.Coefficients{1,2});
        rows{i,7} = sprintf('%0.3f', m.Coefficients{1,3});
        rows{i,8} = sprintf('%0.3f', m.Coefficients{1,4});
        rows{i,9} = sprintf('[%0.3f%%, %0.3f%%]', ci(1,:));
    else
        rows{i,4} = '';
        rows{i,5} = '';
        rows{i,6} = '';
        rows{i,7} = '';
        rows{i,8} = '';
        rows{i,9} = '';
    end
    
    % If a filter exists, and data is displayed
    if (isempty(rows{i,2}) || ~strcmp(rows{i,1}, machines{i}) || ...
            rows{i,2}) && ~isempty(d)

        plot(d(:,2), d(:,1), '.', 'MarkerSize', 30);
        rows{i,2} = true;
    else   
        machines{i} = '';
        rows{i,2} = false;
    end

end

hold off;
ylim([90 100]);
legend(machines(~strcmp(machines, '')));
ylabel('Gamma Index Pass Rate (%)');
xlabel('');
datetick('x','mm/dd/yy', 'keepticks');
box on;
grid on;
PlotBackground('horizontal', [94 96 100 100]);

% Loop through phantoms, plotting gamma pass rates over time
subplot(2,1,2);
hold on;
for i = 1:length(phantoms)

    d = cell2mat(data(strcmp(data(:,4), phantoms{i}), 1:2));
    rows{length(machines)+i,1} = phantoms{i};
    rows{length(machines)+i,3} = sprintf('%i', size(d,1));

    if size(d,1) > 1
        try
            m = fitlm(d(:,2), d(:,1), 'linear', 'RobustOpts', 'bisquare');
            ci = coefCI(m, 0.05);
        catch err
            Event(err.message, 'WARN');
            warndlg(err.message);
            return;
        end
        rows{length(machines)+i,4} = sprintf('%0.3f', m.Rsquared.Ordinary);
        rows{length(machines)+i,5} = sprintf('%0.3f%%/day', m.Coefficients{2,1});
        rows{length(machines)+i,6} = sprintf('%0.3f', m.Coefficients{2,2});
        rows{length(machines)+i,7} = sprintf('%0.3f', m.Coefficients{2,3});
        rows{length(machines)+i,8} = sprintf('%0.3f', m.Coefficients{2,4});
        rows{length(machines)+i,9} = sprintf('[%0.3f%%, %0.3f%%]', ci(2,:));
    else
        rows{length(machines)+i,4} = '';
        rows{length(machines)+i,5} = '';
        rows{length(machines)+i,6} = '';
        rows{length(machines)+i,7} = '';
        rows{length(machines)+i,8} = '';
        rows{length(machines)+i,9} = '';
    end
    
    % If a filter exists, and data is displayed
    if (isempty(rows{length(machines)+i,2}) || ...
            ~strcmp(rows{length(machines)+i,1}, phantoms{i}) || ...
            rows{length(machines)+i,2}) && ~isempty(d)

        plot(d(:,2), d(:,1), '.', 'MarkerSize', 30);
        rows{length(machines)+i,2} = true;
    else   
        phantoms{i} = '';
        rows{length(machines)+i,2} = false;
    end

end

hold off;
ylim([90 100]);
legend(phantoms(~strcmp(phantoms, '')));
ylabel('Gamma Index Pass Rate (%)');
xlabel('');
datetick('x','mm/dd/yy', 'keepticks');
box on;
grid on;
PlotBackground('horizontal', [94 96 100 100]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows(1:(length(machines)+length(phantoms)), ...
        1:length(columns)));
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data e d machines i m p;
