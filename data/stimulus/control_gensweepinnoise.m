function varargout = control_gensweepinnoise(varargin)

nul = {''};
frequencies = {'500' '1000' '2000' '4000' };
explanation = {nul, frequencies};

title = 'Sweep detection in narrowband noise';
target = 0.875;
dim = 2;
xfactor = 1;
yfactor = 1;
xlabel = 'Sweep center frequency [Hz]';
ylabel = 'Threshold [dB SPL]';
xlog = true;
xmarks = [];
ymarks = [0];

% Empicial results
level = zeros(size(frequencies));

% Empirical standard deviation
deviation = ones(size(frequencies));

varargout = cell(size(varargin));
for i=1:length(varargin)
  switch varargin{i}
    case 'level'
      varargout{i} = level;
    case 'deviation'
      varargout{i} = deviation;
    case 'target'
      varargout{i} = target;
    case 'xlabel'
      varargout{i} = xlabel;
    case 'ylabel'
      varargout{i} = ylabel;
    case 'xfactor'
      varargout{i} = xfactor;
    case 'yfactor'
      varargout{i} = yfactor;
    case 'explanation'
      varargout{i} = explanation;
    case 'dim'
      varargout{i} = dim;
    case 'xlog'
      varargout{i} = xlog;
    case 'title'
      varargout{i} = title;
    case 'xmarks'
      varargout{i} = xmarks;
    case 'ymarks'
      varargout{i} = ymarks;
  end
end

