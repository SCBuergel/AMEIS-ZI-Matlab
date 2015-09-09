function peakData = processFolders(dataFolders, folderTimeOffsetsS)
% PROCESSFOLDERS is extracting peaks of all files in the given folders in a
% chunk-wise fashion and returns the processed summarized peak data

    samplesPerChunk = 1e6;    % increasing loads more samples in one iteration
    threshold = -2e-5;        % peaks below threshold are ignored
    peakDetectionFreqIndex = 1; % frequency index to be used for peak extraction
    freqs = 5;                % frequencies to be imported from ziBin files
    vOutTimesRfb = 20;        % output voltage times feedback resistor in the transimpedance amplifier, used for calculating the impedance. E.g.: Vout = 200mV, Rfb = 100Ohm -> vOutTimesRfb = 20
    skipInitialSamples = 500; % this many samples are skipped after activating a new chamber (might be noisy due to digital tilt signal, bubbles, ...
    
    narginchk(1,2);

    if (~iscell(dataFolders))
        % if we pass just one folder, wrap it into a cell array to make it
        % compatible with multi-folder processing
        dataFolders = {dataFolders};
    end
    
    if (nargin == 1 & size(dataFolders,2) < 2)
        % no folderTimeOffsetS provided and less than two folders
        folderTimeOffsetsS = 0;
    end
    
    if (nargin == 1 & size(dataFolders,2) > 1)
        % no folderTimeOffsetS provided but more than one folder
        error('When processing more than one folder, folderTimeOffsetsS has to be provided. This vector contains the time offsets of the beginning of the file in seconds.');
    end

    
    peakData = [];
    allIndices = [];
    folder = 1;
    for folder  = 1:size(dataFolders, 2)
        chunkIndex = 0;             % change to skip some iterations in the beginning of the file
        dataRaw = 1;  % should not be empty to get into while loop
        newIndices = [];
        while(~isempty(dataRaw))
            
            % TODO: ideally, loadData should know where the last sample in
            % the previous chunk (incomplete there) started and seek there
            % 1. load data
            dataRaw=loadData(dataFolders{folder}, ...
                samplesPerChunk, samplesPerChunk * chunkIndex, freqs);

            % if we did not get any data, then probably we are done processing
            if (isempty(dataRaw))
                continue;
            end

            % 2. find indices
            [allIndices, newIndices] = getIndices(dataRaw, skipInitialSamples, allIndices);

%             % 3 (optional). plot some selected time domain data
%             plotDataTimeDomain(dataRaw, 5, 0, inf, 1, 10, 'mag');

            % 4. extract peak and baseline data
            if (isempty(peakData))
                peakData = getPeaks(dataRaw, newIndices, 'mag', peakDetectionFreqIndex, threshold, vOutTimesRfb);
                peakData.timestamp = peakData.timestamp + folderTimeOffsetsS(folder);
                peakData.f = dataRaw.f;
            else
                tmpData = getPeaks(dataRaw, newIndices, 'mag', peakDetectionFreqIndex, threshold, vOutTimesRfb);
                peakData.blLeft = [peakData.blLeft; tmpData.blLeft];
                peakData.blRight = [peakData.blRight; tmpData.blRight];
                peakData.P2Bl = [peakData.P2Bl; tmpData.P2Bl];
                peakData.chamberIndex = [peakData.chamberIndex; tmpData.chamberIndex];
                peakData.iterationOfChamber = [peakData.iterationOfChamber; tmpData.iterationOfChamber];
                peakData.timestamp = [peakData.timestamp; tmpData.timestamp + folderTimeOffsetsS(folder)];
            end
% 
            % plot some intermediate p2bl data
            figure(1);
            subplot(1, 3, 1);
            index=find(peakData.chamberIndex==2);
            plot(peakData.timestamp(index)./3600, peakData.P2Bl(index, peakDetectionFreqIndex, 1), 'o');
            xlabel('Time [h]');
            ylabel('\Delta{}V (chamber 2) [V]');
            
            subplot(1, 3, 2);
            plot(peakData.timestamp(index)./3600, peakData.blRight(index, peakDetectionFreqIndex, 1), 'o');
            xlabel('Time [h]');
            ylabel('V_{baseline} (chamber 2) [V]');
            
            subplot(1, 3, 3);
            index=find(peakData.chamberIndex==2);
            plot(peakData.timestamp(index)./3600, peakData.P2Bl(index, peakDetectionFreqIndex, 1) ./ peakData.blRight(index, peakDetectionFreqIndex, 1), 'o');
            xlabel('Time [h]');
            ylabel('\Delta{}V_{norm} (chamber 2) [V]');
            
            chunkIndex = chunkIndex + 1
        end
    end
end
