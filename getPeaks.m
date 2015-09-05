function [peakData] = getPeaks(dataIn, indices, magPhaseString, freqIndex, threshold, vOutTimesRfb)

% prepare some helper variables
    samplingIntervalS = dataIn.timestamp(2) - dataIn.timestamp(1);
%     minPeakIntervalSamples = ceil(minPeakIntervalS / samplingIntervalS) + 1;
    
    numChambers = size(indices.chamberIndex,1);
    numFreqs = size(dataIn.mag,2);
    
    % create structure with peak data which we return
    % three columns are for storing (1) signal magnitude, (2) phase, (3)
    % real signal component, (4) imaginary signal component in one matrix
    peakData.P2Bl = zeros(numChambers, numFreqs, 4);
    peakData.blLeft = zeros(numChambers, numFreqs, 4);
    peakData.blRight = zeros(numChambers, numFreqs, 4);
    %peakData.peakIndex = zeros(numChambers, 1);
    peakData.chamberIndex = zeros(numChambers, 1);
    peakData.iterationOfChamber = zeros(numChambers, 1);
    peakData.timestamp = zeros(numChambers, 1);

    % process one chamber and one iteration at a time
    for i=1:numChambers

        % it should be possible to index peakData in the same way is
        % indices, therefore we copy the chamber/iteration identifiers
        peakData.chamberIndex(i) = indices.chamberIndex(i);
        peakData.iterationOfChamber(i) = indices.iterationOfChamber(i);

        % skip chamber index 0 (active during switching while we do not
        % have any signal)
        if (indices.chamberIndex(i) == 0)
            continue;
        end
        
        % extract baseline information (beginning and end of chamber
        % recording)
        if (i > size(peakData.blLeft, 1))
            warning('over');
        end
        if (i > size(indices.startIndex,1))
            warning('over');
        end
        if (indices.startIndex(i) > size(dataIn.mag, 1))
            warning('over');
        end
        peakData.blLeft(i,:,1) = dataIn.mag(indices.startIndex(i),:);
        peakData.blLeft(i,:,2) = dataIn.phase(indices.startIndex(i),:);
        peakData.blLeft(i,:,3) = dataIn.x(indices.startIndex(i),:);
        peakData.blLeft(i,:,4) = dataIn.y(indices.startIndex(i),:);
        peakData.blRight(i,:,1) = dataIn.mag(indices.endIndex(i),:);
        peakData.blRight(i,:,2) = dataIn.phase(indices.endIndex(i),:);
        peakData.blRight(i,:,3) = dataIn.x(indices.endIndex(i),:);
        peakData.blRight(i,:,4) = dataIn.y(indices.endIndex(i),:);

        % depending on magPhaseString we work on magnitude or phase data
        if (strcmp(magPhaseString, 'phase'))
            data = dataIn.phase(indices.startIndex(i):indices.endIndex(i),freqIndex) - ...
                (peakData.blLeft(i,freqIndex,2) + peakData.blRight(i,freqIndex,2)) / 2;
        elseif (strcmp(magPhaseString, 'imp'))
            data = vOutTimesRfb./dataIn.mag(indices.startIndex(i):indices.endIndex(i),freqIndex) - ...
                (peakData.blLeft(i,freqIndex,3) + peakData.blRight(i,freqIndex,3)) / 2;
        else
            data = dataIn.mag(indices.startIndex(i):indices.endIndex(i),freqIndex) - ...
                (peakData.blLeft(i,freqIndex,1) + peakData.blRight(i,freqIndex,1)) / 2;
        end

        % if we have negative peaks we expect the majority of all data points
        % to be above the threshold and vice versa
        findMaxima = false;
        if (sum(data > threshold) > sum(data < threshold))
            dataThresh = data < threshold;
            findMaxima = false;
        else
            dataThresh = data > threshold;
            findMaxima = true;
        end

        % find extremum, only treat one peak per chamber and iteration
        if (findMaxima)
            [extr, extrIndex] = max(data);
            % ignore sub-threshold extrema
            if (extr < threshold)
                continue;
            end
        else
            % ignore sub-threshold extrema
            [extr, extrIndex] = min(data);
            if (extr > threshold)
                continue;
            end
        end
        extrIndex = extrIndex + indices.startIndex(i);

        if (size(peakData.P2Bl, 1) < i)
            warning('mismatching size');
        end
        if (size(peakData.blLeft, 1) < i)
            warning('mismatching size');
        end
        if (size(peakData.blRight, 1) < i)
            warning('mismatching size');
        end
        if (size(dataIn.mag, 1) < extrIndex)
            warning('mismatching size');
        end
        A=peakData.blLeft(i,:,1);
        if(size(dataIn.mag,1) < extrIndex)
            warning('overflow');
        end
        B=dataIn.mag(extrIndex,:);
        if(~(isequal(size(A), size(B)) || (isvector(A) && isvector(B) && numel(A) == numel(B))))
            warning('mismatching size');
        end

        % calculate peak-to-baseline for all frequencies, using both left
        % and right baseline
        peakData.P2Bl(i,:,1) = ...
            dataIn.mag(extrIndex,:) - ...
            (peakData.blLeft(i,:,1) + peakData.blRight(i,:,1)) ./ 2;
        peakData.P2Bl(i,:,2) = ...
            dataIn.phase(extrIndex,:) - ...
            (peakData.blLeft(i,:,2) + peakData.blRight(i,:,2)) ./ 2;
        peakData.P2Bl(i,:,3) = ...
            dataIn.x(extrIndex,:) - ...
            (peakData.blLeft(i,:,3) + peakData.blRight(i,:,3)) ./ 2;
        peakData.P2Bl(i,:,4) = ...
            dataIn.y(extrIndex,:) - ...
            (peakData.blLeft(i,:,4) + peakData.blRight(i,:,4)) ./ 2;

        % calculate peak-to-baseline for all frequencies using only right
        % baseline (left might deviate due to early peak)
        peakData.P2Bl(i,:,1) = ...
            dataIn.mag(extrIndex,:) - peakData.blRight(i,:,1);
        peakData.P2Bl(i,:,2) = ...
            dataIn.phase(extrIndex,:) - peakData.blRight(i,:,2);
        peakData.P2Bl(i,:,3) = ...
            dataIn.x(extrIndex,:) - peakData.blRight(i,:,3);
        peakData.P2Bl(i,:,4) = ...
            dataIn.y(extrIndex,:) - peakData.blRight(i,:,4);
        peakData.timestamp(i) = dataIn.timestamp(extrIndex);
        
%         % summarize peaks which are within certain window and only briefly pass
%         % under the threshold
%         dataThreshConv = conv(double(dataThresh), ones(minPeakIntervalSamples,1)) > 0;
%         dataThreshConv = dataThreshConv(ceil(minPeakIntervalSamples/2):end-floor(minPeakIntervalSamples/2)); % cut the data left and right to match the length of the original data set
%         startPeaks = find(diff(dataThreshConv) == 1);
%         endPeaks = find(diff(dataThreshConv) == -1);
%         numPeaks = min(size(startPeaks,2), size(endPeaks,2));
% 
%         % check if first peak is partially cut off, if so: ignore it:
%         if (numPeaks > 0)
%             if (startPeaks(1) > endPeaks(1))
%                 endPeaks = endPeaks(2:end);
%                 numPeaks = min(size(startPeaks,2), size(endPeaks,2));
%             end
%         end
    end

end
