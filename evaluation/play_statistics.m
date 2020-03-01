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

% Number of samples for Monte-Carlo simulations
num_samples = 10000;

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

function [r2, b, e_rms, e_95, eb_rms]  = statistics(x,y)
  x = x(:);
  y = y(:);
  % Correlation coefficient
  xm = x - mean(x);
  ym = y - mean(y);
  r = sum(xm.*ym)./(sqrt(sum(xm.*xm)).*sqrt(sum(ym.*ym)));
  r2 = r.^2.*100;
  % Bias
  b = mean(y-x);
  % RMS error
  e_rms = sqrt(mean((x-y).^2));
  % Error percentiles
  e_prctile = prctile(abs(x-y),[50 95 100]);
  e_95 = e_prctile(2);
  %
  eb_rms = sqrt(mean((x-y+b).^2));
end


for l=1:2
  for k=1:length(individualizations)
    switch l
      case {1}
      x = data_emp;
      y = data_sim(:,:,:,k);
      measure = 'SRT';
      probe_errors = 2;
      case {2}
      x = ben_emp;
      y = ben_sim(:,:,:,k);
      measure = 'Benefit';
      probe_errors = sqrt(2).*2;
    end
    [r, b, e_rms, e_95]  = statistics(x,y);

    stats = nan(num_samples,length(probe_errors),4);
    for i=1:num_samples
      noise = randn(size(x));
      for j=1:length(probe_errors)
        x_model = x + probe_errors(j).*noise;
        y_model = y;
        [stats(i,j,1), stats(i,j,2), stats(i,j,3), stats(i,j,4)] = ...
          statistics(x_model, y_model);
      end
    end

    statsg = nan(num_samples,4);
    for i=1:num_samples
      selection = round(0.5+rand(size(x,1),1).*size(x,1));
      x_model = x(selection,:,:);
      y_model = y(selection,:,:,:);
      [statsg(i,1), statsg(i,2), statsg(i,3), statsg(i,4)] = ...
        statistics(x_model, y_model);
    end
    
    names = {'R$^2$', 'Bias', 'RMS PE', '95P PE'};
    units = {'\%', 'dB', 'dB', 'dB'}; 
    values = [r, b, e_rms, e_95];

    printf('%s:\n',measure);
    printf('Quantitiy &  Indiv. &  Value  & TRR = 2\\,dB  &  Bootstrap \\\\\n');
    for i=1:length(values)
      printf('%s & %s & ', names{i}, individualizations{k});
      pct = prctile(stats(:,:,i),[5 50 95]);
      pctg = prctile(statsg(:,i),[5 95]);
      confidence = [pct(1,:)-pct(2,:); pct(3,:)-pct(2,:)];
      confidenceg = pctg - values(i);
      printf('%.2f\\,%s & [%.2f,%.2f]\\,%s & [%.2f,%.2f]\\,%s \\\\',values(i),units{i},confidence,units{i},confidenceg,units{i});
      printf('\n');
    end
  end
end
