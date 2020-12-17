function [f, ht, ul] = load_hearingprofile(id);
  f = [125 250 500 750 1000 1500 2000 3000 4000 6000 8000 12000]; % Hz
  if strncmpi(id, 'bisgaard', 8)
    profile = strsplit(id, '-');
    hl_profile = str2num(profile{2});
    ul_profile = str2num(profile{3});
    [f, hl] = load_bisgaard(hl_profile);
    ul = ul_profile.*ones(size(f));
    ht = ff2ed(f,hl2spl(f,hl));
    ht = [ht; ht];
    ul = [ul; ul];
  else
    switch id
      case 'normal'
        ht = ff2ed(f,hl2spl(f,zeros(size(f))));
        ht = [ht; ht];
        ul = ones(size(f));
        ul = [ul; ul];
      otherwise
      % Implement loading parameters from "ema-data", i.e. from the individual measurements
      error('not implemented');
    end
  end
end
