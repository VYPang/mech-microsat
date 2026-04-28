function hSurf = PlotPlanet( r, radius, color, noLines )

%% Add planet to the current axes.
% The planet will be a solid color sphere. The color may be input as a
% structure with color data and a texture map, see Earth.mat
%--------------------------------------------------------------------------
%   Form:
%   hSurf = PlotPlanet( r, radius, color, noLines )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r        (3,1)     Location of planet in figure frame
%   radius   (1,1)     Planet radius
%   color    (1,1)     Color, i.e. 'y', 'b' or [R G B], or structure
%                        .planetMap
%                        .planetColorMap
%   noLines  (1,1)     Flag to skip the lat/lon lines
%
%   -------
%   Outputs
%   -------
%   hSurf    (1,1)     Handle to surface object
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%  Copyright (c) 2007 Princeton Satellite Systems, Inc. 
%  All rights reserved.
%--------------------------------------------------------------------------
%  Since 8.1
%--------------------------------------------------------------------------

if( nargin == 0 )
  % First draw a solid gray planet
  NewFig('PlotPlanet');
  r = [0;0;0];
  radius = 6378;
  PlotPlanet( r, radius );
  axis equal
  view(3)
  hold on
  % Then draw an offset planet with a texturemap
  d     = load('EarthMR.mat');
  r     = [15000;5000;1000];
  hSurf = PlotPlanet( r, 0.5*radius, d.planet );
  Watermark('Princeton Satellite Systems',gcf);
  clear hSurf
  return;
end

if nargin < 3
  color = [0.5 0.5 0.5];
end
if nargin<4
  noLines = false;
end

if isempty(r)
  r = [0;0;0];
end

if isempty(radius)
  radius = 6378;
end

hold on

[x,y,z] = sphere(24);

X = radius*x + r(1);
Y = radius*y + r(2);
Z = radius*z + r(3);

hSurf = surface( X,Y,Z );

if isstruct(color)
   pmd =size(color.planetMap,3);
   if( pmd==3 )
     % truecolor
     pmap = color.planetMap;
     for i=1:3
        pmap(:,:,i)=flipud(pmap(:,:,i));
     end
     set(hSurf,'Cdata',pmap,'Facecolor','texturemap');
   else
     set(hSurf,'CData', double(flipud(color.planetMap)),...
         'FaceColor', 'texturemap');
     colormap( color.planetColorMap );
   end
else
  set(hSurf,'facecolor',color);
end

% lighting will enable terminator if light object is added.
set(hSurf,'edgecolor', 'none',...
          'EdgeLighting', 'gouraud','FaceLighting', 'gouraud',...
          'specularStrength',0.1,'diffuseStrength',0.9,...
          'SpecularExponent',0.5,'ambientStrength',0.2,...
          'BackFaceLighting','unlit');

% latitude and longitude lines
if ~noLines
  reg = 1.0001*radius;
  th = linspace(0,2*pi);
  cTh = reg*cos(th);
  sTh = reg*sin(th);
  plot3(cTh + r(1),sTh + r(2),0*th + r(3),'color',[0 0.5 0.5],'linewidth',2);
  for k = 1:6
    lat = k*pi/12;
    lon = pi/6*(k-1);
    plot3(cos(lat)*cTh + r(1),cos(lat)*sTh + r(2),reg*sin(lat)*ones(1,100)+r(3),'color',[0 0.5 0.5]);
    plot3(cos(lat)*cTh + r(1),cos(lat)*sTh + r(2),-reg*sin(lat)*ones(1,100)+r(3),'color',[0 0.5 0.5]);
    plot3(cTh*cos(lon) + r(1),cTh*sin(lon) + r(2),sTh+r(3),'color',[0 0.5 0.5]);
    plot3(cTh*cos(lon+pi) + r(1),cTh*sin(lon+pi) + r(2),sTh+r(3),'color',[0 0.5 0.5]);
  end
end

hold off
axis tight
grid on
rotate3d on


%--------------------------------------
% $Date: 2018-11-12 15:26:40 -0500 (Mon, 12 Nov 2018) $
% $Revision: 47432 $
