#!/usr/bin/octave-cli
close all
clear
clc
warning off;
graphics_toolkit qt

subjects = { ... 
  'listener01-l' ...  1
  'listener02-r' ...  0
  'listener03-l' ...  1
  'listener05-l' ...  0
  'listener06-r' ...  1
  'listener07-l' ...  1
  'listener08-l' ...  0
  'listener09-l' ...  1
  'listener10-l' ...  1
  'listener12-l' ...  0
  'listener14-r' ...  0
  'listener15-r' ...  0
  'listener16-l' ...  1
  'listener17-r' ...  1
  'listener18-r' ...  1
  'listener19-r' ...  1
  'listener20-l' ...  1
  'listener21-l' ...  0
  };

% Can be used to selectively plot data
%plot_mask = [ 1 0 1 0 1 1 0 1 1 0 0 0 1 1 1 1 1 0];
plot_mask = [ 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
  
%% GET EMPIRICAL DATA
printf('Load empirical data\n');
emp_data_dir = 'data';
maskers = {'quiet' 'icra1' 'icra5-250'};
conditions = {'none' 'linear' 'compressive' 'full'};
individualizations = {'AD' 'AG' 'A'};

num_subjects = length(subjects);
num_maskers = length(maskers);
num_conditions = length(conditions);
num_individualizations = length(individualizations);

addpath('features/hzappp-full');
PTA = zeros(size(subjects));
[f, htn] = load_hearingstatus('normal','A');
for j=1:length(subjects)
  [f, ht] = load_hearingstatus(subjects{j},'A');
  PTA(j) = mean(interp1(f,ht-htn,[500 1000 2000 4000]));
end

function threshold = get_emp_data(emp_data_dir, subject, masker, condition)
  threshold = nan;
  datafile = dir([emp_data_dir filesep subject filesep 'matrix-' masker ',' condition '-block*.m']);
  if ~isempty(datafile) && numel(datafile) == 1
    datafile = [emp_data_dir filesep subject filesep datafile.name];
    if exist(datafile,'file')
      run(datafile);
    end
  else
    printf('missing empirical data %s %s %s\n',subject,masker,condition);
  end
end

traindata_emp = nan(num_subjects,3);
for ii = 1:num_subjects
  traindata_emp(ii,1) = get_emp_data(emp_data_dir, subjects{ii}, 'tsn', 'none,train1');
  traindata_emp(ii,2) = get_emp_data(emp_data_dir, subjects{ii}, 'tsn', 'none,train2');
  traindata_emp(ii,3) = get_emp_data(emp_data_dir, subjects{ii}, 'tsn', 'compressive,train1');
end

data_emp = nan(num_subjects,num_maskers,num_conditions);
for ii = 1:num_subjects
  for jj = 1:num_maskers
    for kk = 1:num_conditions
      data_emp(ii,jj,kk) = get_emp_data(emp_data_dir, subjects{ii}, maskers{jj}, conditions{kk});
    end
  end
end


%% GET SIMULATED DATA
printf('Load simulated data\n');
sim_data_file = 'matrix_simulated_data.txt';
% Naming scheme is sightly different for simulations
% icra5-250 -> icra5.250
% none -> unaided
maskers = {'quiet' 'icra1' 'icra5.250'};
conditions = {'unaided' 'linear' 'compressive' 'full'};

function threshold = get_sim_data(sim_data_file, subject, masker, condition, individualization)
  threshold = nan;
  grepcommand = ['grep -e "run-' subject '-Mmatrix,' condition '[^-]*-default,' masker '[^-]*-F[^-]*-I' individualization ' " ' sim_data_file];
  [status, text] = unix(grepcommand);
  text_split = strsplit(text);
  if numel(text_split) >= 3 && ~isempty(text_split{3}) && ischar(text_split{3})
    threshold = str2double(text_split{3});
  else
    printf('missing simulation data %s %s %s %s\n',subject,masker,condition,individualization);
  end
end

data_sim = nan(num_subjects,num_maskers,num_conditions,num_individualizations);
for ii = 1:num_subjects
  for jj = 1:num_maskers
    for kk = 1:num_conditions
      for ll = 1:num_individualizations
         data_sim(ii,jj,kk,ll) = get_sim_data(sim_data_file, subjects{ii}, maskers{jj}, conditions{kk}, individualizations{ll});
      end
    end
  end
end

% Calculate benefits
ben_emp = data_emp(:,:,1) - data_emp(:,:,2:end);
ben_sim = data_sim(:,:,1,:) - data_sim(:,:,2:end,:);

% Set colorcode
colors = jet(length(subjects)).*0.8;
[~, sidx] = sort(data_emp(:,1,1));
colors(sidx,:) = colors;

mkdir('figures');

figsize = [4 2];
figure('Position',100.*[0 0 figsize]);
set(gcf,'PaperUnits','inches','PaperPosition',1.4.*[0 0 figsize]);
plot([40 90],[40 90],'k');
hold on; 
for i=1:num_maskers-1
  switch tolower(maskers{i+1})
    case 'quiet'
      masker_symbol = 'o';
    case 'icra1'
      masker_symbol = 's';
    case 'icra5-250'
      masker_symbol = '^';
  end
  for k=1:num_subjects
    x = squeeze(data_emp(k,1,1))+65;
    y = squeeze(data_emp(k,i+1,1))+65;
    if ~isnan(x) & ~isnan(y)
      scatter(x,y,20,colors(k,:),masker_symbol,'filled');
    end
  end
end
xticks(10:10:90);
yticks(40:5:90);
grid on;
axis image;
xlim([10 90]);
ylim([40 90]);
xlabel('SRT in quiet / dB SPL');
ylabel('SRT in noise / dB SPL');
print(sprintf('figures/quiet_vs_noise.eps',conditions{i}), '-depsc2','-r96');

figsize = [2 2];
for i=1:num_conditions-1
  figure('Position',100.*[0 0 figsize]);
  set(gcf,'PaperUnits','inches','PaperPosition',1.4.*[0 0 figsize]);
  plot([-5 75],[0 0],'k');
  hold on; 
  for j=1:num_maskers
    switch tolower(maskers{j})
      case 'quiet'
        masker_symbol = 'o';
      case 'icra1'
        masker_symbol = 's';
      case 'icra5-250'
        masker_symbol = '^';
    end
    for k=1:num_subjects
      x = PTA(k);
      y = squeeze(ben_emp(k,j,i));
      if ~isnan(x) & ~isnan(y)
        scatter(x,y,20,colors(k,:),masker_symbol);
      end
    end
    xticks(0:10:70);
    yticks(-25:5:35);
    grid on;
    xlim([-5 75]);
    ylim([-25 35]);
    xlabel('PTA / dB HL');
    ylabel('Benefit in SRT / dB SNR');
    print(sprintf('figures/%s_PTA-vs-aided.eps',conditions{i+1}), '-depsc2','-r96');
  end
end

%% Plot all results together
figsize = [2 2];
axis_range = [0 90];
condition_marker = [1 0 0 0];
for ii=1:num_individualizations
  h = [];
  figure('Position',100.*[0 0 figsize]);
  set(gcf,'PaperUnits','inches','PaperPosition',1.4.*[0 0 figsize]);
  plot(axis_range,axis_range,'--k');
  set(gca,'XTick',axis_range(1):10:axis_range(2));
  set(gca,'YTick',axis_range(1):10:axis_range(2));
  grid on;
  hold on;
  axis('equal');
  xlim(axis_range);
  ylim(axis_range);
  for jj=1:num_maskers
    switch tolower(maskers{jj})
      case 'quiet'
        masker_symbol = 'o';
      case 'icra1'
        masker_symbol = 's';
      case 'icra5-250'
        masker_symbol = '^';
    end
    for kk=1:num_subjects
      for ll=1:num_conditions
        x = squeeze(data_emp(kk,jj,ll)) + 65;
        y = squeeze(data_sim(kk,jj,ll,ii)) + 65;
        if ~isnan(x) & ~isnan(y)
          if condition_marker(ll) == 1
            scatter(x,y,20,colors(kk,:),masker_symbol,'filled');
          else
            scatter(x,y,20,colors(kk,:),masker_symbol);
          end
        end
      end
    end
  end
  xlabel('Empirical SRT / dB SPL');
  ylabel('FADE SRT / dB SPL');
  title(['SRTs predicted with individualization "' individualizations{ii} '"']);
  drawnow;
  print(sprintf('figures/overview-%s.eps',individualizations{ii}), '-depsc2','-r96');
end

%% Plot all benefits together
figsize = [2 2];
axis_range = [-25 40];
for ii=1:num_individualizations
  h = [];
  figure('Position',100.*[0 0 figsize]);
  set(gcf,'PaperUnits','inches','PaperPosition',1.4.*[0 0 figsize]);
  plot(axis_range,axis_range,'--k');
  set(gca,'XTick',axis_range(1):5:axis_range(2));
  set(gca,'YTick',axis_range(1):5:axis_range(2));
  grid on;
  hold on;
  axis('equal');
  xlim(axis_range);
  ylim(axis_range);
  for jj=1:num_maskers
    switch tolower(maskers{jj})
      case 'quiet'
        masker_symbol = 'o';
      case 'icra1'
        masker_symbol = 's';
      case 'icra5-250'
        masker_symbol = '^';
    end
    for kk=1:num_subjects
      if plot_mask(kk) == 1
        for ll=1:num_conditions-1
          x = squeeze(ben_emp(kk,jj,ll));
          y = squeeze(ben_sim(kk,jj,ll,ii));
          if ~isnan(x) & ~isnan(y)
            scatter(x,y,20,colors(kk,:),masker_symbol);
          end
        end
      end
    end
  end
  xlabel('Empirical benefit in SRT / dB SPL');
  ylabel('FADE benefit in  SRT / dB SPL');
  title(['Beneftis in SRT predicted with individualization "' individualizations{ii} '"']);
  drawnow;
  print(sprintf('figures/benefit-overview-%s.eps',individualizations{ii}), '-depsc2','-r96');
end


