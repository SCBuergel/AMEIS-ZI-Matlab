function [allIndices, newIndices] = getIndices(dataRaw, skipSamplesStart, prevIndices)
%GETINDICES returns data structures which can be accessed by chamber number
%and iteration, first return value is merged with allIndices (if provided),
%newIndices are just the new indices
% 
%   I = GETINDICES(D) processes raw data D and creates a structure I with
%   the following fields:
%     I.startIndex         - index of samples in the raw data where the chamber
%                            data starts
%     I.startIndex         - index of samples in the raw data where the chamber
%                            data ends
%     I.chamberIndex       - index of chamber
%     I.iterationOfChamber - iteration of chamber, e.g. when a chamber is
%                            recorded for the 5th time, this field has the
%                            value 4 (0-based)
% 
%   I = GETINDICES(D, S) skips the first S samples of each chamber, this
%   data is typically noisy (startIndex has this value as an offset)
% 
%   I = GETINDICES(D, S, P) combines the new indices with the previously
%   existing ones passed in P into I
% 
% % example 1: this now allows you to, e.g. plot the 51st iteration of chamber 4 by:
% figure(1);
% index=find(indices.iterationOfChamber==50 & indices.chamberIndex==4);
% iStart=indices.startIndex(index);
% iEnd=indices.endIndex(index);
% plot(dataRaw.timestamp(iStart:iEnd), dataRaw.mag(iStart:iEnd));
% 
% % example 2: color code the first 10 iterations of each chamber
% figure(1);
% cols = hsv(15);
% plot (dataRaw.ts, dataRaw.mag, 'Color', [0 0 0]);
% hold on;
% for cIt = 0:10
%     for cChamber = 1:15
%         index=find(indices.iterationOfChamber==cIt & indices.chamberIndex==cChamber);
%         iStart=indices.startIndex(index);
%         iEnd=indices.endIndex(index);
%         plot(dataRaw.timestamp(iStart:iEnd), dataRaw.mag(iStart:iEnd), 'Color', cols(cChamber,:), 'LineWidth', 3);
%     end
% end
% hold off;
% 
% % example 3: show which iterations of which chambers are available
% figure(1);
% plot(indices.iterationOfChamber, indices.chamberIndex, 'x')
% 
%   sebastian.buergel@bsse.etz.ch, 2015

    narginchk(1,3);

    if nargin == 1 % assume we do not want to skip any samples
        skipSamplesStart = 0;
        prevIndices = [];
    elseif nargin == 2 % assume we do not have previously existing indices
        prevIndices = [];
    end
%     disp('Getting indices...');
    %{
        TODO: pass matrix with indices where each bit is found and parse
              chamber(i)=dio(i)*lut
              chamber(i, 1) = dio(i, 1)*lut(1)
              -> stackoverflow how to do this efficiently...
    %}

    % get chamber indices from recorded HF2 DIO bit sequence
    
    % this version was used for the 2015 uTAS data
%     chamberIndices = bitshift(dataRaw.bits, 20, 'uint32') / uint32(2^28); % translates raw DIO bits to 0 or chamber index (1-15), this operation depends on version of AMEIS Arduino firmware!

    % this version was used for the dataset 2015-06-05-19-41-00 (human
    % islets)
    chamberIndices = bitshift(dataRaw.bits, 8, 'uint32') / uint32(2^28); % translates raw DIO bits to 0 or chamber index (1-15), this operation depends on version of AMEIS Arduino firmware!
    
    % find times at which chamber index changes (switching)
    switchIndices = find(diff(double(chamberIndices)) ~= 0);
    
    % ignore all switch indices which would be cropped off
    switchIndices = switchIndices(diff(switchIndices)>skipSamplesStart);
    
    % TODO: first and last chamber are cropped, the start of the last
    % chamber should be returned, the absolut position in the file
    % calculated and used as a seek position in the loading of the next
    % chunk
    % TODO: show error/warning if there is less than one chamber in a chunk
    % (would lead to an endless loop)
    
    % find start and end times of chamber
    newIndices.startIndex = switchIndices(1:end-1) + skipSamplesStart;
    newIndices.endIndex = switchIndices(2:end);
    % find chamber ids
    newIndices.chamberIndex = chamberIndices(switchIndices(2:end));
    if (isempty(prevIndices))
        allIndices.startIndex = newIndices.startIndex;
        allIndices.endIndex = newIndices.endIndex ;
        allIndices.chamberIndex = newIndices.chamberIndex;
    else
        allIndices.startIndex = [prevIndices.startIndex; newIndices.startIndex];
        allIndices.endIndex = [prevIndices.endIndex; newIndices.endIndex];
        allIndices.chamberIndex = [prevIndices.chamberIndex; newIndices.chamberIndex];
    end
    
    % find chamber ids
    uinds = unique(allIndices.chamberIndex);
    % count how often each chamber index has been found
    allIndices.iterationOfChamber = zeros(size(allIndices.chamberIndex));
    for i=uinds'
        cnt = conv(double(allIndices.chamberIndex==i),ones(size(allIndices.chamberIndex)));
        indicesOfChambers = find(allIndices.chamberIndex==i);
        allIndices.iterationOfChamber(indicesOfChambers) = cnt(indicesOfChambers);
    end

    % find chamber ids for newIndices
    uinds = unique(newIndices.chamberIndex);
    % count how often each chamber index has been found
    newIndices.iterationOfChamber = zeros(size(newIndices.chamberIndex));
    for i=uinds'
        cnt = conv(double(newIndices.chamberIndex==i),ones(size(newIndices.chamberIndex)));
        indicesOfChambers = find(newIndices.chamberIndex==i);
        newIndices.iterationOfChamber(indicesOfChambers) = cnt(indicesOfChambers);
    end

end
