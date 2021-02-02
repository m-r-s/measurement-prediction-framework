close all
clear
clc

graphics_toolkit qt;

function thresholds = get_sim_data(sim_data_file, id, processing, masker, levels)
  thresholds = nan(numel(levels),1);
  for i = 1:numel(levels)
    [status, text] = unix(['grep -e "run-' id '-Mmatrix,' processing '-default,' masker ',' sprintf('%d',levels(i)) ',b" ' sim_data_file]);
    %disp(text);
    text_split = strsplit(text);
    if numel(text_split) >= 3 && ~isempty(text_split{3}) && ischar(text_split{3})
      thresholds(i) = str2double(text_split{3}) + levels(i);
    else
      printf('missing simulation data %s %s %s %d\n',id,processing,masker,levels(i));
    end
  end 
end

sim_data_file = 'results.txt';

levels = 0:10:100;
plotrange = [5 95];
maskers = {'olnoise' 'icra5'};
maskers_strings = {'OLNOISE' 'ICRA5-250'};

%% frequency range
%profiles = {'P-8000-1' 'none';
%            'P-4000-1' 'none';
%            'P-2000-1' 'none';
%            'P-1000-1' 'none';
%            };

%% level uncertainty
%profiles = {'P-8000-1' 'none';
%            'P-8000-7' 'none';
%            'P-8000-14' 'none';
%            'P-8000-21' 'none';
%            };

%% level uncertainty with frequency range limited to 1000 Hz
%profiles = {'P-1000-1' 'none';
%            'P-1000-7' 'none';
%            'P-1000-14' 'none';
%            'P-1000-21' 'none';
%            };

%% limited frequency range with increased level uncertainty
%profiles = {'P-8000-1' 'none';
%            'P-4000-7' 'none';
%            'P-2000-14' 'none';
%            'P-1000-21' 'none';
%            };

%% limited frequency range with increased level uncertainty
%profiles = {'P-4000-7' 'none';
%            'P-4000-7' 'platt2';
%            'P-4000-7' 'platt4';
%            'P-4000-7' 'platt6';
%            'P-8000-1' 'none';
%            }

%% limited frequency range with increased level uncertainty
%profiles = {'P-2000-14' 'none';
%            'P-2000-14' 'platt2';
%            'P-2000-14' 'platt4';
%            'P-2000-14' 'platt6';
%            'P-8000-1' 'none';
%            }

% limited frequency range with increased level uncertainty
profiles = {'P-1000-21' 'none';
            'P-1000-21' 'platt2';
            'P-1000-21' 'platt4';
            'P-1000-21' 'platt6';
            'P-8000-1' 'none';
            };

figure('Position', [0 0 800 200]);
subplot = @(m,n,p) axes('Position',subposition(m,n,p))
for im = 1:numel(maskers)
  masker = maskers{im};
  num_profiles = size(profiles,1);
  SRTs = cell(num_profiles,1);
  legend_string = cell(num_profiles,1);
  colors = lines(num_profiles-1);
  for ip=1:num_profiles
    SRTs{ip} = get_sim_data(sim_data_file, profiles{ip,1} , profiles{ip,2}, masker, levels);
    legend_string{ip} = [profiles{ip,1} ' ' profiles{ip,2}];
  end

  subplot(1,2*numel(maskers),(im).*2-1);
  h = zeros(size(profiles,1),1);
  plot(plotrange,plotrange,'-k');
  h(1) = plot(levels,SRTs{1},'-k','linewidth',1);
  hold on;
  for offset = 0;
    plot(plotrange,plotrange+offset,':k');
  end 
  axis image; xlim(plotrange); ylim(plotrange);
  xticks(plotrange(1):10:plotrange(2))
  yticks(plotrange(1):10:plotrange(2))
  for ip=2:num_profiles
    h(ip) = plot(levels,SRTs{ip},'-','color',colors(ip-1,:),'linewidth',1);
  end
  grid on;
  title([maskers_strings{im} ' SRT']);
  xlabel('Noise level / dB SPL');
  ylabel('Speech level / dB SPL');

  subplot(1,2*numel(maskers),(im).*2);
  h = zeros(size(profiles,1),1);
  h(1) = plot(plotrange,[0 0],'-k','linewidth',1);
  set(gca,'DataAspectRatio',[90/30 1 1])
  hold on;
  xlim(plotrange);
  ylim([0 30]);
  xticks(plotrange(1):10:plotrange(2));
  yticks(-30:2:30);
  for ip=2:num_profiles
    h(ip) = plot(levels,SRTs{1}-SRTs{ip},'-','color',colors(ip-1,:),'linewidth',1);
  end
  grid on;
  title([maskers_strings{im} ' differences in SRT']);
  xlabel('Noise level / dB SPL');
  ylabel('Speech level difference / dB');
  if im == 1
    l = legend(h,legend_string,'Location','northeast');
    set(l,'position',get(l, 'position')+[0.006 -0.00 0.0 0.0])
  end
end
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 8 2].*1.4);
print('-depsc2','plomplike.eps');

