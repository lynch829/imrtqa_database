function varargout = A_imrtqabymachine(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'IMRT QA by Machine';
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

% Query dose differences, by machine
data = db.queryColumns('delta4', 'machine', 'where', 'delta4', ...
    'measdate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg);
    warndlg(nodatamsg);
    return;
end

% Set column names
columns = {'Machine', 'Show', 'N', '%'};

% Extract unique list of machines
machines = unique(data(:,1));

c = zeros(size(machines));
rows = cell(length(machines), 4);
for i = 1:length(machines)
    c(i) = sum(strcmp(machines{i}, data(:,1)));
    rows{i,1} = machines{i};
    rows{i,2} = true;
    rows{i,3} = sprintf('%i', c(i));
    rows{i,4} = sprintf('%0.1f%%', c(i)/size(data,1)*100);
end

% Plot pie chart
pie(c, machines);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data machines i c;