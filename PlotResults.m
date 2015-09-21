function varargout = PlotResults(varargin)

% Specify plot options and order
plots = {
    'IMRT QA per Week'
    'Dose Diff Histogram'
    'Dose vs. Date (Machine)'
    'Dose vs. Date (Phantom)'
    'Gamma Index Histogram'
    'Gamma vs. Date (Machine)'
    'Gamma vs. Date (Phantom)'
};

% If no input arguments are provided
if nargin == 0
    
    % Return the plot options
    varargout{1} = plots;
    
    % Stop execution
    return;
end