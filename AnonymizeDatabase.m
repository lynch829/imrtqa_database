function AnonymizeDatabase(db)


% Add SQLite JDBC driver (current database is 3.8.5)
javaaddpath('./sqlite-jdbc-3.8.5-pre1.jar');

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Verify database file exists
if exist(fullfile(path, db), 'file') == 2

    % Store database, username, and password
    connection = database(fullfile(path, db), '', '', 'org.sqlite.JDBC', ...
        ['jdbc:sqlite:', fullfile(path, db)]);

    % Set the data return format to support strings
    setdbprefs('DataReturnFormat', 'cellarray');
else
    if exist('Event', 'file') == 2
        Event(['The SQLite3 database file could not be found: ', ...
            fullfile(path, db)], ...
            'ERROR');
    else
        error(['The SQLite3 database file could not be found: ', ...
            fullfile(path, db)]);
    end
end

% Log start
if exist('Event', 'file') == 2
    Event(['Anonymizing database ', db]);
    tic;
end

% Drop scannedfiles table
sql = 'DROP TABLE IF EXISTS scannedfiles';
exec(connection, sql);

% Drop delta4 table
sql = 'DROP TABLE IF EXISTS delta4';
exec(connection, sql);

% Drop tomo table
sql = 'DROP TABLE IF EXISTS tomo';
exec(connection, sql);

% Drop mobius table
sql = 'DROP TABLE IF EXISTS mobius';
exec(connection, sql);

%% Anonymize linac table
% Loop through each record
sql = 'SELECT uid FROM linac';
cursor = exec(connection, sql);
cursor = fetch(cursor);  
rows = cursor.Data;

% Loop through rows
for i = 1:length(rows)
    
    % Query id, name, and rtplan
    sql = ['SELECT id, name, rtplan FROM linac WHERE uid = ''', ...
        rows{i}, ''''];
    cursor = exec(connection, sql);
    cursor = fetch(cursor);  
    row = cursor.Data; 
    
    % Update id and name
    row{1} = sprintf('%04i', i);
    row{2} = sprintf('ANON%04i', i);
    
    % Replace id and name in RT plan
    row{3} = regexprep(row{3}, '"PatientID": "[^"]+"', ...
        ['"PatientID": "', sprintf('%04i', i),'"']);
    row{3} = regexprep(row{3}, '"PatientName": "[^"]+"', ...
        ['"PatientName": "', sprintf('ANON%04i', i),'"']);
    
    % Remove birthdate
    row{3} = regexprep(row{3}, '"PatientBirthDate": "[^"]+"', ...
        '"PatientBirthDate": ""');
    
    % Update record
    sql = ['UPDATE linac SET id = ''', row{1}, ''', name = ''', ...
        row{2}, ''', birthdate = null, rtplan = ''', row{3}, ''' WHERE uid = ''', rows{i}, ''''];
    exec(connection, sql);
end

% Log completion
if exist('Event', 'file') == 2
    Event(['Database anonymization completed successfully in ', ...
        sprintf('%0.3f', toc), ' seconds']);
    tic;
end

% Close database
close(connection);