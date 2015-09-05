function [ output_args ] = plotBl( smoothedChamberData, freqIndex, chamberIndices)
%PLOTBL plotting baseline
%   plotting baseline (magnitude and phase) at given frequency and chamber
    output_args=[];
    cols = hsv(size(chamberIndices, 2) + 1);
    c = 0;
    for (chamberIndex = chamberIndices)
        c = c + 1;
        cData = smoothedChamberData(find(vertcat(smoothedChamberData.chamberIndex)==chamberIndex));
        ts = vertcat(cData.start);
        meanMags = vertcat(cData.BlMagMean);
        meanPhases = vertcat(cData.BlPhaseMean);
        stdMags = vertcat(cData.BlMagStd);
        stdPhases = vertcat(cData.BlPhaseStd);
        h(1)=subplot(2, 1, 1);
        errorbar(ts/3600, meanMags(:,freqIndex), stdMags(:,freqIndex), 'Color', cols(c, :));
        hold on;
        h(2)=subplot(2, 1, 2);
        errorbar(ts/3600, meanPhases(:,freqIndex), stdPhases(:,freqIndex), 'Color', cols(c, :));
        hold on;
    end
    h(1)=subplot(2, 1, 1);
    hold off;
    h(2)=subplot(2, 1, 2);
    hold off;
    linkaxes(h, 'x');
end

