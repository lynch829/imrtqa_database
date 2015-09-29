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

% Plot histogram of dates
subplot(2,2,1);
c = histcounts(data, floor(range(1)):ceil(range(2)));
c(c == 0) = [];
[d, e] = histcounts(c, 0:max(c)+2);
plot(0:0.01:e(end), interp1(e(1:end-1), d, ...
    0:0.01:e(end), 'nearest', 'extrap'), 'LineWidth', 2);
xlabel('Number of IMRT QA plans per day');
ylabel('Occurrence');
box on;
grid on;
PlotBackground('vertical', [0 0 5 10]);

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

% Update stats
if ~isempty(stats)
    set(stats, 'Data', {});
    set(stats, 'ColumnName', {});
end

% Clear temporary variables
clear data c d e p;