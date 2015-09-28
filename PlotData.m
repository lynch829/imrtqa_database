function varargout = PlotData(varargin)
% Queries the IMRT QA database and plots results based on provided type

persistent plotList db parent;

% Define text for warning message if no data is found
nodatamsg = ['Based on the provided date range, no data was found for ', ...
    'this plot. Choose a different plot or adjust your date range.'];

% If no inputs are provided, return list of plots available
if nargin == 0
    addpath(fullfile(pwd, './plots'));
    plotList = what(fullfile(pwd, './plots'));
    plotList.m = sort(plotList.m);
    for i = 1:length(plotList.m)
        plotList.func{i} = str2func(strrep(plotList.m{i}, '.m', ''));
        plotList.string{i} = plotList.func{i}();
    end
    varargout{1} = plotList.string;

    return;
   
% Otherwise, load input arguments
else
    
    % Initialize empty type, default range, and empty filter object
    type = '';
    range = [-1, 1];
    stats = [];
    
    for i = 1:nargin
        if strcmpi(varargin{i}, 'parent')
            parent = varargin{i+1};
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

% If a parent is provided
if ~exist('parent', 'var') || isempty(parent)
    parent = figure;
else
    subplot(1,1,1, 'Parent', parent);
    cla reset;
end

% If a db is not provided or stored, throw an error
if ~exist('db', 'var') || isempty(db)
    Event('A valid database object must be provided to PlotData', 'ERROR');
end

% Verify data exists
if db.countReports() == 0
    Event('No records exist in the database, plotting ignored');
    return;
end

% If type is an integer, execute by index
if isinteger(type)
    plotList.func{type}('db', db, 'stats', stats, 'range', range, ...
        'nodatamsg', nodatamsg);

% Otherwise, loop through plotList until type matches string, then execute
else
    for i = 1:length(plotList.string)
        if strcmp(plotList.string{i}, type)
            plotList.func{i}('db', db, 'stats', stats, 'range', range, ...
                'nodatamsg', nodatamsg);
            break;
        end
    end
end 

% Clear temporary variables
clear i type range stats nodatamsg;