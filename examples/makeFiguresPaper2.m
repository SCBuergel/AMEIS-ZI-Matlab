% todo: combine both loadAndProcess functions into one function
%       instead of passing large number of parameters into those functions
%       create a structure holding those parameters and then just pass this
%       object. 
%       Required parameters in initialize routine of this object are:
%       folder, threshold, frequency for peak detection
% todo: make sure that data loading works if we provide no frequencies to
%       loaded: is the default 1:8 ok if Freq1.ziBin e.g. doesnt exist? 

addpath('..\'); % parent path contains all vital functions
ah=initAmeis('C:\Users\sbuergel\Dropbox\MT-EIS-paper\data\EIS-sampleData\2015-04-02-14-51-12_m\', -2e-4);
ah.maxChunks = 2;
ah.debugOn = 0;
ah.freqs = 2:7;
% ah=initAmeis('C:\Users\sbuergel\Dropbox\AMEIS-bio-paper\data\', 1e-5);
% ah.maxChunks = 2;
% ah.skipInitialSamples = 3000;
% ah.peakDetectionFreqIndex = 3;
% ah.minPeakDistS = 0.5;
% ah.AcSmoothLengthS = 1;
% ah.DcSmoothLengthS = 0.1;

peakData=processFolders(ah);
%% Figure 4
% % load and process cardio data
dataDir = 'C:\Users\sbuergel\Dropbox\MT-EIS-paper\data\EIS-sampleData\2015-04-02-14-51-12_m\';
% peakData = loadAndProcessSingleData(dataDir);

% peakData = loadAndProcessCardioData(dataDir);

%%
figure(1);
x1=subplot(2, 1, 1);
i2 = find(peakData2.chamberIndex == 2 & peakData2.stdInterval < 0.05 & peakData2.meanInterval > 0);
errorbar(peakData2.startTimestampChamberS(i2)./3600, 1./peakData2.meanInterval(i2), peakData2.stdInterval(i2), '.', 'Color', 'red');
% x1=gca();
hold on;
i7 = find(peakData2.chamberIndex == 7 & peakData2.stdInterval < 0.1 & peakData2.meanInterval > 0);
errorbar(peakData2.startTimestampChamberS(i7)./3600, 1./peakData2.meanInterval(i7), peakData2.stdInterval(i7), '.', 'Color', 'blue');
hold off;
ylabel('Beating frequency [Hz]');
xlabel('Time [h]');
xlim([-0.5 19.5]);
% figure(2);
x2=subplot(2, 1, 2);
plot(peakData2.startTimestampChamberS(i2)./3600, peakData2.baseline(1,i2,3)/1000*1e6, 'o', 'Color', 'red');
hold on;
plot(peakData2.startTimestampChamberS(i7)./3600, peakData2.baseline(1,i7,3)/1000*1e6, 'o', 'Color', 'blue');
hold off;
% x2=gca();
ylabel('Current [\mu{}A]');
xlabel('Time [h]');
xlim([-0.5 19.5]);
linkaxes([x1, x2], 'x');


%%
% get indices of chambers


% todo: 
% package in loop processing entire sequence
% check if single peak detection still works

%%
figure(1);
plot(dataRaw.timestamp(allIndices.startIndex), allIndices.chamberIndex);
xlabel('Time [s]');
ylabel('Chamber index');

%%
% for in = 2:15
    in = 2;
    it = 4;
    i2 = find(allIndices.chamberIndex == in & allIndices.iterationOfChamber == it);
    s = allIndices.startIndex(i2(1));
    e = allIndices.endIndex(i2(1));
    figure(2);
    plot(dataRaw.timestamp(s:e), dataRaw.mag(s:e, 5));
    xlabel('Time [s]');
    ylabel('Magnitude [V]');
    title(['chamber ', num2str(in), ' iteration ', num2str(it)]);
    pause(2);
% end

