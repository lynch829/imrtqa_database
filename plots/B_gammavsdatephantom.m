function varargout = B_gammavsdatephantom(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Gamma vs. Date (Phantom)';
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
    'delta4', 'phantom', 'where', 'delta4', 'measdate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Extract unique list of phantoms
phantoms = unique(data(:,3));
phantoms = phantoms(~strcmp(phantoms, 'Unknown'));

% Update column names to this plot's statistics
columns = {
    'Dataset'
    'Show'
    'N'
};

% Loop through phantoms, plotting gamma pass rates over time
hold on;
for i = 1:length(phantoms)

    d = cell2mat(data(strcmp(data(:,3), phantoms{i}), 1:2));
    rows{i,1} = phantoms{i};
    rows{i,3} = sprintf('%i', size(d,1));

    % If a filter exists, and data is displayed
    if (isempty(rows{i,2}) || ~strcmp(rows{i,1}, phantoms{i}) || ...
            rows{i,2}) && ~isempty(d)

        plot(d(:,2), d(:,1), '.', 'MarkerSize', 30);
        rows{i,2} = true;
    else   
        phantoms{i} = '';
        rows{i,2} = false;
    end

end

hold off;
legend(phantoms(~strcmp(phantoms, '')));
ylabel('Gamma Index Pass Rate (%)');
xlabel('');
datetick('x','mm/dd/yyyy');
box on;
grid on;

% Add colored background
PlotBackground('horizontal', [94 96 100 100]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows(1:length(phantoms), 1:length(columns)));
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data e d phantoms i m p;