function [peakData] = getPeaks(dataIn, indices, magPhaseString, ...
    freqIndex, threshold, vOutTimesRfb, ...
    AcSmoothLengthS, DcSmoothLengthS, multiPeak, debugOn)
%GETPEAKS extracts peaks from raw data
% 
%   P = GETPEAKS(D, I, M, F, T) extracts peaks from raw data chunk D on
%   frequency indices I (usually all frequency indices are provided here).
%   The peaks are detected depending on the value of M
%       M = 'phase': peak detection on phase component of signal
%       M = 'imp': converted to impedance and peak detection on impedance
%       signal
%       M = anything else (e.g. 'mag'): peak detection on magnitude
%       component of the signal (raw magnitude, not current)
%   Peak detection is performed on the frequency index F.
%   Peaks above or below the threshold T are discarded.
%
%   P = GETPEAKS(D, I, M, F, T, V) The values of the applied voltage and
%   feedback resistor are used for calculating the impedance if peak
%   detection is to happen on impedance data, not raw magnitude/phase
% 
%   P = GETPEAKS(D, I, M, F, T, V, L) Removes low frequency components by
%   smoothing with this length (high value typically several seconds) and
%   subtracting from raw data.
%       L = 0: no AC filtering
% 
%   P = GETPEAKS(D, I, M, F, T, V, L, H) Removes high frequency components by
%   smoothing with this length (low value, typically sub-seconds).
%       H = 0: no DC filtering
% 
%   P = GETPEAKS(D, I, M, F, T, V, L, H, N) Detects multiple peaks (might
%   also be zero peaks) per chamber. Then returns cellarray instead of 
%   matrix since chambers might have different number of peaks.
%       N = 0: single peak detection
%       N ~= 0: multiple peak detection
% 
%   P = GETPEAKS(D, I, M, F, T, V, L, H, N, P) Debug mode for P ~= 0.
%   Performs peak detection chamber-by-chamber and displays some debug
%   output plots for each chamber
%       P = 0: normal mode (no debug plots)
%       P ~= 0: debug mode (with debug plots)
% 
%   sebastian.buergel@bsse.etz.ch, 2015

    narginchk(5,10);

    if nargin == 5 % assume default values for vOutTimesRfb, we do not want to smooth and detect only one peak per chamber, no debug mode
        vOutTimesRfb = 100;
        AcSmoothLengthS = 0;
        DcSmoothLengthS = 0;
        multiPeak = 0;
        debugOn = 0;
    elseif nargin == 6 % assume we do not want to smooth and detect only one peak per chamber, no debug mode
        AcSmoothLengthS = 0;
        DcSmoothLengthS = 0;
        multiPeak = 0;
        debugOn = 0;
    elseif nargin == 7 % assume we do not want to do DC smoothingdetect only one peak per chamber, no debug mode
        DcSmoothLengthS = 0;
        multiPeak = 0;
        debugOn = 0;
    elseif nargin == 8 % assume we want to detect only one peak per chamber, no debug mode
        multiPeak = 0;
        debugOn = 0;
    elseif nargin == 9 % assume no debug mode
        debugOn = 0;
    end

% prepare some helper variables
    samplingIntervalS = dataIn.timestamp(2) - dataIn.timestamp(1);
    AcSmoothLengthSamples = ceil(AcSmoothLengthS / samplingIntervalS);
    DcSmoothLengthSamples = ceil(DcSmoothLengthS / samplingIntervalS);
    
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

        % it should be possible to index peakData in the same way as
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
        % TODO: this block is single-peak specific. but we would like to
        % have a basic baseline subtration to display debug info nicely
        % -> maybe just subtract first point of data, remove baseline here?
        % TODO: these three if clauses below should not be necessary and
        % could be removed
        if (i > size(peakData.blLeft, 1))
            warning('over');
        end
        if (i > size(indices.startIndex,1))
            warning('over');
        end
        if (indices.startIndex(i) > size(dataIn.mag, 1))
            warning('over');
        end
        % TODO: structural change: remove bl left/right, instead take
        % average value as baseline, this is consistent with baseline
        % extraction from highpass filtering
        peakData.blLeft(i,:,1) = dataIn.mag(indices.startIndex(i),:);
        peakData.blLeft(i,:,2) = dataIn.phase(indices.startIndex(i),:);
        peakData.blLeft(i,:,3) = dataIn.x(indices.startIndex(i),:);
        peakData.blLeft(i,:,4) = dataIn.y(indices.startIndex(i),:);
        peakData.blRight(i,:,1) = dataIn.mag(indices.endIndex(i),:);
        peakData.blRight(i,:,2) = dataIn.phase(indices.endIndex(i),:);
        peakData.blRight(i,:,3) = dataIn.x(indices.endIndex(i),:);
        peakData.blRight(i,:,4) = dataIn.y(indices.endIndex(i),:);

        % depending on magPhaseString we work on magnitude or phase data
        % TODO: baseline subtraction is an alternative to HP filtering. if
        % we do highpass filtering, BL could be taken from there instead of
        % 
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

        % for debugging puposes show raw data
        if (debugOn ~= 0)
            figure(1);
            ts  = dataIn.timestamp(indices.startIndex(i):indices.endIndex(i));
            plot (ts, data, 'Color', 'green');
            le = {};
            le{1} = 'raw data';
            hold on;
        end
        
        % do AC/DC (highpass/lowpass) filtering of data if requested
        if (AcSmoothLengthSamples > 2)
            data = data - smooth(data, AcSmoothLengthSamples);
        else
            % TODO: do bl subtraction
        end
        if (DcSmoothLengthSamples > 2)
            data = smooth(data, DcSmoothLengthSamples);
        end

        % for debugging puposes show filtered data and stop execution after
        % each chamber (execution is advanced after pressing any key in
        % console
        if (debugOn ~= 0)
            ts  = dataIn.timestamp(indices.startIndex(i):indices.endIndex(i));
            plot (ts, data, 'Color', 'blue');
            le{2} = 'filtered data';
            plot([ts(1), ts(end)], [threshold, threshold], ':', 'Color', 'red', 'LineWidth', 5);
            le{3} = 'peak detection threshold';
            hold off;
            legend(le);
            xlabel('Time [s]');
            title(['chamber ', num2str(indices.chamberIndex(i)), ' iteration ', num2str(indices.iterationOfChamber(i))]);
            pause
        end

        % find extremum, only treat one peak per chamber and iteration
        if (multiPeak == 0)
            
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
        else % multiple peaks per chamber
            
            % todo:
%               1. detect regions over / under threshold
%               2. summarize regions which are close to one another
%               3. get extremum in region
%               4. get baseline val at peak from DC data
%               5. get peak vals at all freqs
        end
    end

end
