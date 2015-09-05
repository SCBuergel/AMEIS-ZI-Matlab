function [rawContainer] = loadData(folder, numSamples, startSample, freqIndices)
%LOADDATA reads ziBin files into raw container format
% 
%   D = LOADDATA(F) loads data from folder F into the custom data structure
%   D. All samples from all 8 files (Freq1.ziBin ... Freq8.ziBin) are
%   loaded.
% 
%   D = LOADDATA(F,N) loads the first N samples from each file into the
%   custom data structure D. All samples from all 8 files (Freq1.ziBin ...
%   Freq8.ziBin) are loaded.
% 
%   D = LOADDATA(F,N,S) loads the N samples, starting at sample S from each
%   file into theasd custom data structure D. All samples from all 8 files
%   (Freq1.ziBin ... Freq8.ziBin) are loaded. (For chunk-by-chunk
%   processing of data)
% 
%   D = LOADDATA(F,N,S,I) loads the first N samples from each file into the
%   custom data structure. Only the frequency indices in the vector I are
%   loaded. LOADDATA(F,N,3:5) therefore only loads Freq3.ziBin,
%   Freq4.ziBin, Freq5.ziBin
%
%   D is a custom structure with the following fields:
%   D.f         - vector containing frequencies for each of the files in I
%   D.x         - matrix with columns for each frequency of the files in I,
%   and rows with real component of signal for each sample
%   D.y         - matrix with columns for each frequency of the files in I,
%   and rows with imaginary component of signal for each sample
%   D.mag       - matrix with columns for each frequency of the files in I,
%   and rows with magnitude values for each sample
%   D.phase       - matrix with columns for each frequency of the files in I,
%   and rows with phase values for each sample
%   D.timestamp - vector containing timestamps of each sample
%   D.bits      - vector containing DIOs of each sample
%
%   sebastian.buergel@bsse.etz.ch, 2015

    narginchk(1,4);

    if nargin == 1 % assume we want to read all samples and all 8 frequencies
        numSamples = inf;
        startSample = 0;
        freqIndices = 1:8;
    elseif nargin == 2 % assume we want to read all 8 frequencies from the beginning
        startSample = 0;
        freqIndices = 1:8;
    elseif nargin == 3 % assume we want to read all 8 frequencies
        freqIndices = 1:8;
    end
    rawContainer = {};
    
    % find all ziBin files
    c=0;
	firstFileName = [folder, 'Freq', num2str(freqIndices(1)), '.ziBin'];    % might be needed for warning messages
    for f=freqIndices
        c = c + 1;  % we use this one in case we are not loading indices 1:8 but, e.g. 4:8
        filename = [folder, 'Freq', num2str(f), '.ziBin'];
%         disp(['Loading file ' filename]);

        newData = ziLoad(filename, numSamples, startSample);

        % if we did not receive any more data, then probably we seeked over
        % the end of file and have no more chunks to process
        if (isempty(newData))
            return;
        end
        
        % the first sample is used to zero the timestamps
        firstSample = ziLoad(filename, 1, 0);
        newData.timestamp = newData.timestamp - firstSample.timestamp(1);
        
        % check if sample timestamps are consistent over all files that
        % we load
        if (c ~= 1)
            if (size(newData.timestamp, 1) ~= size(rawContainer.timestamp, 1))
                % if they are of different lengnths, crop to match
                newDataOversize = size(newData.timestamp, 1) - size(rawContainer.timestamp, 1);
            	warnMsg = ['Number of timestamps in file ', filename, ' differ from number of timestamps in ', firstFileName, '! Cropping ', num2str(abs(newDataOversize)), ' from '];
                if (newDataOversize > 0)
                    % new data is longer than previously loaded data ->
                    % crop new data
                    newData.timestamp = newData.timestamp(1:end-newDataOversize);
                    warnMsg = [warnMsg, filename];
                elseif (newDataOversize < 0)
                    % new data is shorter than previously loaded data ->
                    % crop previously loaded data
                    rawContainer.timestamp = rawContainer.timestamp(1:end+newDataOversize);
                    warnMsg = [warnMsg, filename];
                end
                warning(warnMsg);
            end
            
            % check if timestamps of files are matching, otherwise crop
            % samples with mismatching timestamps
            if (sum(newData.timestamp - rawContainer.timestamp) ~= 0)
                minMismatchingIndex = min(find((newData.timestamp - rawContainer.timestamp) ~= 0));
                indicesToCrop = size(newData.timestamp, 1) - minMismatchingIndex;
                newData.timestamp = newData.timestamp(1:end - indicesToCrop);
            	warning(['Timestamps in file ', filename, ' differ from timestamps in ', firstFileName, ', cropped ', num2str(indicesToCrop), ' samples.']);
        	end
        else
            % timestamps are stored from first file only (all others should
            % match after having been cropped above)
%             rawContainer.tStart = newData.timestamp(1);

            rawContainer.timestamp = newData.timestamp;% - rawContainer.tStart;
        end
        
        % check if number of DIO bits are consistent over all files that
        % we load
        if (c ~= 1)
            if (size(newData.bits, 1) ~= size(rawContainer.bits, 1))
            	warning(['Number of bits in file ', filename, ' differ from number of bits in ', firstFileName, '!']);
                % if they are of different lengnths, crop to match
                for fcrop = 1:f
                    newDataOversize = size(newData.bits, 1) - size(rawContainer.bits, 1);
                    if (newDataOversize > 0)
                        % new data is longer than previously loaded data ->
                        % crop new data
                        newData.bits = newData.bits(1:end-newDataOversize);
                    elseif (newDataOversize < 0)
                        % new data is shorter than previously loaded data ->
                        % crop previously loaded data
                        rawContainer.bits = rawContainer.bits(1:end+newDataOversize);
                    end
                end
            end
            % It is ok if bits vary slightly from file to file since the
            % bit write is not in sync with sampling data during the
            % recording. This data is fairly robust, we therefore only rely
            % on the bits in the first file.
        else
            % bits are stored from first file only (all others should
            % match after having been cropped above)
            rawContainer.bits = newData.bits;
        end
        
        % mag, phase, f are not necessarily of same length for all files,
        % therefore we first read them into cell array and later try to
        % crop them to equal length and convert into matrices
        rawContainer.x{c} = newData.x;
        rawContainer.y{c} = newData.y;
        rawContainer.mag{c} = sqrt(newData.x.^2 + newData.y.^2);
        rawContainer.phase{c} = 180/pi * angle(newData.x + 1i * newData.y);
        rawContainer.f(c) = newData.frequency(1);
         
        % check if frequency is constant over the whole data set
        if (sum(diff(newData.frequency) ~= 0) > 1)
        	warning(['Frequency in file ', filename, ' is not constant!']);
        end
    end
    
    if (size(rawContainer.timestamp, 1) ~= size(rawContainer.bits, 1))
        error('found different number of bits and timestamps');
    end
    
    % ensures that timestamp, mag, phase, bits are all same lengths for all files
    for runs = 1:2      % run twice two accomodate for all changes recursively
        c = 0;
        for f=freqIndices
            c = c + 1;  % we use this one in case we are not loading indices 1:8 but, e.g. 4:8
            dataOversize = size(rawContainer.mag{c}, 1) - size(rawContainer.timestamp, 1);
            if (dataOversize > 0) % mag/phase bigger than timestamp
                rawContainer.x{c} = rawContainer.x{c}(1:end-dataOversize);
                rawContainer.y{c} = rawContainer.y{c}(1:end-dataOversize);
                rawContainer.mag{c} = rawContainer.mag{c}(1:end-dataOversize);
                rawContainer.phase{c} = rawContainer.phase{c}(1:end-dataOversize);
            elseif (dataOversize < 0) % timestamp bigger than mag/phase
                rawContainer.timestamp = rawContainer.timestamp(1:end-dataOversize);
                rawContainer.bits = rawContainer.bits(1:end-dataOversize);
            end
        end
    end
    
    % now data from all files should have equal length and can be converted
    % back into matrices
    rawContainer.x = cell2mat(rawContainer.x);
    rawContainer.y = cell2mat(rawContainer.y);
    rawContainer.mag = cell2mat(rawContainer.mag);
    rawContainer.phase = cell2mat(rawContainer.phase);
end
