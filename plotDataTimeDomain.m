function [ plotHandle ] = plotDataTimeDomain(data, freqIndex, tStarth, tEndh, timeScaleFactor, reductionFactor, plotIdentifiers)
%PLOTDATATIMEDOMAIN Plotting raw data in the time domain
%
%   H = PLOTDATATIMEDOMAIN(D, F) plots all data in D at the frequency
%   with index F
%
%   H = PLOTDATATIMEDOMAIN(D, F, S) plots all data in D at the frequency
%   with index F from time S. S is hours counted from the first sample
%
%   H = PLOTDATATIMEDOMAIN(D, F, S, E) plots the data in D at the frequency
%   with index F from time S until E. S and E are hours counted from the
%   first sample
%
%   H = PLOTDATATIMEDOMAIN(D, F, S, E, T) plots the data in D at the frequency
%   with index F from time S until E. S and E are hours counted from the
%   first sample. T (1, 60, 3600, 86400) scales the time axis from seconds
%   to minutes, hours or days. 
%
%   H = PLOTDATATIMEDOMAIN(D, F, S, E, T, R) plots the data in D at the frequency
%   with index F from time S until E. S and E are hours counted from the
%   first sample. E (1, 60, 3600, 86400) scales the time axis from seconds
%   to minutes, hours or days. The data is reduced by the factor R, thus
%   for R=10 only every 10th data point is plotted
%
%   H = PLOTDATATIMEDOMAIN(D, F, S, E, R, T, I) plots the data in D at the frequency
%   with index F from time S until E. S and E are hours counted from the
%   first sample. E (1, 60, 3600, 86400) scales the time axis from seconds
%   to minutes, hours or days. The data is reduced by the factor R, thus
%   for R=10 only every 10th data point is plotted. I is a string selecting
%   the plots to be created, it can contain any or all of the following:
%       'mag'   - plots the signal magnitude
%       'phase' - plots the signal phase
%       'bits'  - plots the DIO bits
%   Combinations such as 'mag phase bits' displays those three plots.
% 
%   sebastian.buergel@bsse.etz.ch, 2015

    narginchk(2, 7);
    if nargin == 2 % assume we want to plot everything in s, no reduction
        tStarth = 0;
        tEndh = inf;
        timeScaleFactor = 1;
        reductionFactor = 1;
        plotIdentifiers = 'mag phase bits';
    elseif nargin == 3 % assume we want to plot until last sample in s, no reduction
        tEndh = inf;
        timeScaleFactor = 1;
        reductionFactor = 1;
        plotIdentifiers = 'mag phase bits';
    elseif nargin == 4 % assume we want to plot in s, no reduction
        timeScaleFactor = 1;
        reductionFactor = 1;
        plotIdentifiers = 'mag phase bits';
    elseif nargin == 5 % assume we do not want to reduce the data
        reductionFactor = 1;
        plotIdentifiers = 'mag phase bits';
    elseif nargin == 6 % assume we want to plot everything
        plotIdentifiers = 'mag phase bits';
    end
    % estimating the unit in the label of the x-axis
    timeUnitStr = '';
    if (timeScaleFactor == 1)
        timeUnitStr = 's';
    elseif (timeScaleFactor == 60)
        timeUnitStr = 'min';
    elseif (timeScaleFactor == 3600)
        timeUnitStr = 'h';
    elseif (timeScaleFactor == 86400)
        timeUnitStr = 'd';
    else
        timeUnitStr = [num2str(timeScaleFactor), 's'];
    end
    
    % finding start and end point in samples
    ts = data.ts(1:1:end) - data.ts(1);
    iStart = find(ts/3600 > tStarth, 1);
    iEnd = find(ts/3600 > tEndh, 1);
    if (isempty(iStart))
        iStart = 1;
    end
    if (isempty(iEnd))
        iEnd = size(ts,1);
    end
    
    % cropping and reducing data for plotting
    ts = ts(iStart:reductionFactor:iEnd);
    mag = data.mag(iStart:reductionFactor:iEnd, freqIndex);
    phi = data.phase(iStart:reductionFactor:iEnd);
    bits = data.bits(iStart:reductionFactor:iEnd);% - min(data.bits);
    freq = data.f(freqIndex);
    
    % estimating the unit in the label of the y-axis
    freqString = '';
    if (freq > 1e9)
        freqString = [num2str(freq/1e9), ' GHz'];
    elseif (freq > 1e6)
        freqString = [num2str(freq/1e6), ' MHz'];
    elseif (freq > 1e3)
        freqString = [num2str(freq/1e3), ' kHz'];
    else
        freqString = [num2str(freq), ' Hz'];
    end

    % make plots
    if (~isempty(strfind(plotIdentifiers,'mag')))
        figure(1);
        plotHandle = plot(ts./timeScaleFactor, mag, 'black');
        set(plotHandle, 'LineWidth', 1);
        xlabel(['Time [', timeUnitStr, ']']);
        ylabel([freqString, ' Signal magnitude [V]']);
    end
     
    if (~isempty(strfind(plotIdentifiers,'phase')))
        figure(2);
        plotHandle = plot(ts./timeScaleFactor, phi, 'black');
        set(plotHandle, 'LineWidth', 1);
        xlabel(['Time [', timeUnitStr, ']']);
        ylabel([freqString, ' Signal phase [deg]']);
    end
    
    if (~isempty(strfind(plotIdentifiers,'bits')))
        figure(3);
        plotHandle = plot(ts./timeScaleFactor, bitshift(bits,20,'uint32')/uint32(2^28), 'x', 'Color', 'black');
        set(plotHandle, 'LineWidth', 1);
        xlabel(['Time [', timeUnitStr, ']']);
        ylabel('DIO bits');
    end
end
