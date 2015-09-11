% example how to plot normalized delta I and baseline of every second
% chamber

% find all indices
uIs = unique(peakData.chamberIndex);
le = {};

% make colors for plotting chambers
cols = jet(numel(uIs));
freq = 3;

% iterate every second chamber
for (i = 1:2:numel(uIs))
    uI = uIs(i);
    
    % skip chamber index zero as this is only the tiny set of data between
    % two chambers
    if (uI == 0)
        continue;
    end
    le{end+1}=['Chamber ', num2str(uI)];
    is = find(peakData.chamberIndex == uI);

    figure(1);
    subplot(1, 2, 1);
    plot(peakData.startTimestampChamberS(is)./3600, smooth(peakData.P2Bl(1, is, freq)./peakData.baseline(1, is, freq),50), '.', 'Color', cols(i,:));
    hold on;
    
    subplot(1, 2, 2);
    plot(peakData.startTimestampChamberS(is)./3600, smooth(peakData.baseline(1, is, freq),10), '.', 'Color', cols(i,:));
    hold on;
    
    figure(2);
    plot(peakData.startTimestampChamberS(is)./3600, smooth(peakData.baseline(1, is, freq) ./ peakData.baseline(1, is(1), freq),10), '.', 'Color', cols(i,:));
    hold on;
end
figure(1);
subplot(1, 2, 1);
hold off;
xlabel('Time [h]');
ylabel('\Delta{}I_{norm}');
legend(le, 'Location', 'SouthWest');

subplot(1, 2, 2);
hold off;
xlabel('Time [h]');
ylabel('Baseline [mV]');

figure(2);
hold off;
xlabel('Time [h]');
ylabel('Baseline_{norm. initial value}');
