function [] = plotBeatingVsTime( peaksInChamber, timesteps)
    X=cell(timesteps,1);
    [X{:}]=peaksInChamber.chamberStartTime;
    tStart=[X{:}];
    [X{:}]=peaksInChamber.meanInterval;
    intMean=[X{:}];
    [X{:}]=peaksInChamber.stdInterval;
    intStd=[X{:}];
    [X{:}]=peaksInChamber.peakCount;
    pkCount=[X{:}];

    figure(2);
    ax(1)=subplot(2, 1, 1);
    errorbar(1:timesteps, intMean, intStd, '.');
    hold on;
    plot(1:timesteps, intMean, 'x-');
    hold off;
    ax(2)=subplot(2, 1, 2);
    plot(1:timesteps, pkCount);
    linkaxes(ax, 'x');
    
    % remove the data points where we have less than 4 peaks (std/mean not
    % defined)
    tStart = tStart(pkCount >= 4);
    intMean = intMean(pkCount >= 4);
    intStd = intStd(pkCount >= 4);
    
    figure(1);
    errorbar(tStart/3600, intMean, intStd);
    title('Chamber 1');
    xlabel('Time [h]');
    ylabel('Beating interval [s]');
end
