uIs = unique(peakDataExt.chamberIndex);
le = {};
cols = jet(numel(uIs));
for (i = 2:2:numel(uIs))
    uI = uIs(i);
    if (uI == 0)
        continue;
    end
    le{end+1}=['chamber ', num2str(uI)];
    is = find(peakDataExt.chamberIndex == uI);

    figure(1);
    subplot(1, 2, 1);
    plot(peakDataExt.timestamp(is)./3600, smooth(peakDataExt.P2Bl(is, 5, 1)./peakDataExt.blRight(is, 5, 1),50), '.', 'Color', cols(i,:));
    hold on;
    
    subplot(1, 2, 2);
    plot(peakDataExt.timestamp(is)./3600, smooth(peakDataExt.blRight(is, 5, 1),10), '.', 'Color', cols(i,:));
    hold on;
    
    figure(2);
    plot(peakDataExt.timestamp(is)./3600, smooth(peakDataExt.blRight(is, 5, 1) ./ peakDataExt.blRight(is(1), 5, 1),10), '.', 'Color', cols(i,:));
    hold on;
end
figure(1);
subplot(1, 2, 1);
hold off;
xlabel('Time [h]');
ylabel('\Delta{}I_{norm} [mV]');
legend(le, 'Location', 'SouthWest');

subplot(1, 2, 2);
hold off;
xlabel('Time [h]');
ylabel('Bl [mV]');

figure(2);
hold off;
xlabel('Time [h]');
ylabel('Bl_{norm. initial value} [mV]');
