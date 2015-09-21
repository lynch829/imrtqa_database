function varargout = QueryMobius(varargin)

% Declare persistent variables
persistent server user pass;

% Initialize patient variables
id = [];
plan = [];
date = [];

% Set default range to accept matched dates, in hours
range = 72;

% Define server's local UTC offset, in hours
utc = -5; % Central time

% Execute in try/catch statement
try

% Loop through input arguments
for i = 1:2:nargin
    
    % Store server variables
    if strcmpi(varargin{i}, 'server')
        server = varargin{i+1};
    elseif strcmpi(varargin{i}, 'user')
        user = varargin{i+1};
    elseif strcmpi(varargin{i}, 'pass')
        pass = varargin{i+1};
    end
    
    % Store patient variables
    if strcmpi(varargin{i}, 'id')
        id = varargin{i+1};
    elseif strcmpi(varargin{i}, 'plan')
        plan = varargin{i+1};
    elseif strcmpi(varargin{i}, 'date')
        if isdatetime(varargin{i+1})
            date = datenum(varargin{i+1});
        else
            date = varargin{i+1};
        end
    elseif strcmpi(varargin{i}, 'range')
        range = varargin{i+1};
    elseif strcmpi(varargin{i}, 'utc')
        utc = varargin{i+1};
    end
end
    
% If server variables are empty, throw an error
if exist('server', 'var') == 0 || isempty(server) || ...
        exist('user', 'var') == 0 || isempty(user) || ...
        exist('pass', 'var') == 0 || isempty(pass)

    % Log error
    if exist('Event', 'file') == 2
        Event('Server information is missing', 'ERROR');
    else
        error('Server information is missing');
    end
    
% If a patient ID was not provided
elseif isempty(id) || (isempty(plan) && isempty(date))
    
    % Log start
    if exist('Event', 'file') == 2
        Event('Querying Mobius3D for plan list');
        tic;
    end

% If a patient and plan was provided
elseif ~isempty(id) && ~isempty(plan)

    % Log start
    if exist('Event', 'file') == 2
        Event(['Querying Mobius3D for patient ', id, ' plan ', plan]);
        tic;
    end
    
% If a patient and plan date was provided
elseif ~isempty(id) && ~isempty(date)

    % Log start
    if exist('Event', 'file') == 2
        Event(['Querying Mobius3D for patient ', id, ' around date ', ...
            datestr(date)]);
        tic;
    end
end

% Verify Python can be executed
try
    version = py.sys.version;
    if exist('Event', 'file') == 2
        Event(['MATLAB is configured to use Python ', char(version)]);
    end    
    clear version;
catch
    if exist('Event', 'file') == 2
        Event(['Python can not be executed from MATLAB. Verify that a ', ...
            'compatible Python engine is installed.'], 'ERROR');
    else
        error(['Python can not be executed from MATLAB. Verify that a ', ...
            'compatible Python engine is installed.']);
    end
end

% Add jsonlab folder to search path
addpath('./jsonlab');

% Check if MATLAB can find XpdfText
if exist('loadjson', 'file') ~= 2
    
    % If not, throw an error
    Event(['The jsonlab/ submodule is missing. Download it from the ', ...
        'MathWorks.com website'], 'ERROR');
end

% Initialize Python batch file
try
    s = py.requests.Session();
catch
    if exist('Event', 'file') == 2
        Event('The Python requests library is not installed.', 'ERROR');
    else
        error('The Python requests library is not installed.');
    end
end

if exist('Event', 'file') == 2
    Event('Retrieving plan list');
end

try
    s.post(['http://', server, '/auth/login'], ...
        py.dict(pyargs('username', user, 'password', pass)));
    r = s.get(['http://', server, ...
        '/_plan/list?sort=date&descending=1&limit=99999']);
    patientList = r.json();
    
catch
    if exist('Event', 'file') == 2
        Event(['The server ', server, ' cannot be reached. Check your ', ...
            'network connection and try again.'], 'ERROR');
    else
        error(['The server ', server, ' cannot be reached. Check your ', ...
            'network connection and try again.']);
    end
end

if exist('Event', 'file') == 2
    Event(sprintf('Patient list retrieved in %0.3f seconds', ...
        double(r.elapsed.seconds) + double(r.elapsed.microseconds)/1e6));
end

% No patient information was provided, retrieve the JSON list and end
if isempty(id) || (isempty(plan) && isempty(date))
    json = loadjson(char(py.json.dumps(patientList)));

% Otherwise, search through the patient list for the provided patient ID
else
    
    % Initialize empty structure
    json = struct;
    
    % Loop over every patient
    for i = 1:length(patientList{'patients'})
        
        % Store patient
        patient = patientList{'patients'}{i};
        
        % If patient ID matches
        if strcmp(char(patient{'patientId'}), id)
            
            % If a plan name or date was provided
            if ~isempty(plan) || ~isempty(date)
            
                % Loop over every plan in the patient
                for j = 1:length(patient{'plans'})
                
                    % Store plan
                    planCheck = patient{'plans'}{j};
                    
                    % Skip if there aren't results (results will be empty)
                    if isempty(planCheck{'results'})
                        continue
                    end
                    
                    % Calculate MATLAB datenum of plan
                    d = str2double(planCheck{'created_timestamp'}) / 86400 + ...
                        datenum(1970,1,1,utc,0,0);
                    
                    % If this plan is the specified plan, or if the plan
                    % date
                    if (~isempty(plan) && strcmpi(char(planCheck{'notes'}), ...
                            plan)) || (~isempty(date) && d > (date - range) ...
                            && d < (date + range))
                        
                        if exist('Event', 'file') == 2
                            Event('Retrieving plan check JSON');
                        end
                        
                        % Retrieve JSON plan information
                        r = s.get(['http://', server, '/check/details/', ...
                            char(planCheck{'request_cid'}), '?format=json']);
                        planData = r.json();
                        
                        if exist('Event', 'file') == 2
                            Event(sprintf(['Plan check retrieved in %0.3f ', ...
                                'seconds'], double(r.elapsed.seconds) + ...
                                double(r.elapsed.microseconds)/1e6));
                        end
                        
                        % Only get data for M3D v1.2 plans and later
                        if planData{'version'}{1} < 1 || ...
                                planData{'version'}{2} < 2
                            continue
                        end
                        
                        % Retrieve JSON plan data
                        json = loadjson(char(py.json.dumps(planData)));
                        
                        % Check if an empty structure was returned
                        if ~isempty(fieldnames(json))
                            if exist('Event', 'file') == 2
                                Event(['Mobius3D plan check was found: ', ...
                                    char(planCheck{'request_cid'})]);
                            end
                        elseif exist('Event', 'file') == 2
                            Event('Mobius3D plan check was not found', ...
                                'WARN');
                        end
                            
                        break;
                    end
                end
            end
            
            break;
        end
    end
end

% Return Python return data
if nargout >= 1 
    
    % If JSON return argument is empty
    if isempty(fieldnames(json))
        varargout{1} = [];
    
    else
        if exist('Event', 'file') == 2
            Event('Parsing JSON into MATLAB structure return argument');
        end
        varargout{1} = json;
    end
end
    
% If user requested RT Plan file
if nargout >= 2

    % If a plan was found
    if ~isempty(id) && (~isempty(plan) || ~isempty(date)) && ...
            ~isempty(json) && isfield(json, 'settings')
    
        % Retrieve JSON RT Plan information
        if exist('Event', 'file') == 2
            Event(['Retrieving RT Plan UID ', ...
                json.settings.plan_dicom.sopinst]);
        end
        r = s.get(['http://', server, '/_dicom/view/', ...
            json.settings.plan_dicom.sopinst]);

        if exist('Event', 'file') == 2
            Event(sprintf(['RT Plan retrieved in %0.3f ', ...
                'seconds'], double(r.elapsed.seconds) + ...
                double(r.elapsed.microseconds)/1e6));
        end
        
        if exist('Event', 'file') == 2
            Event('Parsing JSON into MATLAB structure return argument');
        end
        
        % Replace all tag names with their Group/Element codes, using the
        % format GXXXXEXXXX
        varargout{2} = loadjson(regexprep(char(py.json.dumps(r.json())), ...
            '"\(([0-9a-z]+), ([0-9a-z]+)\)[^"]+"', '"G$1E$2"'));
    else
        varargout{2} = [];
    end
end
    
% Log finish
if exist('Event', 'file') == 2
    Event(sprintf(['Mobius3D query completed successfully in %0.3f', ...
        ' seconds'], toc));
end

% Clear temporary variables
clear i j json login patient patientList plan planData r s;

% Catch errors, log, and rethrow
catch err
    if exist('Event', 'file') == 2
        Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
    else
        rethrow(err);
    end
end


