function varargout = A_imrtqaperday(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'IMRT QA per Day';
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

% Query measured dates for Delta4 records
data = cell2mat(db.queryColumns('delta4', 'measdate', ...
    'where', 'delta4', 'measdate', range));

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Set column names
columns = {'Statistic', 'Show', 'Mean', 'Min', 'Max'};

% Initialize statistic rows
rows = cell(4,5);

% Plot histogram of dates
subplot(2,2,1);
c = histcounts(data, floor(range(1)):ceil(range(2)));
c(c == 0) = [];
[d, e] = histcounts(c, 0:max(c)+2);
plot(0:0.01:e(end), interp1(e(1:end-1), d, ...
    0:0.01:e(end), 'nearest', 'extrap'), 'LineWidth', 2);
xlabel('IMRT QA per day');
ylabel('Occurrence');
box on;
grid on;
PlotBackground('vertical', [0 0 5 10]);
rows{1,1} = 'IMRT QA per day';
rows{1,2} = true;
rows{1,3} = sprintf('%0.1f', mean(c));
rows{1,4} = sprintf('%i', min(c));
rows{1,5} = sprintf('%i', max(c));

% Compute start time, end time, and duration
e = floor(min(data)):ceil(max(data));
t = zeros(length(e)-1, 2);
for i = 2:length(e)
    t(i-1,1) = min(data(data > e(i-1))) - e(i-1);
    t(i-1,2) = max(data(data < e(i))) - e(i-1);
end
t(t>1,:) = [];
t(t<0,:) = [];
t(:,1) = t(:,1) - 0.5/24; % Add a half hour to the beginning for planning
t(:,2) = t(:,2) + 0.5/24; % Add a half hour to the end for cleaning up
d = (t(:,2) - t(:,1)) * 24;
d(d == 0) = [];

% Plot distribution of durations
subplot(2,2,3);
[c, e] = histcounts(d, 0:0.5:8);
plot(0:0.01:e(end), interp1(e(1:end-1), c, ...
    0:0.01:e(end), 'nearest', 'extrap'), 'LineWidth', 2);
xlim([0 8]);
xlabel('Duration (Hours)');
ylabel('Occurrence');
box on;
grid on;
PlotBackground('vertical', [0 0 3 4]);
rows{2,1} = 'Duration (hours)';
rows{2,2} = true;
rows{2,3} = sprintf('%0.1f', mean(d));
rows{2,4} = sprintf('%0.1f', min(d));
rows{2,5} = sprintf('%0.1f', max(d));

% Plot distribution of start times
subplot(2,2,2);
[c, e] = histcounts(t(:,1), 0:0.0208:1.0208);
plot(0:0.001:e(end), interp1(e(1:end-1), c, ...
    0:0.001:e(end), 'nearest', 'extrap'), 'LineWidth', 2);
xlim([0.5 1]);
datetick('x', 'HH AM', 'keepticks');
xlabel('Start Time');
ylabel('Occurrence');
box on;
grid on;
PlotBackground('vertical', [0 0 19/24 1]);
rows{3,1} = 'Start Time';
rows{3,2} = true;
rows{3,3} = datestr(mean(t(:,1)), 'HH:MM AM');
rows{3,4} = datestr(min(t(:,1)), 'HH:MM AM');
rows{3,5} = datestr(max(t(:,1)), 'HH:MM AM');

% Plot distribution of finish times
subplot(2,2,4);
[c, e] = histcounts(t(:,2), 0:0.0208:1.0208);
plot(0:0.001:e(end), interp1(e(1:end-1), c, ...
    0:0.001:e(end), 'nearest', 'extrap'), 'LineWidth', 2);
xlim([0.5 1]);
datetick('x', 'HH AM', 'keepticks');
xlabel('Finish Time');
ylabel('Occurrence');
box on;
grid on;
PlotBackground('vertical', [0 0 21/24 23/24]);
rows{4,1} = 'Finish Time';
rows{4,2} = true;
rows{4,3} = datestr(mean(t(:,2)), 'HH:MM AM');
rows{4,4} = datestr(min(t(:,2)), 'HH:MM AM');
rows{4,5} = datestr(max(t(:,2)), 'HH:MM AM');

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data c d e p;