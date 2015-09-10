addpath('..\'); % parent path contains all vital functions

dataDir = 'C:\Users\sbuergel\Dropbox\AMEIS-bio-paper\data\';
skipInitialSamples = 3000;
threshold = 1e-5;
AcSmoothLengthS = 1;
DcSmoothLengthS = 0.1;
multiPeak = 1;
debugOn = 0;
minPeakDistS = 0.5;
samplesPerChunk = 1e6;
peakDetectionFreqIndex = 5;
freqs = 1:8;

chunkIndex = 0;	% change to skip some iterations in the beginning of the file
dataRaw = 1;    % should not be empty to get into while loop
newIndices = [];
allIndices = [];
peakData2 = [];
while(~isempty(dataRaw))

    % TODO: ideally, loadData should know where the last sample in
    % the previous chunk (incomplete there) started and seek there
    % 1. load data
    % load data
    dataRaw=loadData(dataDir, ...
        samplesPerChunk, samplesPerChunk * chunkIndex, freqs);
    
    ['first timestamp = ', num2str(dataRaw.timestamp(1)/3600), ' h']
    
    % if we did not get any data, then probably we are done processing
    if (isempty(dataRaw))
        continue;
    end

    % 2. find indices
    [allIndices, newIndices] = getIndices(dataRaw, skipInitialSamples, allIndices);
    if (size(newIndices.startIndex,1) == 0)
        continue;
    end
%             % 3 (optional). plot some selected time domain data
%             plotDataTimeDomain(dataRaw, 5, 0, inf, 1, 10, 'mag');

    % 4. extract peak and baseline data and append to existing results of
    % previous chunks
    if (isempty(peakData2))
        peakData2 = getPeaks(dataRaw, allIndices, 'mag', peakDetectionFreqIndex, threshold, ...
            AcSmoothLengthS, DcSmoothLengthS, multiPeak, minPeakDistS, debugOn);
%         peakData.timestamp = peakData.timestamp + folderTimeOffsetsS(folder);
        peakData2.f = dataRaw.f;
    else
        tmpData = getPeaks(dataRaw, newIndices, 'mag', peakDetectionFreqIndex, threshold, ...
            AcSmoothLengthS, DcSmoothLengthS, multiPeak, minPeakDistS, debugOn);
        
        % append peak results to results of previous chunks
        peakData2.chamberIndex = [peakData2.chamberIndex; tmpData.chamberIndex];
        peakData2.iterationOfChamber = [peakData2.iterationOfChamber; tmpData.iterationOfChamber];
%         peakData.startTimestampChamberS = [peakData2.startTimestampChamberS; tmpData.startTimestampChamberS + folderTimeOffsetsS(folder)];
        peakData2.startTimestampChamberS = [peakData2.startTimestampChamberS; tmpData.startTimestampChamberS];
        peakData2.durationChamberS = [peakData2.durationChamberS; tmpData.durationChamberS];
        peakData2.timestampPeak = [peakData2.timestampPeak; tmpData.timestampPeak];
        peakData2.baseline = [peakData2.baseline, tmpData.baseline];  % right dimension for cat?
        peakData2.P2Bl = [peakData2.P2Bl, tmpData.P2Bl];
        if (tmpData.multiPeak ~= 0) % append multi-peak results
            peakData2.peakCount = [peakData2.peakCount; tmpData.peakCount];
            peakData2.meanInterval = [peakData2.meanInterval; tmpData.meanInterval];
            peakData2.stdInterval = [peakData2.stdInterval; tmpData.stdInterval];
        end
    end

    % plot some intermediate multi-peak number
    figure(1);
    plot(peakData2.chamberIndex, peakData2.peakCount, 'o');
%     % plot some intermediate p2bl data
%     figure(1);
%     subplot(1, 3, 1);
%     index=find(peakData.chamberIndex==2);
%     plot(peakData.timestamp(index)./3600, peakData.P2Bl(index, peakDetectionFreqIndex, 1), 'o');
%     xlabel('Time [h]');
%     ylabel('\Delta{}V (chamber 2) [V]');
% 
%     subplot(1, 3, 2);
%     plot(peakData.timestamp(index)./3600, peakData.blRight(index, peakDetectionFreqIndex, 1), 'o');
%     xlabel('Time [h]');
%     ylabel('V_{baseline} (chamber 2) [V]');
% 
%     subplot(1, 3, 3);
%     index=find(peakData.chamberIndex==2);
%     plot(peakData.timestamp(index)./3600, peakData.P2Bl(index, peakDetectionFreqIndex, 1) ./ peakData.blRight(index, peakDetectionFreqIndex, 1), 'o');
%     xlabel('Time [h]');
%     ylabel('\Delta{}V_{norm} (chamber 2) [V]');

    chunkIndex = chunkIndex + 1
    if (chunkIndex > 34)
        break;  % Matlab exception if running for longer, so we quit here...
    end
end

%%
chamber=2;
i=find(peakData2.chamberIndex == 2);
figure(2);
errorbar(peakData2.startTimestampChamberS, peakData2.meanInterval, peakData2.stdInterval,'.');






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

