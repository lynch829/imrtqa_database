classdef IMRTDatabase
    
% Requires jsonlab
% Requires database toolbox
    
% Object variables
properties
    connection
end

% Functions
methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function obj = IMRTDatabase(db)
    % Constructor function

        % Add SQLite JDBC driver (current database is 3.8.5)
        javaaddpath('./sqlite-jdbc-3.8.5-pre1.jar');
    
        % Verify database file exists
        if exist(db, 'file') == 2
        
            % Store database, username, and password
            obj.connection = database(db, '', '', 'org.sqlite.JDBC', ...
                ['jdbc:sqlite:',db]);

            % Set the data return format to support strings
            setdbprefs('DataReturnFormat', 'cellarray')
        else
            if exist('Event', 'file') == 2
                Event(['The SQLite3 database file is missing', db], ...
                    'ERROR');
            else
                error(['The SQLite3 database file is missing', db]);
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function close(obj)
        close(obj.connection);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = countReports(obj, varargin)
    % Returns the size of the QA report cell array based on an optional 
    % machine name

        % If a type was not provided
        if nargin == 1

            % Return the size of the delta4 table
            sql = 'SELECT COUNT(uid) FROM delta4';
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            close(cursor);
            
        % Otherwise, count only the given type
        else
         
            % Return the size of the delta4 table
            sql = ['SELECT COUNT(uid) FROM delta4 WHERE machinetype = ''', ...
                varargin{1}, ''''];
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            close(cursor);
        end
        
        % Clear temporary variables
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = countMatchedRecords(obj)
    % Returns the number of records in the reports tables that contain 
    % linked plan data
        
        % Return the size of the delta4 table
        sql = ['SELECT COUNT(uid) FROM delta4 WHERE linacuid IS NULL AND', ...
            ' tomouid IS NULL'];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        n = cursor.Data{1};
        sql = 'SELECT COUNT(uid) FROM delta4';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor); 
        n = 1 - n/cursor.Data{1};
        close(cursor);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = countPlans(obj, varargin)
    % Returns the size of the plan cell array based on an optional 
    % table and/or SQL where statement

        % If a type was not provided
        if nargin == 1

            % Query the size of the tomo table
            sql = 'SELECT COUNT(uid) FROM tomo';
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            
            % Query the size of the linac table
            sql = 'SELECT COUNT(uid) FROM linac';
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = n + cursor.Data{1};
            close(cursor);
            
        % Otherwise, count only the given type
        else
         
            % Return the size of the listed table
            sql = ['SELECT COUNT(uid) FROM ', varargin{1}];
            
            % Add where statement
            if nargin == 3
                sql = [sql, ' WHERE ', varargin{2}];
            end
            cursor = exec(obj.connection, sql);
            cursor = fetch(cursor);  
            n = cursor.Data{1};
            close(cursor);
        end
        
        % Clear temporary variables
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function data = queryColumns(obj, varargin)
    % Returns an array of associated database parameters within the set 
    % filter range given a list of table/column pairs. If multiple columns
    % are queried, only results that include matching data (across all
    % tables/columns are returned). Note, the first table/column must be a 
    % report table that contains uid reference columns to the other tables.
   
        % Loop through the arguments, prepending the table name to the col
        for i = 1:2:nargin-1
            varargin{i+1} = [varargin{i}, '.', varargin{i+1}];
        end
        
        % Initialize SQL query string
        sql = ['SELECT ', strjoin(varargin(2:2:end), ', '), ' FROM ', ...
            varargin{1}];
        
        % Add join statements if second db doesn't match first one
        for i = 3:2:nargin-1
            if ~strcmp(varargin{1}, varargin{i})
                sql = [sql, ' LEFT JOIN ', varargin{i}, ' ON ', varargin{i}, ...
                    '.uid = ', varargin{1}, '.', varargin{i}, 'uid']; %#ok<*AGROW>
            end
        end
        
        % Add where statements
        sql = [sql, ' WHERE ', varargin{2}, ' IS NOT NULL'];
        for i = 3:2:nargin-1
            sql = [sql, ' AND ', varargin{i+1}, ' IS NOT NULL'];
        end
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);
        data = cursor.Data;
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function data = queryRecords(obj, table, varargin)
    % Returns an array of name/value structure pairs from a specified table
    % that matches one or more provided column name/value pairs.
    
        % Retrieve column names and data types
        sql = ['PRAGMA table_info(', table, ')'];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        cols = cursor.Data;
        
        % Initialize select statement
        sql = ['SELECT ', strjoin(cols(:,2), ', '), ' FROM ', table];
        
        % If where arguments are provided
        if nargin >= 4
            
            % Add first where statement
            sql = [sql, ' WHERE ', varargin{1}, ' = ''', ...
                strrep(varargin{2}, '''', ''), ''''];
            
            % Add subsequent where statements
            for i = 3:2:nargin-2
                
                sql = [sql, ' AND ', varargin{i}, ' = ''', ...
                    strrep(varargin{i+1}, '''', ''), ''''];
            end
        end
        
        % Execute query
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);
        
        % Store return data a cell array of structures
        if ~strcmp(cursor.Data{1,1}, 'No Data')
            data = cell(size(cursor.Data,1),1);
            for i = 1:size(cursor.Data,1)
                for j = 1:size(cols,1)
                    data{i}.(cols{j,2}) = cursor.Data{i,j};
                end
            end
        else
            data = cell(0);
        end
        
        % Clear temporary variables
        clear sql cursor cols;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function deleteRecords(obj, table, varargin)
    % Returns an array of name/value structure pairs from a specified table
    % that matches one or more provided column name/value pairs.
        
        % Initialize select statement
        sql = ['DELETE FROM ', table];
        
        % If where arguments are provided
        if nargin >= 4
            
            % Add first where statement
            sql = [sql, ' WHERE ', varargin{1}, ' = ''', ...
                strrep(varargin{2}, '''', ''), ''''];
            
            % Add subsequent where statements
            for i = 3:2:nargin-2
                
                sql = [sql, ' AND ', varargin{i}, ' = ''', ...
                    strrep(varargin{i+1}, '''', ''), ''''];
            end
        end
        
        % Execute delete
        exec(obj.connection, sql);
        
        % Clear temporary variables
        clear sql;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function updateRecords(obj, table, colnames, data, varargin)
    % Updates one or more table column names with data where the row
    % matches one or more provided column name/value pairs.
   
        % If where arguments are provided
        sql = '';
        if nargin >= 6
            
            % Add first where statement
            sql = [sql, ' WHERE ', varargin{1}, ' = ''', ...
                strrep(varargin{2}, '''', ''), ''''];
            
            % Add subsequent where statements
            for i = 3:2:nargin-4
                
                sql = [sql, ' AND ', varargin{i}, ' = ''', ...
                    strrep(varargin{i+1}, '''', ''), ''''];
            end
        end
        
        % Update table
        update(obj.connection, table, colnames, data, sql);
        
        % Clear temporary variables
        clear sql;
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = fileExists(obj, file)
    % Retrieves the high and low filter ranges 
        
        % Query the record based on the patient ID, plan, and date
        sql = ['SELECT COUNT(fullfile) FROM scannedfiles WHERE fullfile = ''', ...
            file, ''''];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        n = cursor.Data{1};
        close(cursor);
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function addScannedFile(obj, file)
        
        % Insert row into database
        datainsert(obj.connection, 'scannedfiles', {'fullfile'}, {file});
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [low, high] = recordRange(obj)
    % Retrieves the range of timestamps for plan
        
        % Query the highest and lowest plan dates from delta4 table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM delta4';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = cursor.Data{1};
        high = cursor.Data{2};
        
        % Query the highest and lowest plan dates from tomo table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM tomo';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = min(low, cursor.Data{1});
        high = max(high, cursor.Data{2});
        
        % Query the highest and lowest plan dates from linac table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM linac';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = min(low, cursor.Data{1});
        high = max(high, cursor.Data{2});
        
        % Query the highest and lowest plan dates from mobius table
        sql = 'SELECT MIN(plandate), MAX(plandate) FROM mobius';
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        low = min(low, cursor.Data{1});
        high = max(high, cursor.Data{2});
        
        close(cursor);
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function n = dataExists(obj, record, type)
    % Searches the database for a record of given type, returning 0 or 1    
    
        % Initialize return variable
        n = 0;
        
        % Query table based on record type
        switch type
            
        case 'delta4'

            % If the fields exist
            if isfield(record, 'ID') && isfield(record, 'plan') && ...
                    isfield(record, 'planDate')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM delta4 WHERE id = ''', ...
                    record.ID, ''' AND plan = ''', record.plan, ''' AND ', ...
                    'plandate = ''', sprintf('%0.10f', ...
                    datenum(record.planDate)), ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        case 'tomo'

            % If the fields exist
            if isfield(record, 'patientID') && isfield(record, 'planLabel') && ...
                    isfield(record, 'timestamp')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM tomo WHERE id = ''', ...
                    record.patientID, ''' AND plan = ''', ...
                    record.planLabel, ''' AND plandate = ''', ...
                    sprintf('%0.10f', datenum(record.timestamp)), ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        case 'linac'

            % If the fields exist
            if isfield(record, 'PatientID') && isfield(record, 'RTPlanName') ...
                    && isfield(record, 'RTPlanDate') ...
                    && isfield(record, 'RTPlanTime')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM linac WHERE id = ''', ...
                    record.PatientID, ''' AND plan = ''', record.RTPlanName, ...
                    ''' AND plandate = ''', sprintf('%0.10f', ...
                    datenum([record.RTPlanDate, '-', record.RTPlanTime], ...
                    'yyyymmdd-HHMMSS')), ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        case 'mobius'

            % If the fields exist
            if isfield(record, 'settings')
                
                % Query the record based on the patient ID, plan, and date
                sql = ['SELECT COUNT(uid) FROM mobius WHERE id = ''', ...
                    record.settings.planInfo_dict.Patient.PatientID, ...
                    ''' AND plan = ''', ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanName, ...
                    ''' AND plandate = ''', sprintf('%0.10f', datenum(...
                    [record.settings.planInfo_dict.RTGeneralPlan.RTPlanDate, ...
                    '-', ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanDate])), ...
                    ''''];
                cursor = exec(obj.connection, sql);
                cursor = fetch(cursor);  
                n = cursor.Data{1};
                close(cursor);
            end

        otherwise
            n = 0;
        end
        
        % Clear cursor
        clear sql cursor;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function uid = addRecord(obj, record, type, varargin)
    % Adds a record of given type to the database     
        
        % Initialize data cell array
        data = cell(0);
        uid = [];
    
        % Query table based on record type
        switch type
            
        case 'delta4'

            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'ID')
                data{2,2} = record.ID;
            end
            data{3,1} = 'name';
            if isfield(record, 'name')
                data{3,2} = record.name;
            end
            data{4,1} = 'clinic';
            if isfield(record, 'clinic')
                data{4,2} = strjoin(record.clinic, '\n');
            end
            data{5,1} = 'plan';
            if isfield(record, 'plan')
                data{5,2} = record.plan;
            end
            data{6,1} = 'plandate';
            if isfield(record, 'planDate')
                data{6,2} = sprintf('%0.10f', datenum(record.planDate));
            end
            data{7,1} = 'planuser';
            if isfield(record, 'planUser')
                data{7,2} = record.planUser;
            end
            data{8,1} = 'measdate';
            if isfield(record, 'measDate')
                data{8,2} = sprintf('%0.10f', datenum(record.measDate));
            end
            data{9,1} = 'measuser';
            if isfield(record, 'measUser')
                data{9,2} = record.measUser;
            end
            data{10,1} = 'reviewstatus';
            if isfield(record, 'reviewStatus')
                data{10,2} = record.reviewStatus;
            end
            data{11,1} = 'reviewdate';
            if isfield(record, 'reviewDate')
                data{11,2} = sprintf('%0.10f', ...
                    datenum(record.reviewDate));
            end
            data{12,1} = 'reviewuser';
            if isfield(record, 'reviewUser')
                data{12,2} = record.reviewUser;
            end
            data{13,1} = 'comments';
            if isfield(record, 'comments')
                data{13,2} = strjoin(record.comments, '\n');
            end
            data{14,1} = 'phantom';
            if isfield(record, 'phantom')
               data{14,2} = record.phantom;
            end
            data{15,1} = 'students';
            if isfield(record, 'students')
                data{15,2} = record.students;
            end
            data{16,1} = 'cumulativemu';
            if isfield(record, 'cumulativeMU')
                data{16,2} = record.cumulativeMU;
            end
            data{17,1} = 'expectedmu';
            if isfield(record, 'expectedMU')
                data{17,2} = record.expectedMU;
            end
            data{18,1} = 'machine';
            if isfield(record, 'machine')
                data{18,2} = record.machine;
            end
            data{19,1} = 'temperature';
            if isfield(record, 'temperature')
                data{19,2} = record.temperature;
            end
            data{20,1} = 'reference';
            if isfield(record, 'reference')
                data{20,2} = record.reference;
            end
            data{21,1} = 'normdose';
            if isfield(record, 'normDose')
                data{21,2} = record.normDose;
            end
            data{22,1} = 'abs';
            if isfield(record, 'abs')
                data{22,2} = record.abs;
            end
            data{23,1} = 'dta';
            if isfield(record, 'dta')
                data{23,2} = record.dta;
            end
            data{24,1} = 'abspassrate';
            if isfield(record, 'absPassRate')
                data{24,2} = record.absPassRate;
            end
            data{25,1} = 'dtapassrate';
            if isfield(record, 'dtaPassRate')
                data{25,2} = record.dtaPassRate;
            end
            data{26,1} = 'gammapassrate';
            if isfield(record, 'gammaPassRate')
                data{26,2} = record.gammaPassRate;
            end
            data{27,1} = 'dosedev';
            if isfield(record, 'doseDev')
                data{27,2} = record.doseDev;
            end
            data{28,1} = 'report';
            if isfield(record, 'report')
                 data{28,2} = savejson('report', record.report);
            end
            data{29,1} = 'machinetype';
            if isfield(record, 'machineType')
                 data{29,2} = record.machineType;
            end
            data{30,1} = 'mobiusuid';
            if isfield(record, 'mobiusuid')
                 data{30,2} = record.mobiusuid;
            end
            data{31,1} = 'tomouid';
            if isfield(record, 'tomouid')
                 data{31,2} = record.tomouid;
            end
            data{32,1} = 'linacuid';
            if isfield(record, 'linacuid')
                 data{32,2} = record.linacuid;
            end

            % Insert row into database
            datainsert(obj.connection, 'delta4', data(:,1)', data(:,2)');
        
        case 'tomo'
        
            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'patientID')
                data{2,2} = record.patientID;
            end
            data{3,1} = 'name';
            if isfield(record, 'patientName')
                data{3,2} = record.patientName;
            end
            data{4,1} = 'plan';
            if isfield(record, 'planLabel')
                data{4,2} = record.planLabel;
            end
            data{5,1} = 'plandate';
            if isfield(record, 'timestamp')
                data{5,2} = sprintf('%0.10f', datenum(record.timestamp));
            end
            data{6,1} = 'machine';
            if isfield(record, 'machine')
                data{6,2} = record.machine;
            end
            data{7,1} = 'gantrymode';
            if isfield(record, 'planType')
                data{7,2} = record.planType;
            end
            data{8,1} = 'jawmode';
            if isfield(record, 'jawType')
                data{8,2} = record.jawType;
            end
            data{9,1} = 'pitch';
            if isfield(record, 'pitch')
                data{9,2} = record.pitch;
            end
            data{10,1} = 'fieldwidth';
            if isfield(record, 'fieldWidth')
                data{10,2} = record.fieldWidth;
            elseif isfield(record, 'frontField') && ...
                    isfield(record, 'backField')
                data{10,2} = abs(record.frontField) + abs(record.backField);
            end
            data{11,1} = 'period';
            if isfield(record, 'planType') && isfield(record, 'events') ...
                        && strcmp(record.planType, 'Helical')
                for i = 1:size(record.events, 1)
                    if strcmp(record.events{i,2}, 'gantryRate')
                        data{11,2} = record.events{i,3} * 51;
                        break
                    end
                end
            end
            data{12,1} = 'couchspeed';
            if isfield(record, 'events') && isfield(record, 'scale') 
                for i = 1:size(record.events, 1)
                    if strcmp(record.events{i,2}, 'isoZRate')
                        data{12,2} = record.events{i,3} * record.scale;
                        break
                    end
                end
            end
            data{13,1} = 'couchlength';
            if isfield(record, 'events') && isfield(record, 'totalTau') 
                for i = 1:size(record.events, 1)
                    if strcmp(record.events{i,2}, 'isoZRate')
                        data{13,2} = record.events{i,3} * record.totalTau;
                        break
                    end
                end
            end
            data{14,1} = 'planmod';
            if isfield(record, 'modFactor')
                data{14,2} = record.modFactor;
            end
            data{15,1} = 'actualmod';
            if isfield(record, 'sinogram')
                lots = reshape(record.sinogram, 1, []);
                lots(lots == 0) = [];
                data{15,2} = max(lots)/mean(lots);
                clear lots;
            end
            data{16,1} = 'sinogram';
            if isfield(record, 'sinogram')
                data{16,2} = sprintf('%0.32e\t', record.sinogram);
            end
            data{17,1} = 'rtplan';
            data{17,2} = savejson('rtplan', record);
            
            % Insert row into database
            datainsert(obj.connection, 'tomo', data(:,1)', data(:,2)');
            
        case 'linac'
            
            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'PatientID')
                data{2,2} = record.PatientID;
            end
            data{3,1} = 'name';
            if isfield(record, 'PatientName')
                data{3,2} = record.PatientName;
            end
            data{4,1} = 'plan';
            if isfield(record, 'RTPlanName')
                data{4,2} = record.RTPlanName;
            end
            data{5,1} = 'plandate';
            if isfield(record, 'RTPlanDate')
                data{5,2} = sprintf('%0.10f', datenum([record.RTPlanDate, ...
                    '-', record.RTPlanTime], 'yyyymmdd-HHMMSS'));
            end
            data{6,1} = 'machine';
            if isfield(record, 'BeamSequence') && ...
                    isfield(record.BeamSequence, 'Item_1') && ...
                    isfield(record.BeamSequence.Item_1, ...
                    'TreatmentMachineName')
                data{6,2} = record.BeamSequence.Item_1.TreatmentMachineName;
            end
            data{7,1} = 'tps';
            if isfield(record, 'ManufacturerModelName')
                data{7,2} = record.ManufacturerModelName;
            end
            data{8,1} = 'mode';
            if isfield(record, 'BeamSequence') && ...
                    isfield(record.BeamSequence, 'Item_1') && ...
                    isfield(record.BeamSequence.Item_1, ...
                    'BeamType')
                data{8,2} = record.BeamSequence.Item_1.BeamType;
            end
            data{9,1} = 'numbeams';
            if isfield(record, 'BeamSequence')
                data{9,2} = length(fieldnames(record.BeamSequence));
            end
            data{10,1} = 'numcps';
            if isfield(record, 'BeamSequence')
                cps = 0;
                for i = 1:length(fieldnames(record.BeamSequence))
                    if isfield(record.BeamSequence.(sprintf('Item_%i', i)), ...
                            'NumberOfControlPoints')
                        cps = cps + record.BeamSequence...
                            .(sprintf('Item_%i', i)).NumberOfControlPoints;
                    end
                end
                data{10,2} = cps;
            end
            data{11,1} = 'rtplan';
            data{11,2} = savejson('rtplan', record);
            
            % Insert row into database
            datainsert(obj.connection, 'linac', data(:,1)', data(:,2)');
            
        case 'mobius'
            
            % Generate cell array of table columns and data
            data{1,1} = 'uid';
            if nargin == 4
                uid = varargin{1};
            else
                uid = dicomuid;
            end
            data{1,2} = uid;
            data{2,1} = 'id';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{2,2} = ...
                    record.settings.planInfo_dict.Patient.PatientID;
            end
            data{3,1} = 'name';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{3,2} = ...
                    record.settings.planInfo_dict.Patient.PatientsName;
            end
            data{4,1} = 'plan';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{4,2} = ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanName;
            end
            data{5,1} = 'plandate';
            if isfield(record, 'settings') && isfield(record.settings, ...
                    'planInfo_dict')
                data{5,2} = sprintf('%0.10f', datenum([record.settings...
                    .planInfo_dict.RTGeneralPlan.RTPlanDate, '-', ...
                    record.settings.planInfo_dict.RTGeneralPlan.RTPlanTime], ...
                    'yyyymmdd-HHMMSS'));
            end
            data{6,1} = 'abs';
            if isfield(record, 'data') && isfield(record.data, ...
                    'gamma_result') && ~isempty(record.data.gamma_result)
                data{6,2} = ...
                    record.data.gamma_result.criteria.dose.value * 100;
            end
            data{7,1} = 'dta';
            if isfield(record, 'data') && isfield(record.data, ...
                    'gamma_result') && ~isempty(record.data.gamma_result)
                data{7,2} = ...
                    record.data.gamma_result.criteria.maxDTA_mm.value;
            end
            data{8,1} = 'gammapassrate';
            if isfield(record, 'data') && isfield(record.data, ...
                    'gamma_result') && ~isempty(record.data.gamma_result)
                data{8,2} = ...
                    record.data.gamma_result.passingRate.value * 100;
            end
            data{9,1} = 'version';
            if isfield(record, 'version')
                data{9,2} = record.version{4};
            end
            data{10,1} = 'plancheck';
            data{10,2} = savejson('plancheck', record);
            
            % Insert row into database
            datainsert(obj.connection, 'mobius', data(:,1)', data(:,2)');
        end
        
        % Clear temporary variables
        clear data;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function exportCSV(obj, table, file)
        
        % Open handle to file
        fid = fopen(file, 'w');
        
        % Retrieve column names and data types
        sql = ['PRAGMA table_info(', table, ')'];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor);  
        cols = cursor.Data;
        
        % Write column names to first row
        fprintf(fid, '%s,\n', strjoin(cols(:,2), ', '));
        
        % Query data
        sql = ['SELECT ', strjoin(cols(:,2), ', '), ' FROM ', table];
        cursor = exec(obj.connection, sql);
        cursor = fetch(cursor); 
        
        % Write data
        for i = 1:size(cursor.Data,1)
            for j = 1:size(cursor.Data,2)
                if ~isempty(regexp(cols{j,2}, 'date', 'ONCE'))
                    if cursor.Data{i,j} > 0
                        fprintf(fid, '%s,', datestr(cursor.Data{i,j}));
                    else
                        fprintf(fid, ',');
                    end
                elseif strcmp(cols{j,3}, 'float')
                    fprintf(fid, '%f,', cursor.Data{i,j});
                elseif strcmp(cols{j,3}, 'int')
                    fprintf(fid, '%i,', cursor.Data{i,j});
                elseif strcmp(cols{j,3}, 'blob')
                    fprintf(fid, ',');
                else
                    fprintf(fid, '%s,', regexprep(cursor.Data{i,j}, ...
                       '[\n\,]', ' '));
                end
            end
            fprintf(fid, '\n');
        end
        
        % Close file handle
        fclose(fid);
        
        % Clear temporary variables
        clear fid sql cursor cols;
    end
end
end
                