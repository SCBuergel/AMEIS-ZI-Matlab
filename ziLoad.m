function rawFile = ziLoad(file, numSamples, startSample)
% ZILOAD Loads a ziBin file into raw file format
%
%   R = ZILOAD(F) reads all samples from file F into R.
%
%   R = ZILOAD(F, N) reads first N samples from file F into R.
%
%   R = ZILOAD(F, N, S) reads sample S until S+N from file F into R.
%
%   sebastian.buergel@bsse.etz.ch, 2015

    narginchk(1,3);
    if nargin == 1 % assume we want to read entire file from beginning
        numSamples = inf;
        startSample = 0;
    elseif nargin == 2 % assume we want to read from beginning of file
        startSample = 0;
    end
    
    rawFile = [];
    %disp(['Loading file ', file, '...']);
    fid = fopen(file, 'r', 'ieee-be');
    if fid == -1
        error(['File ' file ' not found.']);
    end
    if (fseek(fid, startSample * 56, 0) ~= 0)   % multiply by 56 because we read 7 doubles of 8 byte each
        return; % we try to load chunk by chunk 
                % until we get no more data from this function
                % therefore we do not provide an error here
        %         error(['Could not seek to sample ' startSample  ' in file ' file '.']);
    end
    raw = fread(fid, numSamples * 7, '*double');
    fclose(fid);
    if mod(size(raw), 7) ~= 0
        warning (['Illegal file size of ziBin file detected in file ', file, '.']);
    end
    
    rawFile.timestamp = raw(1:7:end);
    rawFile.x = raw(2:7:end);
    rawFile.y = raw(3:7:end);
    rawFile.frequency = raw(4:7:end);
    rawFile.bits = uint32(raw(5:7:end));
    %data.auxin0 = raw(6:7:end);    % unused, skip for performance reasons
    %data.auxin1 = raw(7:7:end);
    
    % we need to make sure each column (timestamp, x, y, frequency, bits)
    % is equally long, if they are not, crop to length of shortest
    % this happens, e.g. when copying a file which is currently being
    % recorded
    for runs=1:2
        dataOversize = size(rawFile.timestamp, 1) - size(rawFile.x, 1);
        if (dataOversize > 0)
            rawFile.timestamp = rawFile.timestamp(1:end-dataOversize);
        elseif (dataOversize < 0)
            rawFile.x = rawFile.x(1:end+dataOversize);
        end

        dataOversize = size(rawFile.timestamp, 1) - size(rawFile.y, 1);
        if (dataOversize > 0)
            rawFile.timestamp = rawFile.timestamp(1:end-dataOversize);
        elseif (dataOversize < 0)
            rawFile.y = rawFile.y(1:end+dataOversize);
        end

        dataOversize = size(rawFile.timestamp, 1) - size(rawFile.frequency, 1);
        if (dataOversize > 0)
            rawFile.timestamp = rawFile.timestamp(1:end-dataOversize);
        elseif (dataOversize < 0)
            rawFile.frequency = rawFile.frequency(1:end+dataOversize);
        end

        dataOversize = size(rawFile.timestamp, 1) - size(rawFile.bits, 1);
        if (dataOversize > 0)
            rawFile.timestamp = rawFile.timestamp(1:end-dataOversize);
        elseif (dataOversize < 0)
            rawFile.bits = rawFile.bits(1:end+dataOversize);
        end
    end
end
