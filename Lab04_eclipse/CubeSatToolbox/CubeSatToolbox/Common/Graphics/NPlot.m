function NPlot( yLabels, y, x, xAxisLabel, yAxisLabel, plotTitle, figTitle )

%% NPlot generates a plot on which the ylabels are character strings. 
% The y data is assumed to be integers with each integer corresponding to a
% label given in yLabels. Will generate a new figure if figTitle is entered.
%   
% Any input, except yLabels and y may be [].
%--------------------------------------------------------------------------
%   Form:
%   NPlot( yLabels, y, x, xAxisLabel, yAxisLabel, plotTitle, figTitle )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   yLabels                  Labels for the y-axis corresponding to integral
%                            values of y.
%   y                        y-data
%   x                        x-data
%   xAxisLabel               The x-axis label
%   yAxisLabel               The y-axis label
%   plotTitle                The plot title
%   figTitle                 The figure title
%
%   -------
%   Outputs
%   -------
%   none
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin < 7 )
  figTitle = [];
end

if( nargin < 6 )
  plotTitle = [];
end

if( nargin < 5 )
	yAxisLabel = [];
end

if( nargin < 4 )
	xAxisLabel = [];
end

if( nargin < 3 )
	x = [];
end

if( nargin < 2 )
	error('PSS:minrhs','First two inputs are required.')
end

yMax  = ceil( max( y ) );
yMin  = floor( min( y ) );
yI    = linspace(yMin,yMax,yMax-yMin+1);
yL    = 1:length(yI);


% If yMax exceeds the number of labels, append 'Unknown' to the list of labels
%--------------------------------------------------------------------------
[r,c] = size(yLabels) ;

if( r < yMax+1 )
  for k = 1:(yMax+1-r)
    yLabels = strvcat(yLabels,'Unknown');
  end
end

if( ~isempty(figTitle) )
  NewFig(figTitle);
end

a = get(gca,'Position');
set(gca,'Position',[0.23 a(2) 0.675 a(4)]);
if( isempty(x) )
  plot(y);
else
  plot(x,y);
end

if( ~isempty(plotTitle) )
	[style,font] = PltStyle;
	title(plotTitle,'FontWeight',style,'FontName',font,'FontSize',14);
end

if( ~isempty(xAxisLabel) )
  XLabelS(xAxisLabel);
end

if( ~isempty(yAxisLabel))
  YLabelS(yAxisLabel);
end

set(gca,'yTick',yI,'YTickLabel',yLabels(yL,:));
grid;


%--------------------------------------
% $Date: 2017-05-01 16:57:45 -0400 (Mon, 01 May 2017) $
% $Revision: 44443 $
