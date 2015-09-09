addpath('..\'); % parent path contains all vital functions

%%
% perform data extraction, warning: depending on file size this takes long!, run the
% extraction only when necessary, then store the output peakData in file or
% just in memory
dataDir = 'C:\Users\sbuergel\Dropbox\AMEIS-bio-paper\data\';
% peakData = processFolders(dataDirs, folderTimeOffsetsS);

% load data
samplesPerChunk = 2e5;
chunkIndex = 10;
freqs = 1:6;
dataRaw=loadData(dataDir, ...
    samplesPerChunk, samplesPerChunk * chunkIndex, freqs);
dataRaw.timestamp(1)/3600
%%
% get indices of chambers
skipInitialSamples = 3000;
allIndices = getIndices(dataRaw, skipInitialSamples);
threshold = 1e-5;
AcSmoothLengthS = 2;
DcSmoothLengthS = 0.05;
multiPeak = 1;
debugOn = 1;
minPeakDistS = 0.5;
peakData = getPeaks(dataRaw, allIndices, 'mag', 5, threshold, ...
    AcSmoothLengthS, DcSmoothLengthS, multiPeak, minPeakDistS, debugOn);

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
    i = find(allIndices.chamberIndex == in & allIndices.iterationOfChamber == it);
    s = allIndices.startIndex(i(1));
    e = allIndices.endIndex(i(1));
    figure(2);
    plot(dataRaw.timestamp(s:e), dataRaw.mag(s:e, 5));
    xlabel('Time [s]');
    ylabel('Magnitude [V]');
    title(['chamber ', num2str(in), ' iteration ', num2str(it)]);
    pause(2);
% end

