function GroundTrack( r, t, jD0, planet, gS )

%% Plot an orbit track. Converts the inertial positions to planet-fixed.
% Pass in the time array and the initial epoch. The epoch may be a Julian date
% or a datetime array. The initial position is marked with an 'o'. Ground
% stations are marked with 'x'.
%
% You generate the planet data structure like this example;
% The replication of the image map is needed because the png is gray scale.
%
%   p = imread('planet.png');
%   p3(:,:,1) = p;
%   p3(:,:,2) = p;
%   p3(:,:,3) = p;
%   planet.planetMap = p3;
%   planet.radius = 1000;
%   planet.name = 'MyPlanet';
%
% Type GroundTrack for a demo showing an orbit around the Earth.
%--------------------------------------------------------------------------
%   Form:
%   GroundTrack( r, t, jD0, planet, gS )
%   GroundTrack( r, t, datetime, planet, gS )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r                (3*n,:) ECI position vectors (km)
%   t                (1,:) Time array (sec)
%   jD0              (1,1) Epoch Julian date
%             -or- 
%   datetime         (1,6) [year month day hour minute seconds]
%
%   planet           (1,:) Planet (default is earth)
%             -or-
%                    (.)
%                          (1,:) name
%                          (:)   planetMap
%                          (:)   planetColorMap (optional)
%                          (1,1) radius (km)
%   gS               (2,:) Ground stations [lat;lon] (deg)
%
%   -------
%   Outputs
%   -------
%   none   
%
%--------------------------------------------------------------------------
% See also ECIToPlanet, R2LatLon, Date2JD
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2014, 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2014.1
%   2017.1 Added other planets, multiple tracks and ground stations
%   2017.1 Added the option for planet to be a planet structure
%--------------------------------------------------------------------------

if( nargin < 2 )
  % Built-in demo
  p         = Period(9000);
  [r, ~, t] = RVFromKepler( [9000 pi/4 0 0 0.2 0], linspace(0,4*p,400) );
  jD0       = JD2000;
  GroundTrack( r, t, jD0, 'Earth', [0 45 -45;0 120 240] );
	%GroundTrack( r, t, jD0, 'Mars', [0 45 -45;0 120 240] );
  return;
end

% Use today's date as a default
if nargin < 3
  jD0 = Date2JD;
end

if( nargin < 4 )
  planet = [];
end

if( length(jD0)>1 )
  jD0 = Date2JD( jD0 );
end

if( isempty(planet) )
  planet = 'Earth';
end

% Array of Julian centuries
%--------------------------
jD = jD0 + t/86400;


if( strcmp(planet,'Earth') )
  d = load('EarthMR');
elseif(isstruct(planet))
  d.planet	= planet;
  planet    = planet.name;
else
  d         = load(planet);
end

% Transform to the planet fixed frame
%------------------------------------
cR = size(r,2);
nS = floor(size(r,1)/3);
for j = 1:nS
  i = 3*j-2:3*j;
  for k = 1:cR
    r(i,k) = ECIToPlanet( jD(k), planet )*r(i,k);
  end
end
p = Map(d.planet);

s = sprintf('Ground Track on %s',planet);
NewFig(s);
[xdim,ydim]=size(p.planetMap);
plot(0,0), hold on
axis([-180 180 -90 90])
x=linspace(-180,180,xdim);
y=linspace(90,-90,ydim);
pmd = size(p.planetMap,3);
if( pmd==3 )
	image(x,y,p.planetMap);
else
	image(x,y,planet.planetMap);
	colormap(planet.planetColorMap)
end
axis equal, axis tight
XLabelS('East Longitude (deg)')
YLabelS('Latitude (deg)')

c = 'ybgrcm';
j = 1;
for k = 1:nS
  i         = 3*k-2:3*k;
  [lat,lon] = R2LatLon(r(i,:));  
  lat       = lat*180/pi;
  lon       = lon*180/pi; 
  lLon      = length(lon);
  kLon      = [0 find(abs(lon(2:lLon) -lon(1:(lLon-1))) > 300 ) lLon];

  lK        = length(kLon);
  
  for i = 2:lK
    range = (kLon(i-1)+1):kLon(i); 
    plot(lon(range),lat(range),c(j));
  end
  plot(lon(1),lat(1),sprintf('%so',c(j)));
  j = j + 1;
  if( j > length(c) )
    j = 1;
  end
end

% Add ground stations
if( nargin > 4 )
  j = find(abs(gS(2,:)) > 180 );
  gS(2,j) = gS(2,j) - sign(gS(2,j))*180;
  plot(gS(2,:),gS(1,:),'wx')
end
grid on
hold off


%--------------------------------------
% $Date: 2017-06-12 15:40:32 -0400 (Mon, 12 Jun 2017) $
% $Revision: 44835 $
