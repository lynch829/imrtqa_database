function varargout = ScanTomoArchives(path, varargin)

% Inputs:
% Directory to scan
% (opt) Database handle
%
% Outputs:
% Cell array of TomoTherapy plan structures

% Execute in try/catch statement
try
        
% Initialize optional variables
db = [];

% Set default range to accept matched dates, in hours
range = 72;

% Loop through input arguments
for i = 1:2:nargin-1
    
    % Store optional variables
    if strcmpi(varargin{i}, 'db')
        db = varargin{i+1};
    end
end

% Add xpdf_tools submodule to search path
addpath('./tomo_extract');

% Check if MATLAB can find LoadPlan
if exist('LoadPlan', 'file') ~= 2
    
    % If not, throw an error
    Event(['The tomo_exctract submodule does not exist in the search path. ', ...
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
Event(['Searching ', path, ' for TomoTherapy patient archives']);
t = tic;

% Retrieve folder contents of directory
list = dir(path);

% Initialize folder counter
i = 0;

% Initialize plan counter
c = 0;

% Initialize database insert and update counters
d = 0;
e = 0;

% Initialize return variable
if nargout == 1
    varargout{1} = cell(0);
end

% If a valid screen size is returned (MATLAB was run without -nodisplay)
if usejava('jvm') && feature('ShowFigureWindows')
    
    % Start waitbar
    progress = waitbar(0, ...
        'Searching directory for TomoTherapy patient archives');
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
    elseif size(strfind(lower(list(i).name), '_patient.xml'), 1) > 0
        
        % Increment plan counter
        c = c + 1;
                    
        % Check if XML was already scanned
        if ~isempty(db) && db.fileExists(fullfile(path, ...
                list(i).name)) > 0
            Event(['File ', list(i).name, ' was already parsed, skipping']);
            continue;
        end
        
        % Separate file name from full path
        [fullpath, name, ext] = fileparts(fullfile(path, list(i).name));
        patient = [name, ext];
        clear name ext;
        
        % Update waitbar
        if exist('progress', 'var') && ishandle(progress)
            waitbar(i/size(list, 1), progress, ...
                ['Loading TomoTherapy XML ', patient]);
        end

        % Find plan build and database version
        [~, version] = FindVersion(fullpath, patient);

        % If the database version is after 6 (when Tomo moved to characters)
        if isletter(version(1))

            % Retrieve all approved plan plan UIDs
            planUIDs = FindPlans(fullpath, patient);

            % If at least 1 plan was found
            if length(planUIDs) >= 1

                % Loop through plans
                for j = 1:length(planUIDs)
                    
                    % Retrieve Plan 
                    try
                        plan = LoadPlan(fullpath, patient, planUIDs{j}, ...
                            'noerrormsg');
                    catch
                        Event(['LoadPlan encountered an error, ', ...
                            'continuing to next plan'], 'CATCH');
                        continue
                    end
                    
                    % Add this plan to the return variable
                    if nargout == 1
                        varargout{1}{c} = plan;
                    end
                    
                    % If a database is provided
                    if ~isempty(db) 
                        
                        % Search for matching Tomo record using patient
                        % ID and plan name
                        tomo = db.queryRecords('tomo', 'id', ...
                            plan.patientID, 'plan', plan.planLabel);
                        
                        % Loop through matching Tomo records
                        found = 0;
                        for k = 1:length(tomo)
                            
                            % Add reference to tomo plan if plan date is
                            % within range
                            if tomo{k}.plandate < ...
                                    plan.timestamp + range/24 && ...
                                    tomo{k}.plandate > ...
                                    plan.timestamp - range/24
                                
                                % Update flag
                                found = 1;
                                e = e + 1;
                                
                                % Log update
                                Event(['TomoTherapy data already exists for ', ...
                                    'this patient in the database and will be ', ...
                                    'updated']);

                                % Delete the record
                                db.deleteRecords('tomo', 'uid', ...
                                    tomo{k}.uid);

                                % Insert a new record using the same UID
                                db.addRecord(plan, 'tomo', tomo{k}.uid);
                            end
                        end

                        % If no matching Tomo plan was found
                        if found == 0
                            
                            % Execute addRecord to add result to database
                            d = d + 1;
                            Event('Saving TomoTherapy data into database');
                            uid = db.addRecord(plan, 'tomo');

                            % Search for matching Delta4 record using patient
                            % ID and plan name
                            delta4 = db.queryRecords('delta4', 'id', ...
                                plan.patientID, 'plan', plan.planLabel);

                            % Loop through matching Delta4 records
                            for k = 1:length(delta4)

                                % Add reference to tomo plan if plan date is
                                % within range
                                if delta4{k}.plandate < ...
                                        plan.timestamp + range/24 && ...
                                        delta4{k}.plandate > ...
                                        plan.timestamp - range/24
                                    
                                    Event(['Updating Delta4 record UID ', ...
                                        delta4{k}.uid, ' to link to ', ...
                                        'TomoTherapy record UID ', uid]);
                                    
                                    db.updateRecords('delta4', {'tomouid'}, ...
                                        {uid}, 'uid', delta4{k}.uid);
                                end
                            end

                            % Clear temporary variables 
                            clear delta4;
                        end
                        
                        % Clear temporary variables
                        clear tomo;
                    end
                    
                    % Clear temporary variables
                    clear plan;
                end
                
            % Otherwise 
            else

                % Warn user no plans were found
                Event('No approved plans were found in the archive XML ', ...
                    patient);
            end
            
            % Clear temporary variables
            clear planUIDs;

        % Otherwise the file version is not supported   
        else

            % Log error
            Event(['Archive XML ', patient,' database version ', ...
                version, ' is not supported']);
        end
        
        % Execute addScannedFile to add to list of scanned files
        db.addScannedFile(fullfile(path, list(i).name));
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

% Log completion
Event(sprintf(['Directory %s scan completed successfully in %0.3f', ...
    ' seconds, finding %i plans, adding %i, and updating %i'], ...
    path, toc(t), c, d, e));
        
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
