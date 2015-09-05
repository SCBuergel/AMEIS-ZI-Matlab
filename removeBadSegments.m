function [ smoothedChamberDataNew ] = removeBadSegments( smoothedChamberData, freqIndex, thresholdBlStdev)
%REMOVEBADSEMENTS removes bad chambers from smoothedChamberData
%   removing items in smoothedChamberData where a big standard deviation
%   is observed, it is being removed (e.g. due to wrong detection of
%   switching, bubbles, ...)

    disp('Removing bad segments...');
    BlMagStds=vertcat(smoothedChamberData.BlMagStd);
    goodIndices = find(BlMagStds(:,freqIndex) < thresholdBlStdev);
    smoothedChamberDataNew = smoothedChamberData(goodIndices);
end

