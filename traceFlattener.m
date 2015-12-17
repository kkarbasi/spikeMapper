%% trceFlattener.m
% It takes an input trace and an integer representing the regression order
% to be fit to the baseline and returs the flattened (bleach corrected)
% trace

function flattenedTrace = traceFlattener(trace , polynomial_order)
     

    % Flatten the trace using polynomial regression
    timeStamps = 1:numel(trace);
    p = polyfit(timeStamps , trace , polynomial_order);
    y = polyval(p, timeStamps);
    minY = min(y);
    flatY = y-minY;
    flattenedTrace = trace - flatY;


end