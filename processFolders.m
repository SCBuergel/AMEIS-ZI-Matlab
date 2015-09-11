function peakData = processFolders(ah)
% PEAKDATA processes ameis data from folder(s)
%   function parameter is a handler object initialized with initAmeis()
%   returns results of data processing
%
%   sebastian.buergel@bsse.etz.ch, 2015

narginchk(1,1);

if (~iscell(ah.dataFolders))
    % if we get just one folder, wrap it into a cell array to make it
    % compatible with multi-folder processing
    dataFolders = {ah.dataFolders};
else
    dataFolders = ah.dataFolders;
end

allIndices = [];
peakData = [];
% process folder by folder
for folder  = 1:size(dataFolders, 2)
    chunkIndex = ah.startChunkIndex;	% change to skip some iterations in the beginning of the file
    dataRaw = 1;    % should not be empty to get into while loop
    newIndices = [];
    % process chunk by chunk
    while(~isempty(dataRaw))

        % TODO: ideally, loadData should know where the last sample in
        % the previous chunk (incomplete there) started and seek there
        % load data
        dataRaw=loadData(dataFolders{folder}, ...
            ah.samplesPerChunk, ah.samplesPerChunk * chunkIndex, ah.freqs);

        % if we did not get any data, then probably we are done processing
        if (isempty(dataRaw))
            continue;
        end

        ['first timestamp = ', num2str(dataRaw.timestamp(1)/3600), ' h']

        % find indices
        [allIndices, newIndices] = getIndices(dataRaw, ah.skipInitialSamples, allIndices);
        if (size(newIndices.startIndex,1) == 0)
            continue;
        end

        % extract peak and baseline data and append to existing results of
        % previous chunks
        if (isempty(peakData))
            peakData = getPeaks(dataRaw, allIndices, 'mag', ah.peakDetectionFreqIndex, ah.threshold, ...
                ah.AcSmoothLengthS, ah.DcSmoothLengthS, ah.multiPeak, ah.minPeakDistS, ah.debugOn);
            peakData.f = dataRaw.f;
            peakData.startTimestampChamberS = peakData.startTimestampChamberS + ah.folderTimeOffsetsS(folder);
            peakData.timestampPeak = peakData.timestampPeak + ah.folderTimeOffsetsS(folder);
        else
            tmpData = getPeaks(dataRaw, newIndices, 'mag', ah.peakDetectionFreqIndex, ah.threshold, ...
                ah.AcSmoothLengthS, ah.DcSmoothLengthS, ah.multiPeak, ah.minPeakDistS, ah.debugOn);

            % append peak results to results of previous chunks
            peakData.chamberIndex = [peakData.chamberIndex; tmpData.chamberIndex];
            peakData.iterationOfChamber = [peakData.iterationOfChamber; tmpData.iterationOfChamber];
            peakData.startTimestampChamberS = [peakData.startTimestampChamberS; tmpData.startTimestampChamberS + ah.folderTimeOffsetsS(folder)];
            peakData.durationChamberS = [peakData.durationChamberS; tmpData.durationChamberS];
            peakData.timestampPeak = [peakData.timestampPeak; tmpData.timestampPeak + ah.folderTimeOffsetsS(folder)];
            peakData.baseline = [peakData.baseline, tmpData.baseline];  % right dimension for cat?
            peakData.P2Bl = [peakData.P2Bl, tmpData.P2Bl];
            if (tmpData.multiPeak ~= 0) % append multi-peak results
                peakData.peakCount = [peakData.peakCount; tmpData.peakCount];
                peakData.meanInterval = [peakData.meanInterval; tmpData.meanInterval];
                peakData.stdInterval = [peakData.stdInterval; tmpData.stdInterval];
            end
        end

        figure(1);
        if (ah.multiPeak ~= 0)
            % plot some intermediate multi-peak number
            plot(peakData.chamberIndex, peakData.peakCount, 'o');
        else
            % plot some intermediate p2bl data
            chamber = 2;
            subplot(1, 3, 1);
            index=find(peakData.chamberIndex==chamber);
            plot(peakData.startTimestampChamberS(index)./3600, peakData.P2Bl(1, index, ah.peakDetectionFreqIndex), 'o');
            xlabel('Time [h]');
            ylabel(['\Delta{}V (chamber ', num2str(chamber), ') [V]']);

            subplot(1, 3, 2);
            plot(peakData.startTimestampChamberS(index)./3600, peakData.baseline(1, index, ah.peakDetectionFreqIndex), 'o');
            xlabel('Time [h]');
            ylabel(['V_{baseline} (chamber ', num2str(chamber), ') [V]']);

            subplot(1, 3, 3);
            plot(peakData.startTimestampChamberS(index)./3600, peakData.P2Bl(1, index, ah.peakDetectionFreqIndex) ./ peakData.baseline(1, index, ah.peakDetectionFreqIndex), 'o');
            xlabel('Time [h]');
            ylabel(['\Delta{}V_{norm} (chamber ', num2str(chamber), ') [V]']);
        end
        
        chunkIndex = chunkIndex + 1
        if (chunkIndex > ah.maxChunks)
            break;  % Matlab exception if running for longer, so we quit here...
        end
    end
end
end
