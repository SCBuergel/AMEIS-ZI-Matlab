addpath('..\'); % parent path contains all vital functions

%%
% perform data extraction, warning this takes about 15 minutes, run the
% extraction only when necessary, then store the output peakData in file or
% just in memory
dataDir = 'C:\Users\sbuergel\Dropbox\MT-EIS-paper\data\2015-04-02-18-40-39\', ...
    'C:\Users\sbuergel\Dropbox\MT-EIS-paper\data\2015-04-04-14-09-08\'};
folderTimeOffsetsS = [0 44*3600];
peakData = processFolders(dataDirs, folderTimeOffsetsS);

%%
% raw current - Figure 3a, b
% rawData=loadData(dataDirs{1}, 1e6);
indices = getIndices(rawData, 100);

figure(3);
f = 5;
index = find(indices.chamberIndex>0 & (indices.iterationOfChamber==10 | indices.iterationOfChamber==11));
indexSelected = find(indices.chamberIndex>11 & indices.iterationOfChamber==10);
iStart=indices.startIndex(index(1));
iEnd=indices.endIndex(index(end) - 16);
    
subplot(2, 1, 1);
iStartC=indices.startIndex(indexSelected(1));
iEndC=indices.endIndex(indexSelected(1));
ts1 = rawData.timestamp(iStartC-270:iEndC+50) - rawData.timestamp(iStart);
current1 = rawData.mag(iStartC-270:iEndC+50, f) / 200 * 1e6;
plot(ts1, current1 - max(current1));
hold on;

iStartC=indices.startIndex(indexSelected(2));
iEndC=indices.endIndex(indexSelected(2));
ts2 = rawData.timestamp(iStartC-270:iEndC+50) - rawData.timestamp(iStart);
current2 = rawData.mag(iStartC-270:iEndC+50, f) / 200 * 1e6;
plot(ts2, current2 - max(current2));

iStartC=indices.startIndex(indexSelected(3));
iEndC=indices.endIndex(indexSelected(3));
ts3 = rawData.timestamp(iStartC-270:iEndC+50) - rawData.timestamp(iStart);
current3 = rawData.mag(iStartC-270:iEndC+50, f) / 200 * 1e6;
plot(ts3, current3 - max(current3));
xlim([ts1(1)  ts3(end)]);
ylim([-4, 0.5]);
hold off;
title('Figure 3a');

subplot(2, 1, 2);
ts = rawData.timestamp(iStart:iEnd) - rawData.timestamp(iStart);
current = rawData.mag(iStart:iEnd, f) / 200 * 1e6;
plot(ts, current);
ylabel([num2str(rawData.f(f) / 1e3), ' kHz current [\mu{A}]']);
title('Figure 3b');
ylim([-2 52]);
xlim([0  ts(end)]);

%%
% baseline and delta current spectra - figure 5
% 51.92-42.81
% 3.426 -4.468
c=2;
peakData = peakDataExt;
indices = find(peakData.chamberIndex==c);
selectedIndices = [10 610 1210 1250 1850 2450];
colors = hsv(3);
markers = {'-o', '--x'};
el={};
for i = 1:size(selectedIndices, 2)
    index = indices(selectedIndices(i));
    p2blCurrent = peakData.P2Bl(index, :, 1) / 200 * 1e6;
    blCurrent = peakData.blRight(index, :, 1) / 200 * 1e6;
    
    col = colors(mod(i, 3) + 1, :);
    mark = markers{ceil(i/3)};
    figure(5);
    subplot(2, 1, 1);
    semilogx(peakData.f, p2blCurrent, mark, 'Color', col);
    hold on;
    subplot(2, 1, 2);
    semilogx(peakData.f, blCurrent, mark, 'Color', col);
    el{i}=num2str(peakData.timestamp(index)/3600);
    hold on;
end

figure(5);
subplot(2, 1, 1);
hold off;
xlabel('Frequency [Hz]');
ylabel('\Delta current [\mu{A}]');
xlim([8.1e3 2.5e6]);
subplot(2, 1, 2);
hold off;
xlabel('Frequency [Hz]');
ylabel('Baseline current [\mu{A}]');
xlim([8.1e3 2.5e6]);
legend(el);




%%
% long-term - Figure 6
peakData = peakDataExt;
f=5;
el={};
cols=hsv(6);
figure(6);
chamberSelection=[2, 3, 4, 8, 9, 14];
for d=1:size(chamberSelection,2)
    c=chamberSelection(d);
    index = find(peakData.chamberIndex==c);

    p2blCurrent = peakData.P2Bl(index, f, 1);
    sp2blCurrent = smooth(p2blCurrent, 10);
    
    impp2bl = peakData.P2Bl(index, f, 3);
    simpp2bl = smooth(impp2bl, 10);
    
    blCurrent = peakData.blRight(index, f, 1);
    sblCurrent = smooth(blCurrent, 10);
    impbl = peakData.blRight(index, f, 3);
    simpbl = smooth(blCurrent, 10);
    
    normCurrent = p2blCurrent ./ blCurrent;
    snormCurrent = smooth(normCurrent, 10);

    ts = peakData.timestamp(index);
    if (mod(c, 4) == 0)
        marker = 'o';
    elseif (mod(c, 4) == 1)
        marker = 's';
    elseif (mod(c, 4) == 2)
        marker = '^';
    elseif (mod(c, 4) == 3)
        marker = 'v';
    end
    marker='.';
    if (c == 2)
        subplot(2, 2, 1);
        plot(ts./3600, p2blCurrent / 200 * 1e6, '.', 'Color', [0 0 0]);
        hold on;
        subplot(2, 2, 2);
        plot(ts./3600, normCurrent, '.', 'Color', [0 0 0]);
        hold on;
    end
    subplot(2, 2, 3);
    plot(ts./3600, snormCurrent, '.', 'Color', cols(d,:));
    hold on;
    el{d}=num2str(c);
end;

ax1=subplot(2, 2, 1);
hold off;
xlabel('Time[h]');
ylabel('\Delta{}I [\mu{}A]');
ylim([-10.5, -2.5]);
xlim([-5 97]);

ax2=subplot(2, 2, 2);
hold off;
xlabel('Time [h]');
ylabel('\Delta_{norm}I');
ylim([-0.165, -0.065]);
xlim([-5 97]);

ax3=subplot(2, 2, 3);
hold off;
xlabel('Time [h]');
ylabel('\Delta_{norm}I');
ylim([-0.23, -0.055]);
xlim([-5 97]);
legend(el, 'Location', 'SouthWest');
linkaxes([ax1, ax2, ax3], 'x');

% Figure 6d - data for hIS not showing any growth
% folder = 'C:\tempData\2015-06-05-19-41-00\';
% peakDataHIS = processFolders(folder);

subplot(2, 2, 4);
id = find(peakDataHIS.chamberIndex == 14);
plot(peakDataHIS.timestamp(id)/3600, peakDataHIS.P2Bl(id, 1, 1)./peakDataHIS.blRight(id, 1), '.');
ylim([-1.05e-2 5e-4]);
xlim([-1 37]);
title('Human islet');
xlabel('Time [h]');
ylabel('\Delta_{norm}I');




%%
% (not for paper)
% load some short sequences at some time points to compare imp P2BL
chunkIndex = 0;
samplesPerChunk = 1e5;
freqs = 5;
figure(10);
cols = hsv(4);
for c = 1:1 
    for p = 1:3
        switch p
            case 1
                chunkIndex = 2;
                dirIndex = 1;
            case 2
                chunkIndex = 150;
                dirIndex = 1;
            case 3
                chunkIndex = 300;
                dirIndex = 1;
            case 4
                chunkIndex = 2;
                dirIndex = 2;
            case 5
                chunkIndex = 150;
                dirIndex = 2;
            case 6
                chunkIndex = 300;
                dirIndex = 2;
        end
        subplot(3, 1, p);
        dataRaw = loadData(dataDirs{dirIndex}, samplesPerChunk, samplesPerChunk * chunkIndex, freqs);
        indices = getIndices(dataRaw, 100);
        i2 = find(indices.chamberIndex==2);
        s = indices.startIndex(i2(c));
        e = indices.endIndex(i2(c));
        t = (dataRaw.timestamp(s:e) - dataRaw.timestamp(s));
        y =  dataRaw.mag(s:e) .^ -1;% - 20./dataRaw.mag(s);
        plot(t, y, 'o', 'Color', cols(c,:), 'LineWidth', 2);
%         ylim([1750 2600]);
%         ylim([7.8e-3 0.0115]);
        hold on;
    end
end






%%
% (not for paper)
% plot different signals (impedance, voltage, different normalizations)
peakData = peakDataExt;
f=3;
el={};
cols=hsv(15);
chamberSelection=[2, 3, 4, 8, 9, 14]
for d=1:size(chamberSelection,2)
    c=chamberSelection(d);
    index = find(peakData.chamberIndex==c);

    p2blCurrent = abs(peakData.P2Bl(index, f, 1));
    ssigp2bl = smooth(p2blCurrent, 10);
    
    impp2bl = peakData.P2Bl(index, f, 3);
    simpp2bl = smooth(impp2bl, 10);
    
    blCurrent = peakData.blRight(index, f, 1);
    ssigbl = smooth(blCurrent, 10);
    impbl = peakData.blRight(index, f, 3);
    simpbl = smooth(blCurrent, 10);
    
    blX = peakData.blRight(index, f, 4);
    blY = peakData.blRight(index, f, 5);
    pkX = blX + peakData.P2Bl(index, f, 4);
    pkY = blY + peakData.P2Bl(index, f, 5);
    p2blX = peakData.P2Bl(index, f, 4);
    p2blY = peakData.P2Bl(index, f, 5);

    normCurrent = p2blCurrent ./ blCurrent;
    delta2 = 20 ./ (peakData.blRight(index, f, 1) - abs(pkX + 1i * pkY));
    delta3 = 20 ./ peakData.blRight(index, f, 1) - 20 ./ abs(pkX + 1i * pkY);
    delta4 = abs(20 ./ peakData.P2Bl(index, f, 1));
    delta5 = abs(20 ./ (blX + 1i * blY)) - abs(20 ./ (pkX + 1i * pkY));
    delta6 = abs(blX + 1i * blY) - abs(pkX + 1i * pkY);
    delta7 = abs((blX + 1i * blY)./(pkX + 1i * pkY));
    
    % impedance p2bl/bl
    delta8 = (abs(blX + 1i * blY) - abs(pkX + 1i * pkY)) ./ abs(blX + 1i * blY);
    
    % signal p2bl/bl
    delta9 = p2blCurrent ./ blCurrent;
    %sqrt(peakData.P2Bl(index, f, 4).^2 + peakData.P2Bl(index, f, 5).^2); % same as p2bl from data analysis

    ts = peakData.timestamp(index);
    if (mod(c, 4) == 0)
        marker = 'o';
    elseif (mod(c, 4) == 1)
        marker = 's';
    elseif (mod(c, 4) == 2)
        marker = '^';
    elseif (mod(c, 4) == 3)
        marker = 'v';
    end
    marker='.';
    figure(6);
    subplot(1, 2, 1);
    plot(ts./3600, smooth(normCurrent,10), marker, 'Color', cols(c,:));
    hold on;
    subplot(1, 2, 2);
    plot(ts./3600, smooth(delta7,10), marker, 'Color', cols(c,:));
    hold on;
    el{d}=num2str(c);

    % plotting real vs imag of bl and peak (only for first chamber as this
    % takes quite a while
    if (d == 1)
        figure(12);
        n = size(blX,1);
        manyCols = jet(n);
        for j = 1:n
            plot(blX(j), blY(j), 'o', 'Color', manyCols(j,:));
            hold on;
            plot(pkX(j), pkY(j), 'x', 'Color', manyCols(j,:));
        end
        hold off;
    end
end;

figure(11);
ax1=subplot(1, 2, 1);
hold off;
xlabel('Time[h]');
ylabel('current norm. P2Bl');
% ylim([0.08, 0.24]);

ax2=subplot(1, 2, 2);
hold off;
xlabel('Time [h]');
ylabel('delta');
% ylim([-2.5e-5, 2.5e-5]);

% legend(el, 'Location', 'NorthWest');
linkaxes([ax1, ax2], 'x');

figure(12);
axis equal tight;
