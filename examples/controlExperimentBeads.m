% ah=initAmeis('C:\Users\sbuergel\Desktop\mt-eis-2016-02-19\', -1e-4);
% ah.debugOn = 0;
% ah.samplesPerChunk = 1e6;
% peakData = processFolders(ah);

% small: 1, 5, 7, 9, 11, 13
% big: 4, 6, 12, 14
% 

figure(2);
freqIndex = 3;
chambers = [4, 6, 12, 14];
count = 1;
cols = winter(size(chambers, 2));
for chamber = chambers
    i = find(peakData.chamberIndex == chamber);
    x = peakData.timestampPeak(i);
    y = smooth(peakData.P2Bl(1, i, freqIndex), 10); % P2Bl
%     y = smooth(peakData.baseline(1, i, freqIndex), 10); % Bl
%     y = smooth(peakData.P2Bl(1, i, freqIndex) ./ peakData.baseline(1, i, freqIndex), 10); % Bl
    
    plot(x, y, '.', 'Color', cols(count,:));
    hold on;
    count = count + 1;
end
hold off;