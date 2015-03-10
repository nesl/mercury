function [Dist,D,k,w,rw,tw]=dtw_for_paper(r,t,pflag)
%
% [Dist,D,k,w,rw,tw]=dtw(r,t,pflag)
%
% Dynamic Time Warping Algorithm
% Dist is unnormalized distance between t and r
% D is the accumulated distance matrix
% k is the normalizing factor
% w is the optimal path
% t is the vector you are testing against
% r is the vector you are testing
% rw is the warped r vector
% tw is the warped t vector
% pflag  plot flag: 1 (yes), 0(no)
%
% Version comments:
% rw, tw and pflag added by Pau Mic�

[row,M]=size(r); if (row > M) M=row; r=r'; end;
[row,N]=size(t); if (row > N) N=row; t=t'; end;
d=(repmat(r',1,N)-repmat(t,M,1)).^2; %this makes clear the above instruction Thanks Pau Mic�

D=zeros(size(d));
D(1,1)=d(1,1);

for m=2:M
    D(m,1)=d(m,1)+D(m-1,1);
end
for n=2:N
    D(1,n)=d(1,n)+D(1,n-1);
end
for m=2:M
    for n=2:N
        D(m,n)=d(m,n)+min(D(m-1,n),min(D(m-1,n-1),D(m,n-1))); % this double MIn construction improves in 10-fold the Speed-up. Thanks Sven Mensing
    end
end

Dist=D(M,N);
n=N;
m=M;
k=1;
w=[M N];
while ((n+m)~=2)
    if (n-1)==0
        m=m-1;
    elseif (m-1)==0
        n=n-1;
    else 
      [values,number]=min([D(m-1,n),D(m,n-1),D(m-1,n-1)]);
      switch number
      case 1
        m=m-1;
      case 2
        n=n-1;
      case 3
        m=m-1;
        n=n-1;
      end
  end
    k=k+1;
    w=[m n; w]; % this replace the above sentence. Thanks Pau Mic�
end

% warped waves
rw=r(w(:,1));
tw=t(w(:,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if pflag
    
    % --- Accumulated distance matrix and optimal path
    %figure('Name','DTW - Accumulated distance matrix and optimal path', 'NumberTitle','off');
    
    % ------------- main -------------------------------------------------
    
    main1=subplot('position',[0.19 0.23 0.67 0.75]);
    D = log10(D+1);
    D = 110 - D / max(max(D)) * 60 * 1.5;
    D = flipud(D);
    image(D);
    %caxis( [min(min(D)) max(max(D))] )
    colormap('hot')
    
    %cmap = contrast(D);
    %cmap
    %colormap(cmap); % 'copper' 'bone', 'gray' imagesc(D);
    %colorbar
    hold on;
    x=[1; w(:,1); M ]; y=[1; w(:,2); N ];
    ind=find(x==1); x(ind)=1+1;
    ind=find(x==M); x(ind)=M-1;
    ind=find(y==1); y(ind)=1+1;
    ind=find(y==N); y(ind)=N-1;
    x = M - x;
    %plot(y,x,'-', 'Color', [0.5 0.5 0.5 ], 'LineWidth',4);
    plot(y,x,'-k', 'LineWidth',2);
    hold off;
    axis([1 N 1 M]);
    set(main1, 'FontSize',7, 'XTickLabel','', 'YTickLabel','');
%{
    colorb1=subplot('position',[0.88 0.19 0.05 0.79]);
    colorbar(colorb1);
    set(colorb1, 'FontSize',7, 'YTick',[], 'YTickLabel',[]);
    %set(get(colorb1,'YLabel'), 'String','Distance', 'Rotation',-90, 'FontSize',7, 'VerticalAlignment','bottom');
%}
    
    % ------------- left -------------------------------------------------
    
    left1=subplot('position',[0.07 0.23 0.10 0.75]);
    plot(fliplr(r),M:-1:1, 'b--','LineWidth',2);
    set(left1, 'XTick', 20:50:80, 'XTickLabel',[])
    set(left1, 'YTick', 0:100:1000, 'YTickLabel',[])
    axis([min(r) 1.1*max(r) 1 M]);
    %set(get(left1,'YLabel'), 'String','Samples', 'FontSize',7, 'Rotation',-90, 'VerticalAlignment','cap');
    %set(get(left1,'XLabel'), 'String','Amp', 'FontSize',6, 'VerticalAlignment','cap');
    ylabel('Map point index', 'FontSize', 12);
    grid on
    
    % ------------- bottom -----------------------------------------------
    
    bottom1=subplot('position',[0.19 0.11 0.67 0.10]);
    plot(t,'-', 'Color', 'r', 'LineWidth', 2);
    axis([1 N min(t) 1.1*max(t)]);
    set(bottom1, 'XTick', 0:100:500, 'XTickLabel',{})
    set(bottom1, 'YTick', 20:50:80, 'YTickLabel',{})
    %set(get(bottom1,'XLabel'), 'String','Samples', 'FontSize',7, 'VerticalAlignment','middle');
    %set(get(bottom1,'YLabel'), 'String','Amp', 'Rotation',-90, 'FontSize',6, 'VerticalAlignment','bottom');
    xlabel('Barometer sample index', 'FontSize', 12);
    grid on
    
    % --- Warped signals
    %{
    figure('Name','DTW - warped signals', 'NumberTitle','off');
    
    subplot(1,2,1);
    set(gca, 'FontSize',7);
    hold on;
    plot(r,'-bx');
    plot(t,':r.');
    hold off;
    axis([1 max(M,N) min(min(r),min(t)) 1.1*max(max(r),max(t))]);
    grid;
    legend('signal 1','signal 2');
    title('Original signals');
    xlabel('Samples');
    ylabel('Amplitude');
    
    subplot(1,2,2);
    set(gca, 'FontSize',7);
    hold on;
    plot(rw,'-bx');
    plot(tw,':r.');
    hold off;
    axis([1 k min(min([rw; tw])) 1.1*max(max([rw; tw]))]);
    grid;
    legend('signal 1','signal 2');
    title('Warped signals');
    xlabel('Samples');
    ylabel('Amplitude');
    %}
end