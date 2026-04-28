function [h, hA] = Plot3D( r, xL, yL, zL, figTitle, rPlanet, figBackColor  )

%% Create a 3-dimensional plot. 
%--------------------------------------------------------------------------
%   Form:
%   [h, hA] = Plot3D( r, xL, yL, zL, figTitle, rPlanet, figBackColor  )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r          (3,:)    x, y, z values
%   xL         (n,:)    x-axis label
%   yL         (n,:)    y-axis label
%   zL         (n,:)    z-axis label
%   figTitle            Figure title
%   rPlanet    (1,1)    Radius of planet sphere
%   figBackColor (1)	Flag for fig background color (0 - grey, 1 - white)
%
%   -------
%   Outputs
%   -------
%   h          (1,1)    Figure handle
%   hA         (:)      Data structure of handles to line objects
%                       .h
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-1997 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   2017.1 Clarify "rotate3d" using full syntax, "rotate3d on".
%--------------------------------------------------------------------------

if (nargin == 0)
  if( exist('RVFromKepler','file') )
    r = RVFromKepler([7000 0.5 0 0 0 0]);
    Plot3D( r );
    Plot3D( r, 'X', 'Y', 'Z', 'Example of Plot3D', 6378, 0 );
  else
    theta   = linspace(0,2*pi);
    c       = [1,0,0;0 cos(0.5),-sin(0.5);0,sin(0.5),cos(0.5)];
    r       = c*[7000*cos(theta);7000*sin(theta);zeros(size(theta))];
    Plot3D( r );
  end
  return;
end

if( nargin < 7 )
    figBackColor = 1;
end

if( nargin < 6 )
    rPlanet = [];
end

if( nargin < 5 )
	figTitle = [];
end

if( nargin < 4 )
	zL = [];
end

if( nargin < 3 )
	yL = [];
end

if( nargin < 2 )
	xL = [];
end

% Size of r data
%---------------
[n,~] = size(r);

if( n ~= 3 )
  fPlot = 'plot';
else
  fPlot = 'plot3';
end

% Default figure title
%---------------------
useTitle = 1;
if( isempty(figTitle) )
	if( isempty(yL) )
	  useTitle = 0;
		figTitle = 'Plot';
	else
		figTitle = yL;
	end
end

% Default y labels
%-----------------
if( isempty(xL) )
	xL = 'x';
end
if( isempty(yL) )
	yL = 'y';
end
if( isempty(zL) )
	zL = 'z';
end

% Create the figure
%------------------
hFig = figure;
set(hFig,'name',figTitle,'tag','Plot2D');

% Make the plot
%--------------
switch fPlot
case 'plot'
  hA = plot( r(1,:), r(2,:), 'linewidth', 2 );
case 'plot3'
  hA = plot3( r(1,:), r(2,:), r(3,:), 'linewidth', 2 );
  if( ~isempty(rPlanet) )
    hold on;
    [x,y,z] = sphere(24);
    surf(rPlanet*x,rPlanet*y,rPlanet*z,'facecolor',[0.7 0.7 0.7],'edgecolor',[0.6 0.6 0.6]);
    hold off;
  end
  axis('equal'); view(37.5,30); 
  rotate3d on;
end

grid
ZLabelS(zL);
YLabelS(yL);
XLabelS(xL);
[style,font,fSI] = PltStyle;

set(gca,'fontsize',11+fSI);

% Set the background color 
%-------------------------
if figBackColor == 1
   set(hFig,'Color',[1 1 1]);
end

Watermark('Princeton Satellite Systems',hFig);

if( useTitle == 1 )
	title(figTitle,'FontWeight',style,'FontName',font,'FontSize',14+fSI);
end

if( nargout > 0 )
	h = hFig;
end


%--------------------------------------
% $Date: 2017-05-02 11:04:18 -0400 (Tue, 02 May 2017) $
% $Revision: 44448 $
