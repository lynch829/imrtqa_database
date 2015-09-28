function varargout = B_gammapassratemachine(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Gamma Pass Rate (Machine)';
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
data = db.queryColumns('delta4', 'gammapassrate', 'delta4', 'machine', ...
    'where', 'delta4', 'measdate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Extract unique list of machines
machines = unique(data(:,2));

% Define bin edges
e = 90:0.5:100;

% Update column names to this plot's statistics
columns = {
    'Dataset'
    'Show'
    'N'
    'Mean'
    'Min'
    'Max'
    '>95%'
};

% Loop through machines, plotting histogram of gamma pass rate
hold on;
for i = 1:length(machines)

    d = cell2mat(data(strcmp(data(:,2), machines{i}), 1));
    rows{i,1} = machines{i};
    rows{i,3} = sprintf('%i', length(d));

    if length(d) > 1
        rows{i,4} = sprintf('%0.1f%%', mean(d));
        rows{i,5} = sprintf('%0.1f%%', min(d));
        rows{i,6} = sprintf('%0.1f%%', max(d));
        rows{i,7} = sprintf('%0.1f%%', sum(d>=95)/length(d)*100);
    else
        rows{i,4} = '';
        rows{i,5} = '';
        rows{i,6} = '';
        rows{i,7} = '';
    end

    % If a filter exists, and data is displayed
    if (isempty(rows{i,2}) || ~strcmp(rows{i,1}, machines{i}) || ...
            rows{i,2}) && ~isempty(d)

        c = histcounts(d, e);
        plot((e(1):0.01:e(end)), interp1(e(1:end-1), c/sum(c), ...
            (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
            'LineWidth', 2);
        rows{i,2} = true;
    else   
        rows{i,2} = false;
        machines{i} = '';
    end


end

hold off;
legend(machines(~strcmp(machines, '')), 'Location', 'northwest');
xlabel('Gamma Index Pass Rate (%)');
ylabel('Relative Occurrence');
box on;
grid on;

% Add colored background
PlotBackground('vertical', [94 96 100 100]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data e c d machines i p;