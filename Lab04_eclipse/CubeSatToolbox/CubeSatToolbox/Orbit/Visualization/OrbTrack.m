function OrbTrack( r, jD, gType, planet, hFig )

%% Plot a planet-fixed orbit track in 2D or 3D. 
% Converts the input inertial positions to planet-fixed using ECIToPlanet.
% Has a built-in demo showing a Mars orbit in both 3D and 2D.
%--------------------------------------------------------------------------
%   Form:
%   OrbTrack( r, jD, gType, planet, hFig )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r                (3,:) ECI position vectors (km) or
%                    (1,6) elements
%   jD               (:)   Julian dates
%   gType            (1,:) '2d' or '3d' Default is '3d'
%   planet           (1,:) Any planet in the database
%   hFig             (1,:) Figure handle
%
%   -------
%   Outputs
%   -------
%   none                  
%
%--------------------------------------------------------------------------
% See also ECIToPlanet, Map, PlotPlanet, JD2Array, RVOrbGen
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	 Copyright 1995-1999, 2017 Princeton Satellite Systems, Inc. 
%  All rights reserved.
%--------------------------------------------------------------------------
% Since version 1.
%--------------------------------------------------------------------------

if( nargin < 2 )
  % Built-in demo
  mu = Constant('mu mars');
  t  = linspace(0,2*Period(7000,mu));
  r  = RVOrbGen( [7000 pi/4 0 0 0.02 0], t, [], mu );
  jD = JD2Array(JD2000,t);
  OrbTrack( r, jD, '3d', 'Mars' );
  OrbTrack( r, jD, '2d', 'Mars' );
  return;
end

if( nargin < 3 )
	gType = [];
else
  gType = lower(gType);
end

if( nargin < 4 )
	planet = [];
end

if( nargin < 5 )
  hFig = [];
end

if( isempty(gType) )
	gType = '3d';
end

doMark = false;
if( isempty( hFig ) )
  hFig = NewFig('Orbit Track');
  doMark = true;
end

[m, n] = size(r);

if( m == 1 && n == 6 )
  % Compute position from elements
  r = RVOrbGen( r, (jD - jD(1))*86400 );
end

% Transform to the planet fixed frame
%------------------------------------
[~,cR] = size(r);
for k = 1:cR
  r(:,k) = ECIToPlanet( jD(k), planet )*r(:,k);
end

% Get the planet picture
%-----------------------
if( isempty(planet) )
	p = Map;
else
	p = Map(planet);
end

gType = lower(gType);
if( gType == '2d')

  [lat,lon] = R2LatLon(r);  
  lat       = lat*180/pi;
  lon       = lon*180/pi; 
  lLon      = length(lon);
  kLon      = [1 find(abs(lon(2:lLon) -lon(1:(lLon-1))) > 300 ) lLon];

  axis([-180 180 -90 90])
  hold on
  [xdim,ydim]=size(p.planetMap);
  plot(0,0), hold on
  axis([-180 180 -90 90])
  x=linspace(-180,180,xdim);
  y=linspace(90,-90,ydim);
  im = image(x,y,p.planetMap);
  colormap(p.planetColorMap)
  axis equal, axis tight
  XLabelS('East Longitude (deg)')
  YLabelS('Latitude (deg)')
  lK = length(kLon);
  for i = 2:lK
    range = (kLon(i-1)+1):kLon(i); 
    plot(lon(range),lat(range),'y');
  end
  grid on
  hold off
  
elseif( gType == '3d' )
  PlotPlanet([0;0;0],p.radius,p);
  grid on;
  view(3);
  XLabelS('x (km)')
  YLabelS('y (km)')
  ZLabelS('z (km)')
  rotate3d on
  hold on;
  hPlot = plot3( r(1,:), r(2,:) ,r(3,:), 'color', 'r', 'linewidth', 1 );
  axis equal
  hold off

else
  error(['Plot type ', gType,' not supported']);
end
TitleS('Planet-fixed Trajectory')


if (doMark)
  Watermark('Spacecraft Control Toolbox',hFig);
end


%--------------------------------------
% $Date: 2017-06-05 15:00:42 -0400 (Mon, 05 Jun 2017) $
% $Revision: 44755 $
