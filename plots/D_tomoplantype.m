function varargout = D_tomoplantype(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Tomo Plan Type';
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

% Query TomoTherapy gantry mode and date
data = db.queryColumns('tomo', 'gantrymode', ...
    'where', 'tomo', 'plandate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Set column names
columns = {'Gantry Type', 'Show', 'N', '%'};

% Determine unique modes
modes = unique(data(:,1));
c = zeros(size(modes));
rows = cell(length(modes), 4);
for i = 1:length(modes)
    c(i) = sum(strcmp(modes{i}, data(:,1)));
    rows{i,1} = modes{i};
    rows{i,2} = true;
    rows{i,3} = sprintf('%i', c(i));
    rows{i,4} = sprintf('%0.1f%%', c(i)/size(data,1)*100);
end

% Plot pie chart
pie(c, modes);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data modes i c;