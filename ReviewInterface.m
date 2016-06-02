function varargout = ReviewInterface(varargin)
% REVIEWINTERFACE MATLAB code for ReviewInterface.fig
%      REVIEWINTERFACE, by itself, creates a new REVIEWINTERFACE or raises the existing
%      singleton*.
%
%      H = REVIEWINTERFACE returns the handle to a new REVIEWINTERFACE or the handle to
%      the existing singleton*.
%
%      REVIEWINTERFACE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REVIEWINTERFACE.M with the given input arguments.
%
%      REVIEWINTERFACE('Property','Value',...) creates a new REVIEWINTERFACE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ReviewInterface_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ReviewInterface_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ReviewInterface

% Last Modified by GUIDE v2.5 29-Sep-2015 17:40:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ReviewInterface_OpeningFcn, ...
                   'gui_OutputFcn',  @ReviewInterface_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ReviewInterface_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ReviewInterface (see VARARGIN)

% Choose default command line output for ReviewInterface
handles.output = hObject;

% Turn off MATLAB warnings
warning('off','all');

% Turn off TeX processing
set(0, 'DefaulttextInterpreter', 'none');

% Set version handle
handles.version = '0.9';
set(handles.version_text, 'String', ['Version ', handles.version]);

% Set database file location
handles.dbFile = 'database.db';

% Set Mobius3D server IP/DNS and authentication credentials
handles.m3d.server = '10.105.1.12';
handles.m3d.user = 'admin';
handles.m3d.pass = 'admin';

% Declare list of machines and plan types
handles.machines = {
    '0210477'       'tomo'
    '0210488'       'tomo'
    'TrueBeam1358'  'linac'
    '21EXUnified'   'linac'
};

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Store and set current directory to location of this application
cd(path);
handles.path = path;

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'IMRT QA Results Analysis Tool'
    sprintf('Version: %s (%s)', handles.version, handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Clear temporary variables
clear separator;

% Log information
Event(string, 'INIT');

% Set range options, defaulting to Last 90 days
handles.ranges = { 
    'All Records'
    'Last 30 Days'
    'Last 90 Days'
    'Last 1 Year'
    'Custom Dates'
};
set(handles.range, 'String', handles.ranges);
set(handles.range, 'Value', 3);
handles.range_high = now;
handles.range_low = handles.range_high - 90;

% Initialize empty plot_stats table
set(handles.plot_stats, 'Data', cell(4, 8));

% Set plot options
set(handles.plot_types, 'String', PlotData());
set(handles.plot_types, 'Value', 1);

% Log default path
Event(['Default file path set to ', handles.path]);

% Add jsonlab folder to search path
addpath('./mobius_query');

% Check if MATLAB can find EstablishConnection
if exist('EstablishConnection', 'file') ~= 2
    
    % If not, throw an error
    Event(['The Mobius3D server query toolbox submodule does not exist in ', ...
        'the search path. Use git clone --recursive or git submodule init ', ...
        'followed by git submodule update to fetch all submodules'], ...
        'ERROR');
end

% Log database load
Event(['Loading default database file ', handles.dbFile]);

% Verify database file exists
if exist(fullfile(handles.path, handles.dbFile), 'file') == 2

    % Initialize new connection to database
    handles.db = IMRTDatabase(fullfile(handles.path, handles.dbFile));
    
    % Verify database has loaded
    if isempty(handles.db.connection.URL)
        Event(['Could not open connection to ', handles.dbFile, ':', ...
            handles.db.connection.Message], 'ERROR');
    end

    % Update database summary table
    handles = UpdateSummary(handles);
else
    
    % Otherwise, execute callback to prompt user to select a different db
    handles = opendb_Callback(handles.opendb, '', handles);
end

% Connect to Mobius3D server
handles.m3d.session = EstablishConnection('server', handles.m3d.server, ...
    'user', handles.m3d.user, 'pass', handles.m3d.pass);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = ReviewInterface_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = opendb_Callback(hObject, ~, handles)
% hObject    handle to opendb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Prompt user to select a new database file
Event('UI window opened to select database');
[file, path] = uigetfile('*.db','Select a database to open');

% If a directory was selected
if ~isequal(file, 0)

    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Initialize new connection to database
    handles.dbFile = file;
    Event(['Loading database file ', fullfile(path, file)]);
    handles.db = IMRTDatabase(fullfile(path, file));
    
    % Verify database has loaded
    if isempty(handles.db.connection.URL)
        Event(['Could not open connection to ', handles.dbFile, ':', ...
            handles.db.connection.Message], 'ERROR');
    end
    
    % Update database summary table
    handles = UpdateSummary(handles);

    % Update plot using first option
    plots = cellstr(get(handles.plot_types,'String'));
    PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
        plots{get(handles.plot_types,'Value')}, 'range', ...
        [handles.range_low, handles.range_high], 'stats', handles.plot_stats);
    clear plots;
else
    Event('User did not select a database');
end

% Clear temporary variables
clear file path;
    
% Set return variable
if nargout == 1
    varargout{1} = handles;
else
    guidata(hObject, handles);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function export_Callback(hObject, ~, handles)
% hObject    handle to export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Open a dialog box for the user to select a directory
Event('UI window opened to select export path');
path = uigetdir(handles.path, ...
    'Select the directory of export the database to');

% If a directory was selected
if ~isequal(path, 0)

    % Start timer
    t = tic;
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Export delta4, tomo, linac, and mobius tables
    tables = {'delta4', 'linac', 'tomo', 'mobius'};
    for i = 1:length(tables)
        Event(['Exporting ', tables{i}, ' table contents to ', ...
            fullfile(path, [tables{i}, '.csv'])]);
        handles.db.exportCSV(tables{i}, fullfile(path, [tables{i}, '.csv']));
    end

    % Display message box and log event
    Event(sprintf('Tables exported successfully to %s in %0.3f seconds', ...
        path, toc(t)));
    msgbox(sprintf('Tables exported successfully to %s', path), ...
        'Export Completed');
    
else
    Event('User did not select a path');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function import_Callback(hObject, ~, handles)
% hObject    handle to import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Open a dialog box for the user to select a directory
Event('UI window opened to select QA reports path');
path = uigetdir(handles.path, ...
    'Select the directory of IMRT QA reports to scan');

% If a directory was selected
if ~isequal(path, 0)

    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Retrieve list of reports and types
    ScanReports(path, 'db', handles.db, 'server', handles.m3d, ...
        'machines', handles.machines);
   
    % Update database summary table
    handles = UpdateSummary(handles);
    
    % Update plots
    plots = cellstr(get(handles.plot_types,'String'));
    PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
        plots{get(handles.plot_types,'Value')}, 'range', ...
        [handles.range_low, handles.range_high], 'stats', ...
        handles.plot_stats);
    clear plots;
   
else
    Event('User did not select a path');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function import_tomo_Callback(hObject, ~, handles)
% hObject    handle to import_tomo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Open a dialog box for the user to select a directory
Event('UI window opened to select Tomo archives path');
path = uigetdir(handles.path, ...
    'Select the directory of TomoTherapy archives to scan');

% If a directory was selected
if ~isequal(path, 0)

    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Retrieve list of reports and types
    ScanTomoArchives(path, 'db', handles.db);
   
    % Update database summary table
    handles = UpdateSummary(handles);
    
    % Update plots
    plots = cellstr(get(handles.plot_types,'String'));
    PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
        plots{get(handles.plot_types,'Value')}, 'range', ...
        [handles.range_low, handles.range_high], 'stats', ...
        handles.plot_stats);
    clear plots;
else
    Event('User did not select a path');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function match_records_Callback(hObject, ~, handles)
% hObject    handle to match_records (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute matchRecords
handles.db.matchRecords('delta4', 'tomo', 1440);

% Update database summary table
handles = UpdateSummary(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_stats_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to plot_stats (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% Update cell contents
data = get(hObject, 'Data');
if data{eventdata.Indices(1), 2}
    Event([data{eventdata.Indices(1), 1}, ' display enabled']);
elseif ~data{eventdata.Indices(1), 2}
    Event([data{eventdata.Indices(1), 1}, ' display disabled']);
end
set(hObject, 'Data', data);

% Update plots
plots = cellstr(get(handles.plot_types,'String'));
PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
    plots{get(handles.plot_types,'Value')}, 'range', [handles.range_low, ...
    handles.range_high], 'stats', hObject);
clear plots;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_types_Callback(hObject, ~, handles)
% hObject    handle to plot_types (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log choice
plots = cellstr(get(hObject, 'String'));
Event(['Plot changed to ', plots{get(hObject, 'Value')}]);

% Update plots
PlotData('type', plots{get(hObject,'Value')}, 'range', [handles.range_low, ...
    handles.range_high], 'parent', handles.plot_axes, 'db', handles.db, ...
    'stats', handles.plot_stats);
clear plots;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_types_CreateFcn(hObject, ~, ~)
% hObject    handle to plot_types (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function range_Callback(hObject, ~, handles)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve range options
options = cellstr(get(hObject,'String'));

% Update range limits based on selection
switch options{get(hObject, 'Value')}

case 'All Records'
    [handles.range_low, handles.range_high] = handles.db.recordRange();

case 'Last 30 Days'
    handles.range_high = now;
    handles.range_low = handles.range_high - 30;

case 'Last 90 Days'
    handles.range_high = now;
    handles.range_low = handles.range_high - 90;
    
case 'Last 1 Year'
    handles.range_high = now;
    handles.range_low = handles.range_high - 365;

case 'Custom Dates'
    a = inputdlg({'Enter lower date:','Enter upper date:'}, ...
        'Custom Date Range', 1, {datestr(now-30), datestr(now)});
    if ~isempty(a)
        handles.range_low = datenum(a{1});
        handles.range_high = datenum(a{2});
    end
otherwise
    Event('Invalid range choice selected');
end

% Update plots
plots = cellstr(get(handles.plot_types,'String'));
PlotData('parent', handles.plot_axes, 'db', handles.db, 'type', ...
    plots{get(handles.plot_types,'Value')}, 'range', [handles.range_low, ...
    handles.range_high], 'stats', handles.plot_stats);

% Clear temporary variables
clear options plots a;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function range_CreateFcn(hObject, ~, ~)
% hObject    handle to range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = UpdateSummary(handles)

table{1,1} = 'Number of QA Reports';
table{1,2} = sprintf('%i', handles.db.countReports());

table{size(table,1)+1,1} = 'QA Reports with RTPlans';
table{size(table,1),2} = sprintf('%0.1f%%', ...
    handles.db.countMatchedRecords() * 100);
table{size(table,1)+1,1} = 'Linac Reports';
table{size(table,1),2} = sprintf('%0.1f%%', ...
    handles.db.countReports('linac') / (handles.db.countReports()) * 100);
table{size(table,1)+1,1} = 'TomoTherapy Reports';
table{size(table,1),2} = sprintf('%0.1f%%', ...
    handles.db.countReports('tomo') / (handles.db.countReports()) * 100);
table{size(table,1)+1,1} = 'TomoTherapy RT Plans';
table{size(table,1),2} = sprintf('%i', handles.db.countPlans('tomo'));
table{size(table,1)+1,1} = 'Plans with Sinogram Data';
table{size(table,1),2} = sprintf('%0.1f%%', handles.db.countPlans('tomo', ...
    'sinogram IS NOT NULL') / handles.db.countPlans('tomo') * 100);

[low, high] = handles.db.recordRange();
table{size(table,1)+1,1} = 'Earliest Record';
if ~strcmp(low, 'null')
    table{size(table,1),2} = datestr(low, 'yyyy-mm-dd');
else
    table{size(table,1),2} = '';
end
table{size(table,1)+1,1} = 'Latest Record';
if ~strcmp(high, 'null')
    table{size(table,1),2} = datestr(high, 'yyyy-mm-dd');
else
    table{size(table,1),2} = '';
end
table{size(table,1)+1,1} = 'Database File';
table{size(table,1),2} = handles.dbFile;
table{size(table,1)+1,1} = 'Mobius3D Server';
table{size(table,1),2} = handles.m3d.server;
set(handles.dbinfo, 'Data', table);
clear table low high;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_plot_Callback(hObject, ~, handles)
% hObject    handle to save_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

plots = cellstr(get(handles.plot_types, 'String'));
ranges = cellstr(get(handles.range, 'String'));

% Prompt user to select a file to save the plot to
Event('UI window opened to save plot');
[file, path] = uiputfile([plots{get(handles.plot_types, 'Value')}, '.png'], ...
    'Save plot as');

% If a directory was selected
if ~isequal(file, 0)

    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Open new figure
    f = figure('Color', [1 1 1], 'Position', [100 100 400 300]);
    figure(f);

    % Plot data in new figure
    PlotData('parent', f, 'db', handles.db, 'type', ...
        plots{get(handles.plot_types,'Value')}, 'range', [handles.range_low, ...
        handles.range_high], 'stats', handles.plot_stats);
    
    % Add title to plot
    set(f, 'NextPlot', 'add');
    axes('FontSize', 12, 'FontName', 'Arial');
    h = title(sprintf('%s, %s\n', plots{get(handles.plot_types, 'Value')}, ...
        ranges{get(handles.range, 'Value')}));
    set(gca, 'Visible', 'off');
    set(h, 'Visible', 'on');
    
    % Save plot
    set(f, 'PaperUnits', 'centimeters');
    set(f, 'PaperPosition', [0 0 20 15]);
    saveas(f, fullfile(path, file));

    % Close figure
    close(f);
    
    % Display message box
    msgbox(sprintf('Figure exported successfully to %s', file), ...
        'Save Completed');
else
    Event('User did not select a save file');
end

% Clear temporary variables
clear file path plots f a;
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function copy_stats_Callback(hObject, ~, handles)
% hObject    handle to copy_stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Retrieve table contents
table = vertcat(get(handles.plot_stats, 'ColumnName')', ...
    get(handles.plot_stats, 'Data'));

% Remove "show" column
table = horzcat(table(:,1), table(:,3:end));

% Create tab delimited char array of table contents
str = [];
for i = 1:size(table,1); 
r = sprintf('%s\t', table{i,:});
r(end) = sprintf('\n');
str = [str r]; %#ok<AGROW>
end
clipboard('copy', str);

% Display message box
msgbox('Plot statistics have been copied to the clipboard', ...
    'Copy Statistics');

% Clear temporary variables
clear table str i r;
    
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figure1_SizeChangedFcn(hObject, ~, handles) %#ok<*DEFNU>
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set units to pixels
set(hObject,'Units','pixels') 

% Get table width
pos = get(handles.dbinfo, 'Position') .* ...
    get(handles.uipanel1, 'Position') .* ...
    get(hObject, 'Position');

% Update column widths to scale to new table size
set(handles.dbinfo, 'ColumnWidth', ...
    {floor(0.7*pos(3)) - 6 floor(0.3*pos(3))});

% Clear temporary variables
clear pos;
