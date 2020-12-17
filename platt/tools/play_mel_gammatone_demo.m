close all
clear
clc


% Impulse
fs = 48000;
impulse = [0; 0; 0; 0; 1; zeros(fs,1)];
signal_in = impulse;

signal_in = sin(2*pi*1038.8*linspace(0,fs-1,fs)./fs).';



[signal_filtered, centers, filters, bandwidths] = mel_gammatone_iir(signal_in, fs);

figure('Position',[0 0 800 300]);
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 3].*1.4);
subplot = @(m,n,p) axes('Position',subposition(m,n,p));
showfilters = 1:8:length(filters);
t = ((1:1500)-1)/fs.*1000;
for i=1:length(showfilters)
  plot(t([1 end]),[1 1].*(0.08.*i),'k');
  hold on;
  plot(t,(0.08.*i)+real(signal_filtered(1:1500,showfilters(i))),'k');
end
plot(t,0.08.*(length(showfilters)+3)+real(sum(signal_filtered(1:1500,:),2))./4,'k');
xlabel('time / ms');
ylabel('Center frequencies and amplitude');
set(gca,'ytick',0.08.*(1:length(showfilters)));
set(gca,'xtick',0:1:20);
set(gca,'yticklabel',num2str(centers(showfilters).','%.0f'));
xlim([0 20]);
ylim([0 0.08.*(length(showfilters)+6)]);

print('-depsc2','-r300','gammatone_filter_responses.eps');

figure('Position',[0 0 300 150]);
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 3 1.5].*1.4);
f = linspace(0,fs-1,size(signal_filtered,1));
for i=1:length(showfilters)
  plot(log(f),20*log10(abs(fft(signal_filtered(:,showfilters(i))))),'k');
  hold on;
end
plot(log(f),20*log10(abs(fft(sum(signal_filtered,2)))),'k');

set(gca,'xtick',log([125 250 500 1000 2000 4000 8000 16000]));
set(gca,'xtickLabel',[125 250 500 1000 2000 4000 8000 16000]);

set(gca,'ytick',-60:10:10);

xlim(log([64 16000]));
ylim([-60 20])

xlabel('Frequency / Hz');
ylabel('Attenuation / dB');

print('-depsc2','-r300','gammatone_filter_transfer.eps');
