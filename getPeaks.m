function [peakData] = getPeaks(dataIn, indices, magPhaseString, ...
    freqIndex, threshold, ...
    AcSmoothLengthS, DcSmoothLengthS, multiPeak, minPeakDistS, debugOn)
%GETPEAKS extracts peaks from raw data
% 
%   P = GETPEAKS(D, I, M, F, T) extracts peaks from raw data chunk D.
%   The index (obtained by getIndices()) is passed in I.
%   The peaks are detected depending on the value of M
%       M = 'phase': peak detection on phase component of signal
%       M = 'x': peak detection on real component of signal
%       M = 'y': peak detection on imaginary component of signal
%       M = anything else (e.g. 'mag'): peak detection on magnitude
%       component of the signal (raw magnitude, not current)
%   Peak detection is performed on the frequency index F.
%   Peaks above or below the threshold T are discarded.
% 
%   P = GETPEAKS(D, I, M, F, T, L) Removes low frequency components by
%   smoothing with this length (high value typically several seconds) and
%   subtracting from raw data.
%       L = 0: no AC filtering
% 
%   P = GETPEAKS(D, I, M, F, T, L, H) Removes high frequency components by
%   smoothing with this length (low value, typically sub-seconds).
%       H = 0: no DC filtering
% 
%   P = GETPEAKS(D, I, M, F, T, L, H, N) Detects multiple peaks (might
%   also be zero peaks) per chamber. Then returns cellarray instead of 
%   matrix since chambers might have different number of peaks.
%       N = 0: single peak detection
%       N ~= 0: multiple peak detection
% 
%   P = GETPEAKS(D, I, M, F, T, L, H, N, S) When processing multiple peaks, 
%   invidual peaks have to be separated by S seconds, otherwise they are 
%   not separated. Only relevant for detection of multiple peaks per 
%   chamber.
% 
%   P = GETPEAKS(D, I, M, F, T, L, H, N, S, P) Debug mode for P ~= 0.
%   Performs peak detection chamber-by-chamber and displays some debug
%   output plots for each chamber
%       P = 0: normal mode (no debug plots)
%       P ~= 0: debug mode (with debug plots)
% 
%   sebastian.buergel@bsse.etz.ch, 2015

    narginchk(5,10);

    if nargin == 5 % assume we do not want to smooth and detect only one peak per chamber, no minimal peak distance, no debug mode
        AcSmoothLengthS = 0;
        DcSmoothLengthS = 0;
        multiPeak = 0;
        minPeakDistS = 0;
        debugOn = 0;
    elseif nargin == 6 % assume we do not want to do DC smoothingdetect only one peak per chamber, no minimal peak distance, no debug mode
        DcSmoothLengthS = 0;
        multiPeak = 0;
        minPeakDistS = 0;
        debugOn = 0;
    elseif nargin == 7 % assume we want to detect only one peak per chamber, no minimal peak distance, no debug mode
        multiPeak = 0;
        minPeakDistS = 0;
        debugOn = 0;
    elseif nargin == 8 % assume no minimal peak distance, no debug mode
        minPeakDistS = 0;
        debugOn = 0;
    elseif nargin == 9 % assume no debug mode
        debugOn = 0;
    end

    % prepare some helper variables
    samplingIntervalS = dataIn.timestamp(2) - dataIn.timestamp(1);
    AcSmoothLengthSamples = ceil(AcSmoothLengthS / samplingIntervalS);
    DcSmoothLengthSamples = ceil(DcSmoothLengthS / samplingIntervalS);
    minPeakDistSamples = ceil(minPeakDistS / samplingIntervalS);
    numChambers = size(indices.chamberIndex,1);
    numFreqs = size(dataIn.mag,2);
    
    % create structure with peak data which we return
    peakData.chamberIndex = zeros(numChambers, 1);
    peakData.iterationOfChamber = zeros(numChambers, 1);
    peakData.startTimestampChamberS = zeros(numChambers, 1);
    peakData.durationChamberS = zeros(numChambers, 1);
    peakData.baseline = zeros(4, numChambers, numFreqs);
    if (multiPeak == 0)
        peakData.multiPeak = 0;
        % four columns are for storing (1) signal magnitude, (2) phase, (3)
        % real signal component, (4) imaginary signal component in one matrix
        peakData.P2Bl = zeros(4, numChambers, numFreqs);
        peakData.timestampPeak = zeros(numChambers, 1);
    else
        peakData.multiPeak = 1;
        peakData.P2Bl = cell(4, numChambers, numFreqs);
        %peakData.peakPos = cell(numChambers, 1);
        peakData.timestampPeak = cell(numChambers, 1);
        peakData.peakCount = zeros(numChambers,1);
        peakData.meanInterval = zeros(numChambers,1);
        peakData.stdInterval = zeros(numChambers,1);
    end

    % process one chamber and one iteration at a time
    for i=1:numChambers
        % setup indices:
        % it should be possible to index peakData in the same way as
        % indices, therefore we copy the chamber/iteration identifiers
        peakData.chamberIndex(i) = indices.chamberIndex(i);
        peakData.iterationOfChamber(i) = indices.iterationOfChamber(i);

        % skip chamber index 0 (active during switching while we do not
        % have any signal)
        if (indices.chamberIndex(i) == 0)
            continue;
        end

        % helper variables for readability
        iStart = indices.startIndex(i);
        iEnd = indices.endIndex(i);

        % extract baseline levels
        % TODO: we might be unlucky in having a peak during activation of
        % the chamber, this would lead to a shifted baseline. One way
        % around this would be an iterative approach in extracting the
        % baseline, making peak detection and checking if we have a peak
        % near the start/endpoint. In that case pick another baseline point
        % (e.g. between two peaks) and repeat.
        peakData.baseline(1,i,:) = (dataIn.mag(iStart,:) + dataIn.mag(iEnd,:)) / 2;
        peakData.baseline(2,i,:) = (dataIn.phase(iStart,:) + dataIn.phase(iEnd,:)) / 2;
        peakData.baseline(3,i,:) = (dataIn.x(iStart,:) + dataIn.x(iEnd,:)) / 2;
        peakData.baseline(4,i,:) = (dataIn.y(iStart,:) + dataIn.y(iEnd,:)) / 2;
        
        % translate mag, phase, x, y into three dimensional matrix
        % TODO: should this already happen in dataRead() ?
        dataRaw = [];
        for f=1:numFreqs
            dataRaw(1,:,f) = dataIn.mag(iStart:iEnd,f) - peakData.baseline(1,i,f);
            dataRaw(2,:,f) = dataIn.phase(iStart:iEnd,f) - peakData.baseline(2,i,f);
            dataRaw(3,:,f) = dataIn.x(iStart:iEnd,f) - peakData.baseline(3,i,f);
            dataRaw(4,:,f) = dataIn.y(iStart:iEnd,f) - peakData.baseline(4,i,f);
        end

        % depending on magPhaseString we work on magnitude, phase, x or y
        % data and remove the baseline values        
        if (strcmp(magPhaseString, 'phase'))
            pDetectMode = 2;
        elseif (strcmp(magPhaseString, 'x'))
            pDetectMode = 3;
        elseif (strcmp(magPhaseString, 'y'))
            pDetectMode = 4;
        else
            pDetectMode = 1;
        end
        
        % for debugging puposes show raw data
        if (debugOn ~= 0)
            figure(2);
            ts  = dataIn.timestamp(iStart:iEnd);
            plot (ts, dataRaw(pDetectMode, :, freqIndex), 'Color', 'green');
            le = {};
            le{1} = 'raw data';
            hold on;
        end
        
        % do AC (highpass) filtering of data if requested
        if (AcSmoothLengthSamples > 2)
            dataAc = zeros(size(dataRaw));
            for t=1:4
                for f=1:numFreqs
                    dataAc(t, :, f) = dataRaw(t, :, f) - smooth(dataRaw(t, :, f), AcSmoothLengthSamples)';
                end
            end
        else
            dataAc = dataRaw;
        end
            
        % do DC (lowpass) filterting of data if requested
        if (DcSmoothLengthSamples > 2)
            dataDc = zeros(size(dataAc));
            for t=1:4
                for f=1:numFreqs
                    dataDc(t, :, f) = smooth(dataAc(t, :, f), DcSmoothLengthSamples)';
                end
            end
        else
            dataDc = dataAc;
        end
        
        % prepare data for peak detection
        dataForPeakDetection = dataDc(pDetectMode, :, freqIndex);
        
        % find out if we are looking for maxima or minima
        % if we have negative peaks we expect the majority of all data points
        % to be above the threshold and vice versa
        if (sum(dataForPeakDetection > threshold) > sum(dataForPeakDetection < threshold))
            findMaxima = false;
        else
            findMaxima = true;
        end
            
        % store time information of chamber
        peakData.startTimestampChamberS(i) = dataIn.timestamp(iStart);
        peakData.durationChamberS(i) = dataIn.timestamp(iEnd) - dataIn.timestamp(iStart);

        % for debugging puposes show filtered data and stop execution after
        % each chamber (execution is advanced after pressing any key in
        % console
        if (debugOn ~= 0)
            ts = dataIn.timestamp(iStart:iEnd);
            plot (ts, dataForPeakDetection, 'Color', 'blue');
            le{2} = 'filtered data';
            plot([ts(1), ts(end)], [threshold, threshold], ':', 'Color', 'red', 'LineWidth', 5);
            le{3} = 'peak detection threshold';
            legend(le);
            xlabel('Time [s]');
            title(['chamber ', num2str(indices.chamberIndex(i)), ' iteration ', num2str(indices.iterationOfChamber(i))]);
        end
        
        % only treat one peak per chamber and iteration
        if (multiPeak == 0)
            skipPeak = 0;
            % find minimum / maximum
            if (findMaxima)
                [extr, extrIndex] = max(dataForPeakDetection);
                if (extr < threshold)
                    skipPeak = 1;   % ignore sub-threshold extrema
                end
            else
                [extr, extrIndex] = min(dataForPeakDetection);
                if (extr > threshold)
                    skipPeak = 1;   % ignore sub-threshold extrema
                end
            end
            if (skipPeak == 0)
                % calculate peak-to-baseline for all frequencies and timestamp
                % TODO: should we maybe subtract dc fit value if available
                % instead of baseline?
                peakData.P2Bl(:,i,:) = dataDc(:,extrIndex,:);
                peakData.timestampPeak(i) = dataIn.timestamp(extrIndex + iStart);
                % if debug is on, overlay peak positions on debug plot
                if (debugOn ~= 0)
                    plot(peakData.timestampPeak(i), dataDc(pDetectMode, extrIndex, freqIndex), 'x', 'MarkerSize', 20, 'LineWidth', 4);
                end
            end

        else % multiple peaks per chamber

            % threshold data
            if (~findMaxima)
                dataThresh = dataForPeakDetection < threshold;
            else
                dataThresh = dataForPeakDetection > threshold;
            end
            
            % summarize peaks which are within certain window and only briefly pass
            % under the threshold
            dataThreshConv = conv(double(dataThresh), ones(minPeakDistSamples,1)) > 0;
            dataThreshConv = dataThreshConv(ceil(minPeakDistSamples/2):end-floor(minPeakDistSamples/2)); % cut the data left and right to match the length of the original data set
            startPeaks = find(diff(dataThreshConv) == 1);
            endPeaks = find(diff(dataThreshConv) == -1);
            numPeaks = min(size(startPeaks,2), size(endPeaks,2));
    
            % check if first peak is partially cut off. if so, ignore it.
            if (numPeaks > 0)
                if (startPeaks(1) > endPeaks(1))
                    endPeaks = endPeaks(2:end);
                    numPeaks = min(size(startPeaks,2), size(endPeaks,2));
                end
                
                % make sure startPeaks and endPeaks are of same length
                startPeaks = startPeaks(1:numPeaks);
                endPeaks = endPeaks(1:numPeaks);
            end
            
            % find indices and P2Bl values of peaks
            for p = 1:numPeaks
                if (findMaxima)
                    [tmp, peakPos] = max(dataForPeakDetection(startPeaks(p):endPeaks(p)));
                else
                    [tmp, peakPos] = min(dataForPeakDetection(startPeaks(p):endPeaks(p)));
                end
                peakPos = peakPos + startPeaks(p);
                peakData.timestampPeak{i}(p) = dataIn.timestamp(peakPos) + dataIn.timestamp(iStart) - dataIn.timestamp(1);
                
                % find peak-to-baseline values for each frequency, each
                % type (mag, phase, x, y) at each peak
                for f = 1:numFreqs
                    for t = 1:4
                        if (isempty(peakData.P2Bl{t, i, f}))
                            peakData.P2Bl{t, i, f} = zeros(numPeaks,1);
                        end
                        peakData.P2Bl{t, i, f}(p) = dataDc(t, peakPos, f);
                    end
                end
                
                % if debug is on, overlay peak positions on debug plot
                if (debugOn ~= 0)
                    plot(peakData.timestampPeak{i}(p), peakData.P2Bl{pDetectMode, i, freqIndex}(p), 'x', 'MarkerSize', 20, 'LineWidth', 4);
                end
            end
    
            % this section is useful for, e.g. cardiac recordings with periodic beats
            if (numPeaks > 3)
                peakData.meanInterval(i) = mean(diff(peakData.timestampPeak{i}));
                peakData.stdInterval(i) = std(diff(peakData.timestampPeak{i}));
            else
                peakData.meanInterval(i) = 0;
                peakData.stdInterval(i) = 0;
            end
            peakData.peakCount(i) = numPeaks;
        end
        
        % pause for display of debug plots if we are in debug mode
        if (debugOn ~= 0)
            hold off;
            display(['Debug mode is on.' sprintf('\n') 'Press any key to continue to next chamber.' sprintf('\n') 'Abort with Ctrl+c' sprintf('\n') 'Disable debug mode by setting the corresponding mode in the handler:' sprintf('\n') 'ah=initAmeis(folder,threshold);' sprintf('\n') 'ah.debugOn=0;' sprintf('\n')]);
            pause;
        end
    end

end
