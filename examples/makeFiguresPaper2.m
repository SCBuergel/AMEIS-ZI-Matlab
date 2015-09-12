% todo: make sure that data loading works if we provide no frequencies to
%       loaded: is the default 1:8 ok if Freq1.ziBin e.g. doesnt exist? 
%       -> this does not work for now but user can simply specify which
%       files to load by setting the corresponding frequencies by e.g.
%       ah.freqs = 2:8

addpath('..\'); % parent path contains all vital functions
ah=initAmeis('C:\Users\sbuergel\Dropbox\AMEIS-bio-paper\data\', 1e-5);
ah.maxChunks = 1;
ah.startChunkIndex = 60;
ah.skipInitialSamples = 3000;
ah.peakDetectionFreqIndex = 3;
ah.minPeakDistS = 0.5;
ah.multiPeak = 1;
ah.AcSmoothLengthS = 1;
ah.DcSmoothLengthS = 0.1;
ah.samplesPerChunk = 2e5;
% peakData2 = processFolders(ah);

%% Figure 4a: exemplary time domain data
figure(4);
subplot(1, 2, 1);
freq = 3;
chamber = 7;
chunkIndex = 56;
dataRaw=loadData(ah.dataFolders, ...
    ah.samplesPerChunk, ah.samplesPerChunk * chunkIndex, ah.freqs);
indices = getIndices(dataRaw, ah.skipInitialSamples);
i = find(indices.chamberIndex == chamber);
s = indices.startIndex(i)-1400;
e = indices.endIndex(i);
ts1 = dataRaw.timestamp(s(1):e(1));
le={}
le{1}= ['t = ' num2str(ts1(1)./3600), 'h'];
ts1 = ts1 - ts1(1);
plot(ts1, dataRaw.mag(s(1):e(1), freq)/1e3, 'Color', [0 0.6 0], 'LineWidth', 2);
% hold on;
% ts2 = dataRaw.timestamp(s(2):e(2));
% ts2(1)
% le{2}= ['t = ' num2str(ts2(1)./3600), 'h'];
% ts2 = ts2 - ts2(1);
% plot(ts2, dataRaw.mag(s(2):e(2), freq)/1e3, 'Color', [1 0.5 0], 'LineWidth', 2);
% hold off;
xlabel('Time [s]');
ylabel(['Raw current (' num2str(dataRaw.f(freq)/1e3) ' kHz) [\mu{}A]']);
title(['Chamber ', num2str(chamber)]);
legend(le);

%% Figure 4:b cardiac beating over 15h
figure(4);
subplot(1, 2, 2);
chamber = 7;
i2 = find(peakData2.chamberIndex == chamber & peakData2.meanInterval > 0 & peakData2.stdInterval < 0.05);
errorbar(peakData2.startTimestampChamberS(i2)./3600, 1./peakData2.meanInterval(i2), peakData2.stdInterval(i2), '.', 'Color', 'red');
le={};
le{1}=['Chamber ' num2str(chamber)];
% hold on;
% i7 = find(peakData2.chamberIndex == 7 & peakData2.meanInterval > 0 & peakData2.stdInterval < 0.05);
% errorbar(peakData2.startTimestampChamberS(i7)./3600, 1./peakData2.meanInterval(i7), peakData2.stdInterval(i7), '.', 'Color', 'blue');
% le{2}='Chamber 7';
% hold off;
legend(le, 'Location', 'SouthWest');
ylabel('Beating frequency [Hz]');
xlabel('Time [h]');
xlim([-0.5 19.5]);

%% display distribution of beating intervals for different times - no significant change observed
figure(10);
i7 = find(peakData2.chamberIndex == 7 & peakData2.meanInterval > 0 & peakData2.stdInterval < 0.1);
i7b = i7([1, 11, 40, 60, 95]);
cols = jet(size(i7b,1));
le = {};
for i=1:size(i7b,1)
    [nb,xb]=hist(1./diff(peakData2.timestampPeak{i7b(i)}), 5);
    bh=bar(xb,nb);
    le{i} = ['t = ' num2str(peakData2.timestampPeak{i7b(i)}(1)./3600) 'h'];
    set(bh,'facecolor', cols(i,:));
    hp = arrayfun(@(x) allchild(x), bh);
    set(hp, 'FaceAlpha', 0.7)
    hold on;
end
legend(le);
xlabel('Beating frequency [Hz]');
ylabel('Count');
hold off;

%% cardio - display distribution of beating intervals over one chamber for different times - no significant change observed
figure(11);
i7 = find(peakData2.chamberIndex == 7 & peakData2.meanInterval > 0 & peakData2.stdInterval < 0.1);
i7b = i7([1, 11, 40, 60, 95]);
cols = jet(size(i7b,1));
le = {};
for i=1:size(i7b,1)
    t = peakData2.timestampPeak{i7b(i)}(1:end-1);
    t = t - t(1);
    plot(t, (1./diff(peakData2.timestampPeak{i7b(i)})), ':o', 'Color', cols(i,:), 'LineWidth', 2);
    hold on;
    le{i} = ['t = ' num2str(peakData2.timestampPeak{i7b(i)}(1)./3600) 'h'];
    xlabel('Time [s]');
    ylabel('Beat frequency [Hz]');
    xlim([min(t) - 0.5, max(t) + 0.5]);
%     pause;
end
hold off;
title('Chamber 7');
legend(le);

%% cardio - standard deviation of beating interval
figure(12);
i2 = find(peakData2.chamberIndex == 2 & peakData2.meanInterval > 0);
i7 = find(peakData2.chamberIndex == 7 & peakData2.meanInterval > 0);
% p2bl=cellfun(@median, {peakData2.P2Bl{1,:,4}});
semilogy(peakData2.startTimestampChamberS(i2)./3600, peakData2.stdInterval(i2), 'o', 'Color', 'red');
hold on;
semilogy(peakData2.startTimestampChamberS(i7)./3600, peakData2.stdInterval(i7), 'o', 'Color', 'blue');
hold off;
ylabel('Beating interval standard deviation [s]');
title('Chamber 7');
xlabel('Time [h]');
xlim([-0.5 19.5]);
%%
median(peakData2.stdInterval(i2))
median(peakData2.stdInterval(i7))

%% cardio - plot time domain data with high standard deviation to find out what is going on - e.g. here long recording of chamber due to (manual?) interruption of experiment
figure(13);
freq = 3;
chunkIndex = 59;
dataRaw=loadData(ah.dataFolders, ...
    ah.samplesPerChunk, ah.samplesPerChunk * chunkIndex, ah.freqs);
indices = getIndices(dataRaw, ah.skipInitialSamples);
i = find(indices.chamberIndex == 2);
s = indices.startIndex(i(1));
e = indices.endIndex(i(1));
ts = dataRaw.timestamp(s:e);
ts = ts - ts(1);
plot(ts, dataRaw.mag(s:e, freq)./1e3);
xlabel('Time [s]');
ylabel(['Raw current (' num2str(dataRaw.f(freq)/1e3) ' kHz) [\mu{}A]']);
title(['Chamber ', num2str(chamber)]);

%% compare if median beat intervals are very different from mean (no theyre not but the curve is less smooth)
figure(14);
% for chamber = 1:15
    chamber = 2;
    i = find(peakData2.chamberIndex == chamber);
%     errorbar(peakData2.startTimestampChamberS(i), peakData2.meanInterval(i), peakData2.stdInterval(i), '.');
    plot(peakData2.startTimestampChamberS(i)./3600, 1./peakData2.meanInterval(i), '.', 'Color', 'red');
    hold on;
    le = {};
    le{1} = 'Mean beating interval [Hz]';
    plot(peakData2.startTimestampChamberS(i)./3600, cellfun(@diffMed, {peakData2.timestampPeak{i}}), '.', 'Color', 'blue');
    hold off;
    le{2} = 'Median beating interval [Hz]';
    xlabel('Time [h]');
    ylabel('Beating frequency [s]');
    title(['Chamber ', num2str(chamber)]);
    legend(le, 'Location', 'SouthWest');
%     pause;
% end

%% cardio - beating and baseline over 15h
figure(15);
x1=subplot(1, 2, 1);
i2 = find(peakData2.chamberIndex == 2 & peakData2.meanInterval > 0 & peakData2.stdInterval < 0.05);
errorbar(peakData2.startTimestampChamberS(i2)./3600, 1./peakData2.meanInterval(i2), peakData2.stdInterval(i2), '.', 'Color', 'red');
le={};
le{1}='Chamber 2';
hold on;
i7 = find(peakData2.chamberIndex == 7 & peakData2.meanInterval > 0 & peakData2.stdInterval < 0.05);
errorbar(peakData2.startTimestampChamberS(i7)./3600, 1./peakData2.meanInterval(i7), peakData2.stdInterval(i7), '.', 'Color', 'blue');
le{2}='Chamber 7';
hold off;
legend(le, 'Location', 'SouthWest');
ylabel('Beating frequency [Hz]');
xlabel('Time [h]');
xlim([-0.5 19.5]);

x2=subplot(1, 2, 2);
plot(peakData2.startTimestampChamberS(i2)./3600, peakData2.baseline(1,i2,3)/1000*1e6, 'o', 'Color', 'red');
hold on;
plot(peakData2.startTimestampChamberS(i7)./3600, peakData2.baseline(1,i7,3)/1000*1e6, 'o', 'Color', 'blue');
hold off;
ylabel('Baseline current [\mu{}A]');
xlabel('Time [h]');
xlim([-0.5 19.5]);

