function varargout = ScanReports(path, varargin)

% Inputs:
% Directory to scan
% (opt) Database handle
% (opt) Mobius info (server, user, pass)
% (opt) Machines list
%
% Outputs:
% Cell array of IMRT QA report structures

% Execute in try/catch statement
try
        
% Initialize optional variables
db = [];
server = [];
machines = [];

% Loop through input arguments
for i = 1:2:nargin-1
    
    % Store optional variables
    if strcmpi(varargin{i}, 'db')
        db = varargin{i+1};
    elseif strcmpi(varargin{i}, 'server')
        server = varargin{i+1};
    elseif strcmpi(varargin{i}, 'machines')
        machines = varargin{i+1};
    end
end

% Add xpdf_tools submodule to search path
addpath('./xpdf_tools');

% Check if MATLAB can find XpdfText
if exist('XpdfText', 'file') ~= 2
    
    % If not, throw an error
    Event(['The xpdf_tools submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

% Add dicom_tools submodule to search path
addpath('./dicom_tools');

% Check if MATLAB can find LoadJSONTomoPlan
if exist('LoadJSONTomoPlan', 'file') ~= 2
    
    % If not, throw an error
    Event(['The dicom_tools submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

% Add jsonlab submodule to search path
addpath('./jsonlab');

% Check if MATLAB can find loadjson
if exist('loadjson', 'file') ~= 2
    
    % If not, throw an error
    Event(['The jsonlab submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end


% Log start of search and start timer
Event(['Searching ', path, ' for IMRT QA reports']);
t = tic;

% Retrieve folder contents of directory
list = dir(path);

% Initialize folder counter
i = 0;

% Initialize plan counter
c = 0;

% Initialize database insert counter
d = 0;

% Initialize return variable
if nargout == 1
    varargout{1} = cell(0);
end

% If a valid screen size is returned (MATLAB was run without -nodisplay)
if usejava('jvm') && feature('ShowFigureWindows')
    
    % Start waitbar
    progress = waitbar(0, 'Searching directory for IMRT QA reports');
end

% Start recursive loop through each folder, subfolder
while i < size(list, 1)

    % Increment current folder being analyzed
    i = i + 1;
    
    % Update waitbar
    if exist('progress', 'var') && ishandle(progress)
        waitbar(i/size(list, 1), progress);
    end
    
    % If the folder content is . or .., skip to next folder in list
    if strcmp(list(i).name, '.') || strcmp(list(i).name, '..')
        continue
        
    % Otherwise, if the folder content is a subfolder    
    elseif list(i).isdir == 1
        
        % Retrieve the subfolder contents
        subList = dir(fullfile(path, list(i).name));
        
        % Look through the subfolder contents
        for j = 1:size(subList, 1)
            
            % If the subfolder content is . or .., skip to next subfolder 
            if strcmp(subList(j).name, '.') || ...
                    strcmp(subList(j).name, '..')
                continue
            else
                
                % Otherwise, replace the subfolder name with its full name
                subList(j).name = fullfile(list(i).name, subList(j).name);
            end
        end
        
        % Append the subfolder contents to the main folder list
        list = vertcat(list, subList); %#ok<AGROW>
        
        % Clear temporary variable
        clear subList;
        
    % Otherwise, if the file is a PDF file
    elseif size(strfind(lower(list(i).name), '.pdf'), 1) > 0
        
        % Increment plan counter
        c = c + 1;
        
        % Check if file was already scanned
        if ~isempty(db) && db.fileExists(fullfile(path, ...
                list(i).name)) > 0
            Event(['File ', list(i).name, ' was already parsed, skipping']);
            continue;
        end
        
        % Read PDF text contents
        content = XpdfText(path, list(i).name);
        
        % If the first page matches the format of a Delta4 IMRT QA report
        if size(strfind(content{1}{length(content{1})-1}, ...
                'ScandiDos AB'), 1) > 0

            % Update waitbar
            if exist('progress', 'var') && ishandle(progress)
                waitbar(i/size(list, 1), progress, ...
                    ['Loading Delta4 report ', list(i).name]);
            end
            
            % Parse Delta4 PDF report using first two pages
            delta4 = ParseD4report(horzcat(content{1}, content{2}));
            
            % Override plan name with title, if present
            if isfield(delta4, 'title') && ~strcmp(delta4.title, '')
                delta4.plan = delta4.title;
            end
            
            % Add text content to structure
            delta4.report = content;

            % Find type
            type = '';
            if ~isempty(machines) && isfield(delta4, 'machine')
                for j = 1:size(machines, 1)
                    if strcmp(delta4.machine, machines{j,1})
                        type = machines{j,2};
                        delta4.machineType = type;
                    end
                end
            end
            
            % Validate data
            if ~isfield(delta4, 'plan') || ~isfield(delta4, 'ID') || ...
                    ~isfield(delta4, 'planDate') || ...
                    ~isfield(delta4, 'machine') || ...
                    ~isfield(delta4, 'measDate')
               
                Event(['The parsed Delta4 report does not contain all ', ...
                    'necessary components, skipping'], 'WARN');
                
                % Execute addScannedFile to add to list of scanned files
                db.addScannedFile(fullfile(path, list(i).name));
                
                continue; 
            end

            % Add this plan to the return variable
            if nargout == 1
                varargout{1}{c} = delta4;
            end
            
            % If a Mobius3D server (and database) is provided
            if ~isempty(server) && ~isempty(db)
                  
                % Execute QueryMobius to search M3D server for plan
                Event(['Retrieving JSON and RTPLAN data from Mobius3D ', ...
                    'server']);
                [mobius, rtplan, dvh] = QueryMobius('server', server.server, ...
                    'user', server.user, 'pass', server.pass, ...
                    'id', delta4.ID, 'plan', delta4.plan);
                mobius.dvh = dvh;
                
                % If no data was returned, search again by date
                if isempty(mobius)
                    
                    Event(['Plan ', delta4.plan, ...
                        ' not found, searching by plan date']);
                    
                    [mobius, rtplan] = QueryMobius('id', delta4.ID, ...
                        'date', delta4.planDate);
                end
                
                % If Mobius3D data does not already exist in database
                if ~isempty(mobius) && ~isempty(db) && ...
                        db.dataExists(mobius, 'mobuis') == 0
                    
                    % Execute addRecord to add result to database
                    Event('Saving Mobius3D data into database');
                    delta4.mobiusuid = db.addRecord(mobius, 'mobius');
                    
                elseif ~isempty(mobius)
                    Event(['Mobius3D data already exists for this patient ', ...
                        'in the database']);
                else
                    Event(['No Mobius3D data exists, moving on to ', ...
                        'next patient']);
                end
            
                % If plan data was returned
                if ~isempty(rtplan)
                    
                    % Parse plan data based on machine type
                    switch type

                    case 'tomo'  
                        
                        % Execute LoadJSONTomoPlan to extract TomoTherapy 
                        % specific plan data
                        tomo = LoadJSONTomoPlan(rtplan);

                        % If TomoTherapy data does not already exist in the 
                        % database 
                        if db.dataExists(tomo, 'tomo') == 0

                            % Execute addRecord to add result to database
                            Event('Saving TomoTherapy data into database');
                            delta4.tomouid = db.addRecord(tomo, 'tomo');
                        else
                            Event(['TomoTherapy data already exists for this ', ...
                                'patient in the database']);
                        end

                    case 'linac'

                        % Execute LoadJSONPlan to extract plan data
                        linac = LoadJSONPlan(rtplan);

                        % If Linac data does not already exist in the database 
                        if db.dataExists(linac, 'linac') == 0

                            % Execute addRecord to add result to database
                            Event('Saving Linac data into database');
                            delta4.linacuid = db.addRecord(linac, 'linac');
                        else
                            Event(['Linac data already exists for this ', ...
                                'patient in the database']);
                        end
                    end
                else
                    Event(['No RT plan data exists, moving on to ', ...
                        'next patient']);
                end
            end
            
            % If Delta4 report does not already exist in database, add it
            if ~isempty(db)
                if db.dataExists(delta4, 'delta4') == 0
                
                    % Increment database counter
                    d = d + 1;
                    
                    % Execute addRecord to add result to database
                    Event('Saving Delta4 data into database');
                    db.addRecord(delta4, 'delta4');
                else
                    Event(['Delta4 data already exists for this patient ', ...
                        'in the database']);
                end
            end
            
            % Execute addScannedFile to add to list of scanned files
            db.addScannedFile(fullfile(path, list(i).name));
        end

        % Otherwise, if the page matches an ArcCHECK report
        

        % Otherwise, if the page matches a ViewRay point dose report
        
        
        % Clear temporary variables
        clear content plan delta4 mobius tomo linac rtplan;
    end
end

% Close waitbar
if exist('progress', 'var') && ishandle(progress)
    close(progress);
end

% If a valid screen size is returned (MATLAB was run without -nodisplay)
if usejava('jvm') && feature('ShowFigureWindows')
    msgbox(sprintf('Directory %s scan completed successfully', path), ...
        'Scan Reports Completed');
end

Event(sprintf(['Directory %s scan completed successfully in %0.3f', ...
    ' seconds, finding %i plans and uploading %i into the database'], ...
    path, toc(t), c, d));

% Catch errors, log, and rethrow
catch err
    
    % Delete progress handle if it exists
    if exist('progress', 'var') && ishandle(progress), delete(progress); end
    
    % Log error
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end