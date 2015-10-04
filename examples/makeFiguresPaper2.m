% todo: make sure that data loading works if we provide no frequencies to
%       loaded: is the default 1:8 ok if Freq1.ziBin e.g. doesnt exist? 
%       -> this does not work for now but user can simply specify which
%       files to load by setting the corresponding frequencies by e.g.
%       ah.freqs = 2:8

addpath('..\'); % parent path contains all vital functions
%% selected time domain peaks of cancer spheroids

%% cancer - selected chambers:
% long-term N\DeltaI vs time for different 5FU concentrations
% optical size
% atp values

chambers = [2, 3, 7, 12, 14];
ctrlIs = [1, 2, 8];
c1Is = [3, 4, 5];
c2Is = [6, 7, 10];
c3Is = [11, 12, 13];
dmsoIs = [9, 14, 15];

% cancer - ATP assay

% averaged ATP luminosity of reference values
refLumVals = [6458016, 786421, 377791, 77449];

% reference ATP concentrations
refConcVals = [1, 0.1, 0.05, 0.001];

% ATP luminosity values of spheroids
spheroidVals = [4183171, 6206299, 4870101, 5347990, 4725827, 3279807, 3984614, 7190324, 6810642, 3587530, 1543350, 2278822, 525714, 4807521, 5844767];

% linear interpolation of reference values
[p, S] = polyfit(refConcVals, refLumVals, 1);

% estimation of ATP concentration of spheroids
spheroidConcs = (spheroidVals - p(2)) ./ p(1);

% % plot reference measurements, interpolation and spheroid concentrations
% mi = min(refConcVals);
% ma = max(spheroidConcs);
% x = mi:(ma-mi)/100:ma;
% y = x * p(1) + p(2);
% figure(5);
% loglog(refConcVals, refLumVals, 'o');
% hold on;
% loglog(x, y, 'b:');
% loglog(spheroidConcs, spheroidVals, 'rx', 'LineWidth', 2, 'MarkerSize', 20);
% axis square;
% hold off;

le = {};
figure(6);
count = 0;
for c = chambers
    count = count + 1;
    markerSize = 10;
    if (~isempty(find(ctrlIs == c)))
        % current chamber id is a control
        col = [228,26,28]/255; % colors from http://colorbrewer2.org/, 5 data classes, qualitatice, printer friendly, selected 3rd option (most pretty)
        le{end + 1} = 'Control';
        marker = 'x';
    elseif (~isempty(find(c1Is == c)))
        % current chamber id is a concentration 1
        col = [55,126,184]/255;
        le{end + 1} = '0.4 uM';
        marker = 'v';
    elseif (~isempty(find(c2Is == c)))
        % current chamber id is a concentration 2
        col = [77,175,74]/255;
        le{end + 1} = '4 uM';
        marker = 'o';
    elseif (~isempty(find(c3Is == c)))
        % current chamber id is a concentration 3
        col = [152,78,163]/255;
        le{end + 1} = '40 uM';
        marker = '^';
    elseif (~isempty(find(dmsoIs == c)))
        % current chamber id is a DMSO
        col = [255,127,0]/255;
        le{end + 1} = 'DMSO';
        marker = '+';
    else
        error(['Error: Unknown index ', num2str(c), '!']);
    end

%     le=cell(3,1);   % for legend entries
    bar(count, spheroidConcs(c), 'FaceColor', col, ...
        'EdgeColor', [0 0 0], 'LineWidth', 1, 'barwidth', 0.8)
    hold on;
end
hold off;
% legend(le);
xlim([0.5, count + 0.5]);
set(gca, 'XTick', 1:count);
set(gca, 'XTickLabel', le);
% xlabel('Chamber number');
ylabel('ATP concentration [units unclear]');

% cancer - selected chambers long-term N\DeltaI vs time for different 5FU concentrations
figure(2);
le = {};
for plotType = 1:2
    pH = [];
    for c = chambers
        markerSize = 10;
        if (~isempty(find(ctrlIs == c)))
            % current chamber id is a control
            col = [228,26,28]/255; % colors from http://colorbrewer2.org/, 5 data classes, qualitatice, printer friendly, selected 3rd option (most pretty)
            le{end + 1} = ['Control, chamber ', num2str(c)];
            marker = 'x';
        elseif (~isempty(find(c1Is == c)))
            % current chamber id is a concentration 1
            col = [55,126,184]/255;
            le{end + 1} = ['0.4 uM, chamber ', num2str(c)];
            marker = 'v';
        elseif (~isempty(find(c2Is == c)))
            % current chamber id is a concentration 2
            col = [77,175,74]/255;
            le{end + 1} = ['4 uM, chamber ', num2str(c)];
            marker = 'o';
        elseif (~isempty(find(c3Is == c)))
            % current chamber id is a concentration 3
            col = [152,78,163]/255;
            le{end + 1} = ['40 uM, chamber ', num2str(c)];
            marker = '^';
        elseif (~isempty(find(dmsoIs == c)))
            % current chamber id is a DMSO
            col = [255,127,0]/255;
            le{end + 1} = ['DMSO, chamber ', num2str(c)];
            marker = '+';
        else
            error(['Error: Unknown index ', num2str(c), '!']);
        end
        i = find(peakData.chamberIndex == c);
        ts = peakData.startTimestampChamberS(i);
        y = peakData.P2Bl(1, i, 5) ./ peakData.baseline(1, i, 5);
        red = 1;
        ts = ts(1:red:end) ./ 3600;
        y = y(1:red:end);
        y = y ./ y(1); % comment this line for \Delta{}I_{norm}, uncomment for \Delta{}I_{norm,0}
        if (plotType == 1)
            plot(ts, y, '.', 'Color', col * 0.7);
        else
            pH(end + 1) = plot(ts, smooth(y,100), '-', 'Color', col, 'LineWidth', 4);
        end
        hold on;
    end
end
xlim([0, 92]);
ylim([0.7, 2]); % for \Delta{}I_{norm,0}
% ylim([-0.16, -0.05]); % for \Delta{}I_{norm}
xlabel('Time [h]');
ylabel('\Delta I_{norm,0}');
% ylabel('\Delta I_{norm}');
legend(pH, le, 'Location', 'NorthWest');
hold off;

% cancer - selected chamber sizes optical
figure(3);
count = 0;
for c = chambers
    count = count + 1;
    markerSize = 10;
    if (~isempty(find(ctrlIs == c)))
        % current chamber id is a control
        col = [228,26,28]/255; % colors from http://colorbrewer2.org/, 5 data classes, qualitatice, printer friendly, selected 3rd option (most pretty)
    elseif (~isempty(find(c1Is == c)))
        % current chamber id is a concentration 1
        col = [55,126,184]/255;
    elseif (~isempty(find(c2Is == c)))
        % current chamber id is a concentration 2
        col = [77,175,74]/255;
    elseif (~isempty(find(c3Is == c)))
        % current chamber id is a concentration 3
        col = [152,78,163]/255;
    elseif (~isempty(find(dmsoIs == c)))
        % current chamber id is a DMSO
        col = [255,127,0]/255;
    else
        error(['Error: Unknown index ', num2str(c), '!']);
    end
    
    le=cell(3,1);   % for legend entries
    bar(count - 0.25, sizeChamber(1,c), 'FaceColor', col/2, ...
        'EdgeColor', [0 0 0], 'LineWidth', 1, 'barwidth', 0.25)
    le{1} = 'Day 0';
    hold on;
    bar(count, sizeChamber(2,c), 'FaceColor', col/1.5, ...
        'EdgeColor', [0 0 0], 'LineWidth', 1, 'barwidth', 0.25)
    le{2} = 'Day 2';
    le{3} = 'Day 4';
    bar(count + 0.25, sizeChamber(3,c), 'FaceColor', col, ...
        'EdgeColor', [0 0 0], 'LineWidth', 1, 'barwidth', 0.25)
end
hold off;
legend(le);
xlim([0.5, size(chambers,2) + 0.5]);
set(gca, 'XTick', 1:size(chambers,2));
set(gca, 'XTickLabel', {'Control', '0.4 uM', '4 uM', '40 uM', 'DMSO'});
% xlabel('Chamber number');
ylabel('Spheroid cross section [\mu{}m ^2]');
% set(gca,'XGrid','on')
% set(gca,'YGrid','off')
% xlim([0, count + 1]);

%% cancer - overview over all chambers: long-term N\DeltaI vs time for different 5FU concentrations
figure(1);
for c = 1:15
    markerSize = 10;
    switch(c)
        case 1
            col = [1 0 0];
            le = {'Control a - 1'};
            marker = 'x';
            markerSize = 15;
        case 2
            col = [0 0.8 0];
            le{c} = 'Control b - 2';
            marker = 'x';
            markerSize = 15;
        case 3
            col = [1 0 0];
            le{c} = '0.4 uM a - 3';
            marker = 'v';
        case 4
            col = [0 0.8 0];
            le{c} = '0.4 uM b - 4';
            marker = 'v';
        case 5
            col = [0 0 1];
            le{c} = '0.4 uM c - 5';
            marker = 'v';
        case 6
            col = [1 0 0];
            le{c} = '4 uM a - 6';
            marker = 'o';
        case 7
            col = [0 0.8 0];
            le{c} = '4 uM b - 7';
            marker = 'o';
        case 8
            col = [0 0 1];
            le{c} = 'Control c - 8';
            marker = 'x';
            markerSize = 15;
        case 9
            col = [1 0 0];
            le{c} = 'DMSO a - 9';
            marker = '+';
            markerSize = 15;
        case 10
            col = [0 0 1];
            le{c} = '4 uM c - 10';
            marker = 'o';
        case 11
            col = [1 0 0];
            le{c} = '40 uM a - 11';
            marker = '^';
        case 12
            col = [0 0.8 0];
            le{c} = '40 uM b - 12';
            marker = '^';
        case 13
            col = [0 0 1];
            le{c} = '40 uM c - 13';
            marker = '^';
        case 14
            col = [0 0.8 0];
            le{c} = 'DMSO b - 14';
            marker = '+';
            markerSize = 15;
        case 15
            col = [0 0 1];
            le{c} = 'DMSO c - 15';
            marker = '+';
            markerSize = 15;
    end
    i = find(peakData.chamberIndex == c);
    ts = peakData.startTimestampChamberS(i);
    y = peakData.P2Bl(1, i, 5) ./ peakData.baseline(1, i, 5);
    red = 100;
    ts = ts(1:red:end) ./ 3600;
    y = y(1:red:end);
%     y = y ./ y(5);
    plot(ts, y, marker, 'Color', col, 'MarkerSize', markerSize, ...
        'MarkerFaceColor', col, 'LineWidth', 3);
    title (['Chamber ', num2str(c)]);
%     ylim([-0.3, 0]);
    hold on;
end
legend(le, 'Location', 'NorthWest');
hold off;

%% cancer - rename files to random name for blind size extraction via Fiji
folder = 'C:\Users\sbuergel\Dropbox\MT-EIS-paper\data\pixRnd\'
filePattern = '*.bmp';
files = dir([folder filePattern]);
names = {files(1:end).name};
nameTable = cell(2,size(names,2));

alphabet = 'abcdefghijklmnopqrstuvwxyz';
numRands = length(alphabet); 
sLength = 10;%specify length of random string to generate

for c=1:size(names,2)
    %generate random string
    randName = [alphabet(ceil(rand(1,sLength)*numRands)), '.bmp'];
    nameTable{1,c} = names{c};
    nameTable{2,c} = randName;
    movefile([folder names{c}], [folder randName]);
end
save('nameTable.mat', 'nameTable');
%% add padding 0's to nameTable in case original filenames have different lengths (e.g. 1a.bmp vs 10a.bmp)

% find longest filename (e.g. '14a.bmp')
maxLen = max(cell2mat(strfind({nameTable{1,:}}, '.')));
for c = 1:size(nameTable,2)
    % get length of current filename
    curLen = strfind(nameTable{1,c}, '.');
    padStr = '';
    
    % pad difference to maximal length with zeros
    for z = curLen:maxLen
        padStr(end + 1) = '0';
    end
    nameTable{1,c} = [padStr, nameTable{1,c}];
end

%% plot sizes of spheroids vs chambers (for that we combine sizes measured by Fiji with nameTable)
% in order for this to work, you need to first run the random file rename
% section above, then manually measure spheroid sizes in Fiji and save to
% file, then add paddings 0's section above

% this file contains the sizes measured with Fiji.
% the format is a \t separated file with one header line.
% the first column is the measurement number (e.g. 1 to 45).
% the second column is the measured surface area.
fijiResultFile = 'C:\Users\sbuergel\Dropbox\MT-EIS-paper\data\pixRnd\zzz-FijiSizeMeasurements.txt';

fijiResults=dlmread(fijiResultFile, '\t', 1, 0);

% scale in micron/pixel (measure e.g. in Fiji by measuring width in pixel
% between electrodes (500um)
scale = 500/485;

% sort random names and get indix to random names in table
[name,indexRand] = sort(lower({nameTable{2,:}}));

% make cell array with entries for: original filename, random filename, fijiResult
nt = cell(3,size(fijiResults,1));
nt(1:2,:) = nameTable(:,indexRand);
nt(3,:) = num2cell(fijiResults(:,2));

% sort original names and get indix to original names in table
[name,indexOrig] = sort(lower({nt{1,:}}));

sizes = [nt{3,indexOrig}] .* scale^2;
sizeChamber(1,:) = sizes(1:3:end);
sizeChamber(2,:) = sizes(2:3:end);
sizeChamber(3,:) = sizes(3:3:end);
save('sizeChamber.mat', 'sizeChamber');

le=cell(3,1);   % for legend entries
plot(sizes(3:3:end), '^', 'LineWidth', 4, 'Color', [0 0 1]);
le{1} = 'Day 4';
hold on;
plot(sizes(2:3:end), 'o', 'LineWidth', 4, 'Color', [0 0.8 0]);
le{2} = 'Day 2';
plot(sizes(1:3:end), 'v', 'LineWidth', 4, 'Color', [1 0 0]);
le{3} = 'Day 0';
hold off;
legend(le);
set(gca, 'XTick', [1:size(sizes,2)/3]);
% set(ax, 'XTickLabel', [1:size(name,2)/3]);
xlabel('Chamber number');
ylabel('Spheroid cross section [\mu{}m ^2]');
set(gca,'XGrid','on')
set(gca,'YGrid','off')


%% is this the cardio data analysis???
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
alphabet = indices.startIndex(i)-1400;
e = indices.endIndex(i);
ts1 = dataRaw.timestamp(alphabet(1):e(1));
le={}
le{1}= ['t = ' num2str(ts1(1)./3600), 'h'];
ts1 = ts1 - ts1(1);
plot(ts1, dataRaw.mag(alphabet(1):e(1), freq)/1e3, 'Color', [0 0.6 0], 'LineWidth', 2);
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

%% cardio - time domain data with high standard deviation to find out what is going on - e.g. here long recording of chamber due to (manual?) interruption of experiment
figure(13);
freq = 3;
chunkIndex = 59;
dataRaw=loadData(ah.dataFolders, ...
    ah.samplesPerChunk, ah.samplesPerChunk * chunkIndex, ah.freqs);
indices = getIndices(dataRaw, ah.skipInitialSamples);
i = find(indices.chamberIndex == 2);
alphabet = indices.startIndex(i(1));
e = indices.endIndex(i(1));
ts = dataRaw.timestamp(alphabet:e);
ts = ts - ts(1);
plot(ts, dataRaw.mag(alphabet:e, freq)./1e3);
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

