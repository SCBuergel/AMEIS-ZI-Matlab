function [ smoothedChamberData ] = smoothData( dataRaw)
%SPLITDATATOCHAMBERS extracts baseline and smoothed data from raw.
%   Detailed explanation goes here
    
    smoothedChamberData = dataRaw;
    
    starts = indices.startIndex;
    for (i = 1:size(startIndices, 1))
        %TODO: find out which values actually need to be smoothed and
        %      change/create those here
    end
    
    smoothLengthForBaselineS = 4;
    smoothLengthForPeakDetectionS = 0.02;

    smoothedChamberData.start = dataRaw.ts(startSamp);
    smoothedChamberData.ts = dataRaw.ts(startSamp:endSamp) - dataRaw.ts(startSamp);
    sampleRate = smoothedChamberData.ts(2)-smoothedChamberData.ts(1);
    
    smoothLengthForBaselineSamples = ceil(smoothLengthForBaselineS / sampleRate);
    smoothLengthForPeakDetectionSamples = ceil(smoothLengthForPeakDetectionS / sampleRate);
    smoothedChamberData.chamberIndex = chamberIndex;
    smoothedChamberData.timeIndex = timeIndex;

    for freqIndex=1:8
        smoothedChamberData.mag(freqIndex,:)= dataRaw.mag{freqIndex}(startSamp:endSamp) - dataRaw.mag{freqIndex}(startSamp);
        smoothedChamberData.magSmoothed(freqIndex,:) = smooth(smoothedChamberData.mag(freqIndex,:), smoothLengthForBaselineSamples);
        smoothedChamberData.magAc(freqIndex,:) = smoothedChamberData.mag(freqIndex,:) - smoothedChamberData.magSmoothed(freqIndex,:);
        smoothedChamberData.magAcSmoothed(freqIndex,:) = smooth(smoothedChamberData.magAc(freqIndex,:), smoothLengthForPeakDetectionSamples);
        smoothedChamberData.phase(freqIndex,:) = dataRaw.phase{freqIndex}(startSamp:endSamp)-dataRaw.phase{freqIndex}(startSamp);
        smoothedChamberData.phaseSmoothed(freqIndex,:) = smooth(smoothedChamberData.phase(freqIndex,:), smoothLengthForBaselineSamples);
        smoothedChamberData.phaseAc(freqIndex,:) = smoothedChamberData.phase(freqIndex,:) - smoothedChamberData.phaseSmoothed(freqIndex,:);
        smoothedChamberData.phaseAcSmoothed(freqIndex,:) = smooth(smoothedChamberData.phaseAc(freqIndex,:), smoothLengthForPeakDetectionSamples);
        smoothedChamberData.BlMagMean(freqIndex) = mean(dataRaw.mag{freqIndex}(startSamp:endSamp));
        smoothedChamberData.BlMagStd(freqIndex) = std(dataRaw.mag{freqIndex}(startSamp:endSamp));
        smoothedChamberData.BlPhaseMean(freqIndex) = mean(dataRaw.phase{freqIndex}(startSamp:endSamp));
        smoothedChamberData.BlPhaseStd(freqIndex) = std(dataRaw.phase{freqIndex}(startSamp:endSamp));
    end
    
%     if (doPlot)
%         grayVal = 0.9;
%         figure(4);
%         colors = hsv(7);
%         lengendEntries = {};
%         lengendHandles = [];
%         for freqIndex=1:5;
%             freq = dataRaw.f(freqIndex);
%             freqString = '';
%             if (freq > 1e9)
%                 freqString = [num2str(freq/1e9), ' GHz'];
%             elseif (freq > 1e6)
%                 freqString = [num2str(freq/1e6), ' MHz'];
%             elseif (freq > 1e3)
%                 freqString = [num2str(freq/1e3), ' kHz'];
%             else
%                 freqString = [num2str(freq), ' Hz'];
%             end
% 
%             lengendEntries{freqIndex} = freqString;
%             lineWidth=1;
%             subplot(2,2,1);
%             plot(smoothedChamberData.ts, smoothedChamberData.mag(freqIndex,:), 'Color', colors(freqIndex,:), 'LineWidth', lineWidth);
%             hold on;
%             plot(smoothedChamberData.ts, smoothedChamberData.magSmoothed(freqIndex,:), '--', 'Color', colors(freqIndex,:), 'LineWidth', lineWidth);
%             subplot(2,2,3);
%             plot(smoothedChamberData.ts, smoothedChamberData.magAc(freqIndex,:), 'Color', [grayVal grayVal grayVal], 'LineWidth', lineWidth);
%             hold on;
%             plot(smoothedChamberData.ts, smoothedChamberData.magAcSmoothed(freqIndex,:), '--', 'Color', colors(freqIndex,:), 'LineWidth', 2);
% 
%             subplot(2,2,2);
%             plot(smoothedChamberData.ts, smoothedChamberData.phase(freqIndex,:), '--', 'Color', colors(freqIndex,:), 'LineWidth', lineWidth);
%             hold on;
%             plot(smoothedChamberData.ts, smoothedChamberData.phaseSmoothed(freqIndex,:), 'Color', colors(freqIndex,:), 'LineWidth', lineWidth);
%             subplot(2,2,4);
%             plot(smoothedChamberData.ts, smoothedChamberData.phaseAc(freqIndex,:), '--', 'Color', [grayVal grayVal grayVal], 'LineWidth', lineWidth);
%             hold on;
%             h=plot(smoothedChamberData.ts, smoothedChamberData.phaseAcSmoothed(freqIndex,:), 'Color', colors(freqIndex,:), 'LineWidth', 2);
%             lengendHandles(end+1)=h;
%         end
%         h(1)=subplot(2,2,1);
% %         xlim([2 5.5]);
%         title(['Chamber ', num2str(chamberIndex), ', t = ', num2str(smoothedChamberData.start/3600, '%2.1f'), 'h']);
%         ylabel('Magnitude (raw / baseline)');
%         xlabel('Time [s]');
%         hold off;
%         h(2)=subplot(2,2,3);
%         ylabel('AC Magnitude (raw / smoothed)');
%         xlabel('Time [s]');
%         legend(lengendHandles, lengendEntries, 'Location', 'SouthEast');
%         hold off;
%         h(3)=subplot(2,2,2);
%         ylabel('Phase (raw / baseline)');
%         xlabel('Time [s]');
%         hold off;
%         h(4)=subplot(2,2,4);
%         ylabel('AC Phase (raw / smoothed)');
%         xlabel('Time [s]');
%         hold off;
%         linkaxes(h, 'x');
%     end
end

