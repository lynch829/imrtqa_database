function varargout = B_gammavsdatemachine(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Gamma vs. Date (Machine)';
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
    'delta4', 'machine');
machines = unique(data(:,3));

% Remove dates outside of range range
data = data(cell2mat(data(:,2)) > range(1), 1:3);
data = data(cell2mat(data(:,2)) < range(2), 1:3);

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Update column names to this plot's statistics
columns = {
    'Dataset'
    'Show'
    'N'
};

% Loop through machines, plotting gamma pass rate over time
hold on;
for i = 1:length(machines)

    d = cell2mat(data(strcmp(data(:,3), machines{i}), 1:2));
    rows{i,1} = machines{i};
    rows{i,3} = sprintf('%i', size(d,1));

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
legend(machines(~strcmp(machines, '')));
ylabel('Gamma Index Pass Rate (%)');
xlabel('');
datetick('x','mm/dd/yyyy');
box on;
grid on;

% Add colored background
PlotBackground('horizontal', [94 96 100 100]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data e d machines i m p;