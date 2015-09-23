function varargout = PlotData(varargin)


% Define text for warning message if no data is found
nodatamsg = ['Based on the provided date range, no data was found for ', ...
    'this plot. Choose a different plot or adjust your date range.'];

% If no inputs are provided, return list of plots available
if nargin == 0
    
    varargout{1} = {
        'IMRT QA by Machine'
        'IMRT QA per Day'
        'Dose Difference (Machine)'
        'Dose Difference (Phantom)'
        'Dose vs. Date (Machine)'
        'Dose vs. Date (Phantom)'
        'Gamma Pass Rate (Machine)'
        'Gamma Pass Rate (Phantom)'
        'Gamma vs. Date (Machine)'
        'Gamma vs. Date (Phantom)'
        'Cumulative vs. Expected MU'
    };

    return;
   
% Otherwise, load input arguments
else
    
    % Initialize empty type, default range, and empty filter object
    type = '';
    range = [-1, 1];
    stats = [];
    
    for i = 1:nargin
        if strcmpi(varargin{i}, 'axes')
            ax = varargin{i+1};
        elseif strcmpi(varargin{i}, 'type')
            type = varargin{i+1};
        elseif strcmpi(varargin{i}, 'db')
            db = varargin{i+1};
        elseif strcmpi(varargin{i}, 'range')
            range = varargin{i+1};
        elseif strcmpi(varargin{i}, 'stats')
            stats = varargin{i+1};
        end
    end
end

% If an axes is not provided (or stored), create a new figure/axes
if ~exist('ax', 'var') || isempty(ax)
    ax = gca;
end

% If a db is not provided or stored, throw an error
if ~exist('db', 'var') || isempty(db)
    Event('A valid database object must be provided to PlotData', 'ERROR');
end

% If a valid filter was provided, store its current contents
if ~isempty(stats)
    rows = get(stats, 'Data');
    columns = get(stats, 'ColumnName'); %#ok<*NASGU>
end

% Localize to current axes
axes(ax);
cla(ax, 'reset');

% Generate plot based on type
switch type

% Plot a pie graph of IMRT QA reports by machine
case 'IMRT QA by Machine'
    
    % Query dose differences, by machine
    data = db.queryColumns('delta4', 'machine', 'delta4', 'measdate');
    
    % Remove dates outside of range range
    data = data(cell2mat(data(:,2)) > range(1), 1:2);
    data = data(cell2mat(data(:,2)) < range(2), 1:2);
    
    % Determine unique machines
    machines = unique(data(:,1));
    c = zeros(size(machines));
    for i = 1:length(machines)
        c(i) = sum(strcmp(machines{i}, data(:,1)));
    end
    
    % Plot pie chart
    pie(c, machines);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', {});
        set(stats, 'ColumnName', {});
    end
    
    % Clear temporary variables
    clear data machines i c;
    
% Plot number of IMRT QA plans performed per day
case 'IMRT QA per Day'

    % Query measured dates for Delta4 records
    data = cell2mat(db.queryColumns('delta4', 'measdate'));
    
    % Remove dates outside of range range
    data = data(data > range(1));
    data = data(data < range(2));
    
    % If no data was found
    if isempty(data)
        Event(nodatamsg);
        warndlg(nodatamsg);
        return;
    end
    
    % Plot histogram of dates
    c = histcounts(data, floor(range(1)):ceil(range(2)));
    c(c == 0) = [];
    [d, e] = histcounts(c);
    plot(e(1:end-1)+0.5, d);
    xlabel('Number of IMRT QA plans per day');
    ylabel('Occurrence');
    box on;
    grid on;
    
    % Add colored background
    xl = xlim;
    yl = ylim;
    p = patch([max(xl(1), 0) min(xl(2), 5) min(xl(2), 5) max(xl(1), 0)], ...
        [yl(1) yl(1) yl(2) yl(2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([max(xl(1), 5) xl(2) xl(2) max(xl(1), 5)], ...
        [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', {});
        set(stats, 'ColumnName', {});
    end
    
    % Clear temporary variables
    clear data c d e p xl yl;

% Plot absolute measured dose difference
case 'Dose Difference (Machine)'
    
    % Query dose differences, by machine
    data = db.queryColumns('delta4', 'dosedev', 'delta4', 'machine', ...
        'delta4', 'measdate');
    machines = unique(data(:,2));
    
    % Define bin edges
    edges = -5:0.5:5;
    
    % Remove dates outside of range range
    data = data(cell2mat(data(:,3)) > range(1), 1:3);
    data = data(cell2mat(data(:,3)) < range(2), 1:3);
    
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
        'Mean'
        'SD'
        'Min'
        'Max'
        'P-Value'
        '95% CI'
    };
    
    % Loop through machines, plotting histogram of dose differences
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

            c = histcounts(d, edges);
            plot(edges(1:end-1), c/sum(c));
            rows{i,2} = true;
        else   
            rows{i,2} = false;
            machines{i} = '';
        end
        
        
    end
    
    hold off;
    legend(machines(~strcmp(machines, '')));
    xlabel('Absolute Dose Difference (%)');
    ylabel('Relative Occurrence');
    box on;
    grid on;
    
    % Add colored background
    xl = xlim;
    yl = ylim;
    p = patch([-2 2 2 -2], [yl(1) yl(1) yl(2) yl(2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([-3 -2 -2 -3], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([2 3 3 2], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([-5 -3 -3 -5], [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([3 5 5 3], [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges c d machines i s p ci xl yl;
    
% Plot absolute measured dose difference
case 'Dose Difference (Phantom)'
    
    % Query dose differences, by phantom
    data = db.queryColumns('delta4', 'dosedev', 'delta4', 'phantom', ...
        'delta4', 'measdate');
    phantoms = unique(data(:,2));
    phantoms = phantoms(~strcmp(phantoms, 'Unknown'));
    
    % Define bin edges
    edges = -5:0.5:5;
    
    % Remove dates outside of range range
    data = data(cell2mat(data(:,3)) > range(1), 1:3);
    data = data(cell2mat(data(:,3)) < range(2), 1:3);
    
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
        'Mean'
        'SD'
        'Min'
        'Max'
        'P-Value'
        '95% CI'
    };
    
    % Loop through phantoms, plotting histogram of dose differences
    hold on;
    for i = 1:length(phantoms)
        
        d = cell2mat(data(strcmp(data(:,2), phantoms{i}), 1));
        rows{i,1} = phantoms{i};
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
        if (isempty(rows{i,2}) || ~strcmp(rows{i,1}, phantoms{i}) || ...
                rows{i,2}) && ~isempty(d)

            c = histcounts(d, edges);
            plot(edges(1:end-1), c/sum(c));
            rows{i,2} = true;
        else   
            phantoms{i} = '';
            rows{i,2} = false;
        end
        
        
    end
    
    hold off;
    legend(phantoms(~strcmp(phantoms, '')));
    xlabel('Absolute Dose Difference (%)');
    ylabel('Relative Occurrence');
    box on;
    grid on;
    
    % Add colored background
    xl = xlim;
    yl = ylim;
    p = patch([-2 2 2 -2], [yl(1) yl(1) yl(2) yl(2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([-3 -2 -2 -3], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([2 3 3 2], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([-5 -3 -3 -5], [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([3 5 5 3], [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(phantoms), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges c d phantoms i s p ci xl yl;
    
% Plot dose difference over time
case 'Dose vs. Date (Machine)'
    
    % Query dose differences, by machine
    data = db.queryColumns('delta4', 'dosedev', 'delta4', 'measdate', ...
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
        'Adj R^2'
        'Slope'
        'P-Value'
    };

    % Loop through machines, plotting dose differences over time
    hold on;
    for i = 1:length(machines)
        
        d = cell2mat(data(strcmp(data(:,3), machines{i}), 1:2));
        rows{i,1} = machines{i};
        rows{i,3} = sprintf('%i', size(d,1));
        
        if size(d,1) > 1
            m = fitlm(d(:,2), d(:,1));
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
    ylabel('Absolute Dose Difference (%)');
    xlabel('');
    datetick('x','mm/dd/yyyy');
    box on;
    grid on;
    
    % Add colored background
    xl = xlim;
    yl = ylim;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),-2) max(yl(1),-2) ...
        min(yl(2),2) min(yl(2),2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),-3) max(yl(1),-3) ...
        max(yl(1),-2) max(yl(1),-2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2),2) min(yl(2),2) ...
        min(yl(2),3) min(yl(2),3)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [yl(1) yl(1) ...
        max(yl(1),-3) max(yl(1),-3)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2),3) min(yl(2),3) ...
        yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges d machines i m p xl yl;
    
% Plot dose difference over time
case 'Dose vs. Date (Phantom)'
    
    % Query dose differences, by machine
    data = db.queryColumns('delta4', 'dosedev', 'delta4', 'measdate', ...
        'delta4', 'phantom');
    phantoms = unique(data(:,3));
    phantoms = phantoms(~strcmp(phantoms, 'Unknown'));

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
        'Adj R^2'
        'Slope'
        'P-Value'
    };

    % Loop through phantoms, plotting dose differences over time
    hold on;
    for i = 1:length(phantoms)
        
        d = cell2mat(data(strcmp(data(:,3), phantoms{i}), 1:2));
        rows{i,1} = phantoms{i};
        rows{i,3} = sprintf('%i', size(d,1));
        
        if size(d,1) > 1
            m = fitlm(d(:,2), d(:,1));
            rows{i,4} = sprintf('%0.3f', m.Rsquared.Adjusted);
            rows{i,5} = sprintf('%0.3f%%/day', m.Coefficients{2,1});
            rows{i,6} = sprintf('%0.3f', m.Coefficients{2,4});
        else
            rows{i,4} = '';
            rows{i,5} = '';
            rows{i,6} = '';
        end
        
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
    ylabel('Absolute Dose Difference (%)');
    xlabel('');
    datetick('x','mm/dd/yyyy');
    box on;
    grid on;
    
    % Add colored background
    xl = xlim;
    yl = ylim;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),-2) max(yl(1),-2) ...
        min(yl(2),2) min(yl(2),2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),-3) max(yl(1),-3) ...
        max(yl(1),-2) max(yl(1),-2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2),2) min(yl(2),2) ...
        min(yl(2),3) min(yl(2),3)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [yl(1) yl(1) ...
        max(yl(1),-3) max(yl(1),-3)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2),3) min(yl(2),3) ...
        yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(phantoms), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges d phantoms i m p xl yl;
    
% Plot gamma pass rate
case 'Gamma Pass Rate (Machine)'
    
    % Query gamma pass rate, by machine
    data = db.queryColumns('delta4', 'gammapassrate', 'delta4', 'machine', ...
        'delta4', 'measdate');
    machines = unique(data(:,2));
    
    % Define bin edges
    edges = 90:0.5:100;
    
    % Remove dates outside of range range
    data = data(cell2mat(data(:,3)) > range(1), 1:3);
    data = data(cell2mat(data(:,3)) < range(2), 1:3);
    
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

            c = histcounts(d, edges);
            plot(edges(2:end), c/sum(c));
            rows{i,2} = true;
        else   
            rows{i,2} = false;
            machines{i} = '';
        end
        
        
    end
    
    hold off;
    legend(machines(~strcmp(machines, '')));
    xlabel('Gamma Index Pass Rate (%)');
    ylabel('Relative Occurrence');
    box on;
    grid on;
   
    % Add colored background
    xl = xlim;
    yl = ylim;
    p = patch([96 100 100 96], [yl(1) yl(1) yl(2) yl(2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([94 96 96 94], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([90 94 94 90], [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges c d machines i p xl yl;
    
% Plot gamma pass rate
case 'Gamma Pass Rate (Phantom)'
    
    % Query gamma pass rate, by phantom
    data = db.queryColumns('delta4', 'gammapassrate', 'delta4', 'phantom', ...
        'delta4', 'measdate');
    phantoms = unique(data(:,2));
    phantoms = phantoms(~strcmp(phantoms, 'Unknown'));
    
    % Define bin edges
    edges = 90:0.5:100;
    
    % Remove dates outside of range range
    data = data(cell2mat(data(:,3)) > range(1), 1:3);
    data = data(cell2mat(data(:,3)) < range(2), 1:3);
    
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
        'Mean'
        'Min'
        'Max'
        '>95%'
    };
    
    % Loop through phantoms, plotting histogram of gamma pass rate
    hold on;
    for i = 1:length(phantoms)
        
        d = cell2mat(data(strcmp(data(:,2), phantoms{i}), 1));
        rows{i,1} = phantoms{i};
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
        if (isempty(rows{i,2}) || ~strcmp(rows{i,1}, phantoms{i}) || ...
                rows{i,2}) && ~isempty(d)

            c = histcounts(d, edges);
            plot(edges(1:end-1), c/sum(c));
            rows{i,2} = true;
        else   
            phantoms{i} = '';
            rows{i,2} = false;
        end
    end
    
    hold off;
    legend(phantoms(~strcmp(phantoms, '')));
    xlabel('Gamma Index Pass Rate (%)');
    ylabel('Relative Occurrence');
    box on;
    grid on;
    
    % Add colored background
    xl = xlim;
    yl = ylim;
    p = patch([96 100 100 96], [yl(1) yl(1) yl(2) yl(2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([94 96 96 94], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([90 94 94 90], [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(phantoms), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges c d phantoms i p xl yl;
    
% Plot gamma pass rate over time
case 'Gamma vs. Date (Machine)'
    
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
    xl = xlim;
    yl = ylim;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),96) max(yl(1),96) ...
        min(yl(2),100) min(yl(2),100)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),94) max(yl(1),94) ...
        max(yl(1),96) max(yl(1),96)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [yl(1) yl(1) ...
        max(yl(1),94) max(yl(1),94)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges d machines i m p xl yl;
    
% Plot gamma pass rate over time
case 'Gamma vs. Date (Phantom)'
    
    % Query gamma pass rate, by machine
    data = db.queryColumns('delta4', 'gammapassrate', 'delta4', 'measdate', ...
        'delta4', 'phantom');
    phantoms = unique(data(:,3));
    phantoms = phantoms(~strcmp(phantoms, 'Unknown'));

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
    xl = xlim;
    yl = ylim;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),96) max(yl(1),96) ...
        min(yl(2),100) min(yl(2),100)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),94) max(yl(1),94) ...
        max(yl(1),96) max(yl(1),96)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [yl(1) yl(1) ...
        max(yl(1),94) max(yl(1),94)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(phantoms), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges d phantoms i m p xl yl;

% Plot ratio of cumulative vs. expected MU, by machine
case 'Cumulative vs. Expected MU'
    
    % Query gamma pass rate, by machine
    data = db.queryColumns('delta4', 'cumulativemu', 'delta4', 'expectedmu', ...
        'delta4', 'measdate', 'delta4', 'machine');
    machines = unique(data(:,4));

    % Remove dates outside of range range
    data = data(cell2mat(data(:,3)) > range(1), 1:4);
    data = data(cell2mat(data(:,3)) < range(2), 1:4);
    
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
    xl = xlim;
    yl = ylim;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),0.95) max(yl(1),0.95) ...
        min(yl(2),1.05) min(yl(2),1.05)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1),0.9) max(yl(1),0.9) ...
        max(yl(1),0.95) max(yl(1),0.95)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2),1.05) min(yl(2),1.05) ...
        min(yl(2),1.1) min(yl(2),1.1)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [yl(1) yl(1) ...
        max(yl(1),0.9) max(yl(1),0.9)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2),1.1) min(yl(2),1.1) ...
        yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    xlim(xl);
    ylim(yl);
    
    % Update stats
    if ~isempty(stats)
        set(stats, 'Data', rows(1:length(machines), 1:length(columns)));
        set(stats, 'ColumnName', columns);
    end
    
    % Clear temporary variables
    clear data edges d machines i m p xl yl;
    
end

% Clear temporary variables
clear type range stats rows columns;