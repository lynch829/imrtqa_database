function PlotBackground(orientation, range)
% Adds a red/yellow/green background to the currently selected plot
%
% Inputs: 
%   orientation: string, either 'vertical' or 'horizontal'
%   range: 4-element vector, in ascending order, indicating the lower red,
%       yellow, and upper yellow, red limits (in that order)

xl = xlim;
yl = ylim;

switch orientation
    
case 'vertical'
    
    p = patch([max(xl(1), range(2)) min(xl(2), range(3)) min(xl(2), ...
        range(3)) max(xl(1), range(2))], [yl(1) yl(1) yl(2) yl(2)], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([max(xl(1), range(1)) max(xl(1), range(2)) max(xl(1), ...
        range(2)) max(xl(1), range(1))], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([min(xl(2), range(3)) min(xl(2), range(4)) min(xl(2), ...
        range(4)) min(xl(2), range(3))], [yl(1) yl(1) yl(2) yl(2)], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) max(xl(1), range(1)) max(xl(1), range(1)) xl(1)], ...
        [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([min(xl(2), range(4)) xl(2) xl(2) min(xl(2), range(4))], ...
        [yl(1) yl(1) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    
case 'horizontal'

    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1), range(2)) max(yl(1), ...
        range(2)) min(yl(2), range(3)) min(yl(2), range(3))], 'green');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [max(yl(1), range(1)) max(yl(1), ...
        range(1)) max(yl(1), range(2)) max(yl(1), range(2))], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2), range(3)) min(yl(2), ...
        range(3)) min(yl(2), range(4)) min(yl(2), range(4))], 'yellow');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [yl(1) yl(1) ...
        max(yl(1), range(1)) max(yl(1), range(1))], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    p = patch([xl(1) xl(2) xl(2) xl(1)], [min(yl(2), range(4)) min(yl(2), ...
        range(4)) yl(2) yl(2)], 'red');
    p.EdgeAlpha = 0;
    p.FaceAlpha = 0.05;
    
end

xlim(xl);
ylim(yl);

clear xl yl p;