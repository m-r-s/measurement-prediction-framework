function [presentations, answers] = presentationresponse(presentationhandle, answerhandle, sampleorder)

% Initial values
count = 0;

presentations = [];
answers = [];

% Measure loop
for i=1:numel(sampleorder)
  count = count + 1;

  % Present stimulus
  presentation = sampleorder(i);
  presentationhandle(presentation);
  presentations(count) = presentation;
  
  % Get answer
  answer = answerhandle(count);
  answers(count) = answer;
end
end

