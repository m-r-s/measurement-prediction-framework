function plot_run(resultfile)
  assert(exist(resultfile,'file'));
  run(resultfile);

  figure('Visible','off'); close;
  graphics_toolkit('gnuplot');
  figh = figure('Position',[0 0 400 400],'Visible','off');
  set(gcf,'PaperUnits','inches','PaperPosition',[0 0 4 4].*1.4);
  
  x = 1:length(values);
  plot(x,values,'-k');
  xlabel('Presentation number');
  ylabel('Value');
  hold on;

  if ~isempty(threshold) && ~isnan(threshold)
    plot(x([1 end]),[1 1].*threshold,'Color',[0 1 0].*0.8,'LineWidth',2);
  end

  xi = measures==0 & reversals==0;
  if ~isempty(xi)
    plot(x(xi),values(xi),'o','Color',[1 1 1].*0.5);
  end
  xi = measures==1 & reversals==0;
  if ~isempty(xi)
    plot(x(xi),values(xi),'o','Color',[1 0 0].*0.8);
  end

  xi = measures==0 & reversals>0;
  if ~isempty(xi)
    plot(x(xi),values(xi),'^','Color',[1 1 1].*0.65,'MarkerSize',10);
  end
  xi = measures==1 & reversals>0;
  if ~isempty(xi)
    plot(x(xi),values(xi),'^','Color',[0 1 1].*0.65,'MarkerSize',10);
  end
  
  xi = measures==0 & reversals<0;
  if ~isempty(xi)
    plot(x(xi),values(xi),'v','Color',[1 1 1].*0.65,'MarkerSize',10);
  end
  xi = measures==1 & reversals<0;
  if ~isempty(xi)
    plot(x(xi),values(xi),'v','Color',[0 1 1].*0.65,'MarkerSize',10);
  end
  
  axis tight;
  title(resultfile(regexp(resultfile,'[^/]+$'):end-2));
  [~, imagefile] = system('mktemp',1);
  print('-depsc2', '-r300', imagefile);
  close(figh);
  system(['evince ', imagefile, ' 1>/dev/null 2>/dev/null; rm ', imagefile ' 1>/dev/null 2>/dev/null'], 0, 'async');
end
