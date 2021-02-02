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

levels = [70 80 90];
maskers = {'olnoise' 'icra5'};
maskers_strings = {'OLNOISE' 'ICRA5-250'};


profiles = {'P-8000-1' 'P-8000-7' 'P-8000-14' 'P-8000-21';
            'P-4000-1' 'P-4000-7' 'P-4000-14' 'P-4000-21';
            'P-2000-1' 'P-2000-7' 'P-2000-14' 'P-2000-21';
            'P-1000-1' 'P-1000-7' 'P-1000-14' 'P-1000-21'}.';
processings = {'none' 'platt2' 'platt4' 'platt6' 'platt8'};

num_profiles = numel(profiles);
num_processings = numel(processings);

for im = 1:numel(maskers)
  masker = maskers{im}
  printf('\n');
  SRTs = zeros(num_profiles,num_processings);
  legend_string = cell(num_profiles,1);
  colors = lines(num_profiles-1);
  for ip=1:num_profiles
    for jp=1:num_processings
      SRTs(ip,jp) = mean(get_sim_data(sim_data_file, profiles{ip} , processings{jp}, masker, levels)-levels.');
    end
  end
  SRT_benefits = SRTs(:,1) - [SRTs(:,2:end) SRTs(1,1).*ones(num_profiles,1)];
  for ip=1:num_profiles
    printf('%s',profiles{ip});
    printf(' & %.1f',SRT_benefits(ip,:));
    printf('\\\\\n');
  end
  printf('\n');
end

