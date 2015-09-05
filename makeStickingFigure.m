% making figure showing the dependence of the number of moving tissues in a
% chip on the tilt time interval
figure(1);
movingTissues = [15,14,15,15,15,14,8,6,6,5,3]./15 * 100
tiltIntervalMin = [0.3,2.6,6.2,10.4,15,21,29,42,62,99,171];
semilogx(tiltIntervalMin, movingTissues, 'o-');
ylim([-5 105]);
xlim([0.2 250]);
xlabel('Tilt interval [min]');
ylabel('Moving spheroids [%]');
