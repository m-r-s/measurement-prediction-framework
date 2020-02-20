function [threshold, values, reversals, measures, presentations, answers, adjustments, offsets] =...
  matrixadapt(presentationhandle, answerhandle, target, discardreversals, startvalue, steps, explanationidx, selfservice)

% Example config  
%  target = 0.5;
%  discardreversals = 2;
%  startvalue = 10;
%  steps = [4 2 1];
%  explanationidx = {};
%  selfservice = false;

% Initial values
value = startvalue;
lastvalue = [];
direction = [];
count = 0;


threshold = [];
values = [];
reversals = [];
measures = [];
presentations = [];
answers = [];
adjustments = [];
offsets = [];

% Naively construct adaptation steps
adjustment_matrix = [0 1 2 3 4 5] - (target.*5);
adjustment_matrix = -adjustment_matrix;

assert(discardreversals>=0);

% Measure loop
for il=1:20
  count = count + 1;

  % Present stimulus
  presentation = il;
  offset = presentationhandle(presentation, value);
  presentations(count) = presentation;
  values(count) = value;
  offsets(count) = offset;

  if selfservice
    input(sprintf('%3i| press enter to show results... ', count));
  end

  % Get answer
  answer = answerhandle(count, explanationidx{presentation}, value);
  answers(count) = answer;
  
  % Determine adjustment
  adjustment = adjustment_matrix(1+answer) .* steps(min(1+sum(abs(reversals)),end));
  adjustments(count) = adjustment;
  
  % Apply adjustment
  lastvalue = value;
  value = value + adjustment;
  
  % Detect reversals
  if isempty(direction) && adjustment ~= 0
    direction = adjustment;
  elseif (adjustment>0 && direction<0) || (adjustment<0 && direction>0)
    direction = adjustment;
    reversals(count) = sign(direction);
  else
    reversals(count) = 0;
  end
  
  % Mark measures
  if sum(abs(reversals)) > discardreversals
    measures(count) = 1;
  else
    measures(count) = 0;
  end
end

% Evaluate measurement
if sum(abs(reversals))>discardreversals
  reversalvalues = values(logical(abs(reversals)));
  usereversalvalues = reversalvalues(1+discardreversals:end);
  threshold = median(usereversalvalues);
end
end

