close all
clear
clc

graphics_toolkit qt;

function values = get_psy_data(sim_data_file, id, processing, masker)
  [status, text] = unix(['grep -e "run-' id '-Mmatrix,' processing '-default,' masker ',80,b" ' sim_data_file]);
  %disp(text);
  text_split = strsplit(text);
  if numel(text_split) >= 16
    values = cellfun(@str2double,text_split(2:end));
  else
    values = [];
    printf('missing simulation data %s %s %s %d\n',id,processing,masker,80);
  end
end

sim_data_file = 'psyfun-data.txt';

maskers = {'olnoise' 'icra5'};
maskers_strings = {'OLNOISE' 'ICRA5-250'};

profile = 'P-4000-7';
%profile = 'P-2000-14';
%profile = 'P-1000-21';

processings = {'none' 'platt2' 'platt4' 'platt6' 'platt8'};
thresholds = 0.2:0.05:0.9;
num_processings = numel(processings);
num_thresholds = numel(thresholds);

figure('Position', [0 0 450 200]);
%subplot = @(m,n,p) axes('Position',subposition(m,n,p))
for im = 1:numel(maskers)
  masker = maskers{im}
  VALUES = nan(num_processings,num_thresholds);
  legend_string = cell(num_processings,1);
  colors = lines(num_processings-1);
  for jp=1:num_processings
    values_tmp = get_psy_data(sim_data_file, profile , processings{jp}, masker);
    values_tmp(values_tmp(1:end-1)>values_tmp(2:end)) = nan;
    if ~isempty(values_tmp)
      VALUES(jp,:) = values_tmp(1:num_thresholds);
    end
    legend_string{jp} = [processings{jp}];
  end

  subplot(1,numel(maskers),im);
  h = zeros(num_processings,1);
  h(1) = plot(VALUES(1,:),thresholds,'-k','linewidth',1);
  hold on;
  plot([-20 20],[1 1]*0.5,':k');
  plot([-20 20],[1 1]*0.8,'--k');
  for jp=2:num_processings
    h(jp) = plot(VALUES(jp,:),thresholds,'color',colors(jp-1,:),'linewidth',1);
  end
  title([profile ' ' maskers_strings{im}]);
  xticks(-90:5:90);
  yticks(0:0.1:1);
  yticklabels(0:10:100);
  ylabel('Word recognition rate / % correct');
  xlabel('SNR / dB');
  xlim([-20 20])
  ylim([0 1]);
  grid on;
  box on;
  if im == 1
    l = legend(h,legend_string,'location','southeast');
    set(l,'position',get(l, 'position')+[0.0 0.03 0.0 0.0])
  end
end
set(gcf,'PaperUnits','inches','PaperPosition',[0 0 4.5 2].*1.4);
print('-depsc2','psyfun.eps');
