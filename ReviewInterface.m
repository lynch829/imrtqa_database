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

% Last Modified by GUIDE v2.5 18-Sep-2015 10:12:36

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
handles.version = '0.1';
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

% Log database load
Event(['Loading database file ', handles.dbFile]);

% Load file
handles.db = IMRTDatabase(fullfile(handles.path, handles.dbFile));

% Verify database has loaded
if isempty(handles.db.connection.URL)
    Event(['Could not open connection to ', handles.dbFile, ':', ...
        handles.db.connection.Message], 'ERROR');
end

% Set filter options
options = { 
    'All Records'
    'Last 30 Days'
    'Last 90 Days'
    'Custom'
};
set(handles.filter, 'String', options);
clear options;

% Set plot options
options = PlotResults();
set(handles.plot_types, 'String', options);
clear options;

% Diable plot list
set(handles.plot_types, 'enable', 'off');

% Disable plot
set(allchild(handles.plot_axes), 'visible', 'off'); 
set(handles.plot_axes, 'visible', 'off');
colorbar(handles.plot_axes,'off');

% Update database summary table
handles = UpdateSummary(handles);

% Log default path
Event(['Default file path set to ', handles.path]);

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
    
    % Update statistics table
    handles = UpdateStatistics(handles);
    
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
    
    % Update statistics table
    handles = UpdateStatistics(handles);
    
else
    Event('User did not select a path');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_types_Callback(hObject, eventdata, handles)
% hObject    handle to plot_types (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns plot_types contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plot_types


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
function filter_Callback(hObject, eventdata, handles)
% hObject    handle to filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns filter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from filter


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filter_CreateFcn(hObject, ~, ~)
% hObject    handle to filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = UpdateSummary(handles)

table = cell(6,2);
table{1,1} = 'Number of QA Reports';
table{1,2} = sprintf('%i', handles.db.countPlans());
table{2,1} = 'QA Reports with RTPlans';
table{2,2} = sprintf('%0.1f%%', handles.db.countMatchedRecords() * 100);
table{3,1} = 'Linac Plans';
table{3,2} = sprintf('%0.1f%%', handles.db.countPlans('linac') / ...
    (handles.db.countPlans() + 1E-6) * 100);
table{4,1} = 'TomoTherapy Plans';
table{4,2} = sprintf('%0.1f%%', handles.db.countPlans('tomo') / ...
    (handles.db.countPlans() + 1E-6) * 100);
table{5,1} = 'ViewRay Plans';
table{5,2} = sprintf('%0.1f%%', handles.db.countPlans('viewray') / ...
    (handles.db.countPlans() + 1E-6) * 100);
[low, high] = handles.db.planRange();
table{6,1} = 'Earliest Record';
if ~strcmp(low, 'null')
    table{6,2} = datestr(low, 'yyyy-mm-dd');
else
    table{6,2} = '';
end
table{7,1} = 'Latest Record';
if ~strcmp(high, 'null')
    table{7,2} = datestr(high, 'yyyy-mm-dd');
else
    table{7,2} = '';
end
table{8,1} = 'Database File';
table{8,2} = handles.dbFile;
table{9,1} = 'Mobius3D Server';
table{9,2} = handles.m3d.server;
set(handles.dbinfo, 'Data', table);
clear table low high;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = UpdateStatistics(handles)



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

% Get table width
pos = get(handles.stats, 'Position') .* ...
    get(handles.uipanel2, 'Position') .* ...
    get(hObject, 'Position');

% Update column widths to scale to new table size
set(handles.stats, 'ColumnWidth', ...
    {floor(0.7*pos(3)) - 6 floor(0.3*pos(3))});

% Clear temporary variables
clear pos;
