function varargout = C_cumulativevsexpectedmu(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Cumulative vs. Expected MU';
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
data = db.queryColumns('delta4', 'cumulativemu', 'delta4', 'expectedmu', ...
    'delta4', 'measdate', 'delta4', 'machine', 'where', 'delta4', ...
    'measdate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Extract unique list of machines
machines = unique(data(:,4));

% Update column names to this plot's statistics
columns = {
    'Dataset'
    'Show'
    'N'
    'Adj R^2'
    'Slope'
    'P-Value'
};

% Loop through machines, plotting dose differences over time
hold on;
for i = 1:length(machines)

    d = cell2mat(data(strcmp(data(:,4), machines{i}), 1:3));
    rows{i,1} = machines{i};
    rows{i,3} = sprintf('%i', size(d,1));

    if size(d,1) > 1
        m = fitlm(d(:,3), d(:,1)./d(:,2));
        rows{i,4} = sprintf('%0.3f', m.Rsquared.Adjusted);
        rows{i,5} = sprintf('%0.3f%%/day', m.Coefficients{2,1});
        rows{i,6} = sprintf('%0.3f', m.Coefficients{2,4});
    else
        rows{i,4} = '';
        rows{i,5} = '';
        rows{i,6} = '';
    end

    % If a filter exists, and data is displayed
    if (isempty(rows{i,2}) || ~strcmp(rows{i,1}, machines{i}) || ...
            rows{i,2}) && size(d,1) > 0

        plot(d(:,3), d(:,1)./d(:,2), '.', 'MarkerSize', 30);
        rows{i,2} = true;
    else   
        machines{i} = '';
        rows{i,2} = false;
    end

end

hold off;
legend(machines(~strcmp(machines, '')));
ylabel('Cumulative/Expected MU ratio (%)');
xlabel('');
datetick('x','mm/dd/yyyy');
box on;
grid on;

% Add colored background
PlotBackground('horizontal', [0.9 0.95 1.05 1.10]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data e d machines i m p;