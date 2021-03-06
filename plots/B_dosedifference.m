function varargout = B_dosedifference(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Dose Difference';
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

% Query dose differences, by machine
data = db.queryColumns('delta4', 'dosedev', 'delta4', 'machine', ...
    'delta4', 'phantom', 'where', 'delta4', 'measdate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Define bin edges
e = -5:0.5:5;

% Extract unique list of machines
machines = unique(data(:,2));

% Extract unique list of phantoms
phantoms = unique(data(:,3));
phantoms = phantoms(~strcmp(phantoms, 'Unknown'));

% Update column names to this plot's statistics
columns = {
    'Dataset'
    'Show'
    'N'
    'Mean'
    'SD'
    'Min'
    'Max'
    'P-Value'
    '95% CI'
};

% Loop through machines, plotting histogram of dose differences
subplot(2,1,1);
hold on;
for i = 1:length(machines)

    d = cell2mat(data(strcmp(data(:,2), machines{i}), 1));
    rows{i,1} = machines{i};
    rows{i,3} = sprintf('%i', length(d));

    if length(d) > 1
        [~, p, ci, s] = ttest(d, 0, 'Alpha', 0.05);
        rows{i,4} = sprintf('%0.1f%%', mean(d));
        rows{i,5} = sprintf('%0.1f%%', s.sd);
        rows{i,6} = sprintf('%0.1f%%', min(d));
        rows{i,7} = sprintf('%0.1f%%', max(d));
        rows{i,8} = sprintf('%0.3f', p);
        rows{i,9} = sprintf('[%0.1f%%, %0.1f%%]', ...
            ci(1), ci(2));
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
legend(machines(~strcmp(machines, '')));
xlabel('Abs Dose Difference (%)');
ylabel('Relative Occurrence');
box on;
grid on;
PlotBackground('vertical', [-3 -2 2 3]);

% Loop through phantoms, plotting histogram of dose differences
subplot(2,1,2);
hold on;
for i = 1:length(phantoms)

    d = cell2mat(data(strcmp(data(:,3), phantoms{i}), 1));
    rows{length(machines)+i,1} = phantoms{i};
    rows{length(machines)+i,3} = sprintf('%i', length(d));

    if length(d) > 1
        [~, p, ci, s] = ttest(d, 0, 'Alpha', 0.05);
        rows{length(machines)+i,4} = sprintf('%0.1f%%', mean(d));
        rows{length(machines)+i,5} = sprintf('%0.1f%%', s.sd);
        rows{length(machines)+i,6} = sprintf('%0.1f%%', min(d));
        rows{length(machines)+i,7} = sprintf('%0.1f%%', max(d));
        rows{length(machines)+i,8} = sprintf('%0.3f', p);
        rows{length(machines)+i,9} = sprintf('[%0.1f%%, %0.1f%%]', ...
            ci(1), ci(2));
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

        c = histcounts(d, e);
        plot((e(1):0.01:e(end)), interp1(e(1:end-1), c/sum(c), ...
            (e(1):0.01:e(end))-(e(2)-e(1))/2, 'nearest', 'extrap'), ...
            'LineWidth', 2);
        rows{length(machines)+i,2} = true;
    else   
        phantoms{i} = '';
        rows{length(machines)+i,2} = false;
    end
end

hold off;
legend(phantoms(~strcmp(phantoms, '')));
xlabel('Abs Dose Difference (%)');
ylabel('Relative Occurrence');
box on;
grid on;
PlotBackground('vertical', [-3 -2 2 3]);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows(1:(length(machines)+length(phantoms)), ...
        1:length(columns)));
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data e c d machines i s p ci;