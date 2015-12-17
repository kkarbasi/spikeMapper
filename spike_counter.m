%% spike_counter.m
%   Author: Kaveh Karbasi
%   The Miller lab, University of California, Berkeley.
%   Created: October 2015
%---------------------------------------------------------------------
% This function:
% gets a trace as an input and returns the number of spikes
% that it detects in that trace.
%---------------------------------------------------------------------

function [nspikes , spike_times] = spike_counter(trace , polynomial_order , sd_treshold , re_arm_gap)

    %------ Configuration Variables------
%     polynomial_order = 10;
%     sd_treshold =3;
    %-----------------------------------

    % Flatten the trace using polynomial regression
    timeStamps = 1:numel(trace);
    p = polyfit(timeStamps , trace , polynomial_order);
    y = polyval(p, timeStamps);
    minY = min(y);
    flatY = y-minY;
    ftrace = trace - flatY;

    % Calculate trace's mean and standard deviation:
    baseSD = std(ftrace);
    baseM = median(ftrace);

    % Subtract sd_treshold*baseSD from the flattened trace. Whats left are the spikes
    tmp = ftrace - (baseM + sd_treshold*baseSD);
    tmp(tmp<0) = 0;
    
    spike_times = find(tmp);
    
    spike_times = burstAggregator(spike_times , re_arm_gap);
    nspikes = numel(spike_times);
    
    % Count the number of spikes in the trace
%     nspikes = nnz(tmp);

end