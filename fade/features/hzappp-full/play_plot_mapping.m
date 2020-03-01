#!/usr/bin/octave -q
close all
clear
clc
graphics_toolkit qt

[ul_data freq_data threshold_data] = textread(fullfile(fileparts(mfilename),'ul2tintable.txt'),'%f %f %f\n');
uls = sort(unique(ul_data));
freqs = sort(unique(freq_data)).';

f = [500 1000 2000 4000];
t = -5:1:25;
ul = 0:1:30;
colors = hsv(length(f));

figure('Position',[0 0 600 300]);
subplot(1,2,1);
plot([-6 30],[-6 30],'k');
hold on;

h = nan(size(f));
for i=1:length(ul_data)
  scatter(ul_data(i),threshold_data(i), 20, colors(freq_data(i) == f,:)*0.8, 'o');
end

for i=1:length(f)
  h(i) = plot(ul,ul2tin(f(i).*ones(size(ul)),ul),'-','color',colors(i,:).*0.65);
##  if any(f(i)==[500 1000 2000 4000]);
##    set(h(i),'LineWidth',2);
##  end
end
xlabel('Level uncertainty / dB');
ylabel('Thresholds / dB');
axis image;
legend(h,num2str(f.'),'location','NorthWest');
xlim([-6 30]);
ylim([-6 30]);
grid on;
xticks(-6:3:30);
yticks(-6:3:30);


subplot(1,2,2);
plot([-6 30],[-6 30],'k');
hold on;
for i=1:length(f)
  h(i) = plot(t,tin2ul(f(i).*ones(size(t)),t),'color',colors(i,:).*0.65);
##  if any(f(i)==[500 1000 2000 4000]);
##    set(h(i),'LineWidth',2);
##  end
end
ylabel('Level uncertainty / dB');
xlabel('Thresholds / dB');
axis image;
xlim([-6 30]);
ylim([-6 30]);
grid on;
xticks(-6:3:30);
yticks(-6:3:30);

print('-depsc2','tin_mapping.eps');
