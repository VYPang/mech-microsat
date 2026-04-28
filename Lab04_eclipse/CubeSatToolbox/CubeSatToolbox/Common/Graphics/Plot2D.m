function [h, hA] = Plot2D( x, y, xL, yL, figTitle, plotType, iY, iX, nCols, pThresh, figBackColor, leg )

%% Easily build a versatile 2D plot page consisting of any number of plots. 
% Data is indexed into a subplot grid and labels are applied automatically.
% The data series must be in rows. Any of the inputs, except y, may be
% omitted or [].
%
% The elements of iY indicate what rows of the y matrix should be plotted on 
% each subplot. If iY is not entered the number of y-axis labels will determine 
% the number of plots on the page. The number of rows of x must equal the number 
% of x labels. If you enter only one row of x it will be used for all plots 
% without the need to enter iX. Otherwise, the elements of iX indicate
% which rows of the x matrix should be used for each subplot.
%
% For example, to plot a position in a (3,n) matrix:
%
%   Plot2D( t, r, 'Time', {'X','Y','Z'}, 'Position Vector' )
%
% or even just
%
%   Plot2D( t, r )
%
% To plot this position overlaid with a target, 
%
%   Plot2D(t,[r;rT],'Time',{'X','Y','Z'},'Position Vector',[],{'[1 4]','[2 5]','[3 6]'})
%
% This function has a built-in demo with 4 subplots showing indexing. Type
% Plot2D for the demo.
%--------------------------------------------------------------------------
%   Form:
%   [h, hA] = Plot2D( x, y, xL, yL, figTitle, plotType, iY, iX, nCols, pThresh, figBackColor, leg )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x          (m,:)       x values
%   y          (n,:)       y values
%   xL       (m,:) or {m}  x-axis label(s)
%   yL       (n,:) or {n}  y-axis label(s)
%   figTitle    (:)        Figure title
%   plotType (n,4) or {n}  Type of axes 'xlog', 'ylog', 'log', 'lin'. 'lin' is the default.
%   iY       (n,:) or {n}  Index. Indexes Y data to plots. Each row or cell gives the indexes
%                          of the data that go on that plot. This is a string,
%                          either '[1 2 3 4]', '1:3', or an array.
%   iX         (n,1)       Index. Indexes X data to plots. Each row gives the indexes
%                          of the x data that goes with that plot.
%   nCol       (1,1)       Number of columns.
%   pThresh    (1,1)       Minimum plot resolution. Set to 2.220446049250313e-10 for PowerPC
%                          Prevents a MATLAB warning that appears in V5.x.
%   figBackColor (1)       Flag for fig background color (0 - grey, 1 - white)
%   leg         {}         Add legends for each plot {{'a', 'b', 'c'},{'x','y'}}
%
%   -------
%   Outputs
%   -------
%   h          (1,1)       Figure handle
%   hA         (:)         Data structure of handles to line objects
%                          .h
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-2019 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2019.1 Added legends
%--------------------------------------------------------------------------

% Demo
%-----
if nargin == 0
  t = linspace(0,7);
  x = [sin(t);cos(t);1+sin(t).*cos(t)];
  Plot2D( t, x, 'Angle (rad)', {'Sine','Cosine','Function','Combined'},...
    'An example of the use of Plot2D',[],{1,2,3,[1 2 3]} );
  return;
end

if( nargin < 2 )
	error('Two arguments must be entered');
end

if nargin < 11
   figBackColor = 0;
end

if( nargin < 10 || isempty(pThresh) )
	pThresh = 2.220446049250313e-10;
end

if( nargin < 9 )
	nCols = [];
end

if( nargin < 8 )
	iX = {};
end

if( nargin < 7 )
	iY = {};
end

if( nargin < 6 )
	plotType = [];
end

if( nargin < 5 )
	figTitle = [];
end

if( nargin < 4 )
	yL = [];
end

if( nargin < 3 )
	xL = [];
end

if( isempty(nCols) )
    nCols = 1;
end

% Allow the use of cell arrays for plotType
%------------------------------------------
if( ~iscell(plotType) )
  f = plotType;
  plotType = cell(size(f,1),1);
  for k = 1:size(f,1)
    plotType{k} = f(k,:);
  end
end

% Size of y data
%---------------
[n,m] = size(y);

% Default x
%----------
if( isempty(x) )
  x = 1:m;
end

% Default figure title
%---------------------
useTitle = 1;
if( isempty(figTitle) )
	if( isempty(yL) )
	  useTitle = 0;
		figTitle = 'Plot';
  else
    if iscell(yL)
      figTitle = yL{1};
    else
      figTitle = yL(1,:);
    end
	end
end

% Default y labels
%-----------------
if( isempty(yL) )
	yL = 'y';
	for k = 2:n
		yL = char(yL,'y');
	end
end

if( iscell( yL ) )
	yL = CellToMat( yL );
end

% Plot indexes
%-------------
if( isempty(iY) ) 
  nPlots = size(yL,1);
  if( nPlots == 1 )
 		if( n > 1 )
	 	  iY = {1:n};
		else
	 	  iY = {1};
		end
  else
    if( n ~= nPlots )
	  	error('If indices are not entered the number of Y labels either must == 1 or the number of plots')
    else
			iY{1} = 1;
    	for k = 2:nPlots
     		iY{k} = k;
      end
    end
  end
else
  if (ischar(iY) || isnumeric(iY))
    % distribute to cell array
    iY = MatToCell( iY );
  end
  nPlots = length(iY);
end

nRows = ceil(nPlots/nCols);

% Default x labels
%-----------------
if( isempty(xL) )
	xL = 'x';
end

if( iscell( xL ) )
  xL = CellToMat( xL );
end

% Put x labels only at the bottom of each column of plots
%--------------------------------------------------------
rXL = size(xL,1);
if( rXL == 1 )
	k           = [(nRows-1)*nCols + (1:(nCols-1)) nPlots];
	xLT         = xL;
	xL          = blanks(length(xLT));
	for j = 1:length(k)
		xL(k(j),:) = xLT;
	end
end

% Default plot types
%-------------------
if( isempty(plotType) )
  for k = 1:nPlots
    plotType{k} = 'lin';
  end
else
  rPT = size(plotType,1);
  if( rPT == 1 )
    for k = 2:nPlots
      plotType{k} = plotType{1};
    end
  end
end

% Default x
%----------
if( isempty(iX) )
	nX = size(x,1);
	if( nX == nPlots )
    jX = cell(1,nPlots);
    for k = 1:nPlots
      jX{k} = k;
    end
	elseif( nX == n )
 		jX{k} = 1:n;
	elseif( nX == 1 )
    jX = cell(1,nPlots);
    for k = 1:nPlots
      jX{k} = 1;
    end
	else
		error('If indices are not entered the number of x rows must equal 1 or the number of plots')
	end
else
  if (ischar(iX) || isnumeric(iX))
    % distribute to cell array
    nX = size(iX,1);
    iX = MatToCell( iX );
  else
    nX = length(iX);
  end
	 if( nX == nPlots )
    jX = cell(1,nPlots);
		for k = 1:nPlots
      if ischar(iX{k})
        jX{k} = str2num(iX{k});
      else
        jX{k} = iX{k};
      end
	 end
	else
		error('Number of rows of IX, if entered, must equal number of plots');
	end
end

% Just print if there is only one column of data
if( m == 1 )
	if( size(x,1) > 1 )
	  for k = 1:nPlots
		  fprintf(1,'%s = %12.4g at %s = %12.4g\n',yL(k,:),y(k,1),xL(k,:),x(jX{k},1));
	  end
	else
	  for k = 1:nPlots
		  fprintf(1,'%s = %12.4g at %s = %12.4g\n',yL(k,:),y(k,1),xL(end,:),x(1,1));
    end
  end
  h = [];
  hA = [];
	return;
end

% Create the figure
hFig = figure;
set(hFig,'Name',figTitle,'tag','Plot2D');

% Set the background color 
%-------------------------
if figBackColor == 1
   set(hFig,'Color',[1 1 1]);
end

% Add the watermark
%------------------
Watermark('Princeton Satellite Systems',hFig);

[style,font,fSI] = PltStyle;
if( useTitle == 1 )
	axes('pos', [0 0.96 1 0.04]);
	axis off
	text(.5,0.2,figTitle,'horizontal','center','FontWeight',style,'FontName',font,'FontSize',14+fSI);
end

% Do the plots
%-------------
for k = 1:nPlots
  j = iY{k};
  if ischar(j)
    j = eval(j);
  end
	
  subplot(nRows,nCols,k);
  
  % This code eliminates an annoying Matlab warning
  %------------------------------------------------
	minY = min(min(y(j,:)));
	maxY = max(max(y(j,:)));
	d    = max([abs(minY), abs(maxY)]);
	if( abs(maxY - minY) < pThresh*abs(d) )
		yT = mean(mean(y(j,:)))*ones(size(y(j,:)));
 	else
		yT = y(j,:);
 	end

	% Draw the plots
	%---------------
  if( strcmp(plotType{k},'lin') )
    hA(k).h = plot    ( x(jX{k},:)', yT', 'linewidth', 1 );
  elseif( strcmp(plotType{k},'log') )
    hA(k).h = loglog  ( x(jX{k},:)', yT', 'linewidth', 1 );
  elseif( strcmp(plotType{k},'xlog') )
    hA(k).h = semilogx( x(jX{k},:)', yT', 'linewidth', 1 );
  elseif( strcmp(plotType{k},'ylog') )
    hA(k).h = semilogy( x(jX{k},:)', yT', 'linewidth', 1 );
  else
    error([plotType{k} ' not supported'])
  end
  grid
  ylabel(yL(k,:),'FontSize',12+fSI);
  if ~isempty(find(~isspace(xL(k,:)), 1))
    xlabel(xL(k,:),'FontSize',12+fSI);
  end
  set(gca,'fontsize',11+fSI);
  
  % Add legends
  if( nargin > 11 )
    legend(leg{k},'location','best');
  end

end

if( nargout > 0 )
	h = hFig;
end


%--------------------------------------
% $Date: 2019-10-10 23:18:12 -0400 (Thu, 10 Oct 2019) $
% $Revision: 49995 $
