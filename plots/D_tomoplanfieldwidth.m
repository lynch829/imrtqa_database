function varargout = D_tomoplanfieldwidth(varargin)

% If no inputs are provided, return plot name
if nargin == 0
    varargout{1} = 'Tomo Plan Field Width';
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
data = db.queryColumns('tomo', 'fieldwidth', ...
    'where', 'tomo', 'plandate', range);

% If no data was found
if isempty(data)
    Event(nodatamsg, 'WARN');
    warndlg(nodatamsg);
    return;
end

% Set column names
columns = {'Field Width', 'Show', 'N', '%'};

% Determine unique modes
for i = 1:size(data,1)
    if round(data{i,1}) == 5
        data{i,1} = '5 cm';
    elseif round(data{i,1}) == 3
        data{i,1} = '2.5 cm';
    elseif round(data{i,1}) == 1
        data{i,1} = '1 cm';
    else
        data{i,1} = '';
    end
end
widths = unique(data(:,1));
c = zeros(size(widths));
rows = cell(length(widths), 4);
for i = 1:length(widths)
    c(i) = sum(strcmp(widths{i}, data(:,1)));
    rows{i,1} = widths{i};
    rows{i,2} = true;
    rows{i,3} = sprintf('%i', c(i));
    rows{i,4} = sprintf('%0.1f%%', c(i)/size(data,1)*100);
end

% Plot pie chart
pie(c, widths);

% Update stats
if ~isempty(stats)
    set(stats, 'Data', rows);
    set(stats, 'ColumnName', columns);
end

% Clear temporary variables
clear data widths i c rows columns;