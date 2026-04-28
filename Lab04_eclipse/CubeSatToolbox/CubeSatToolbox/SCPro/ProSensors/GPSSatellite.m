function [r, v] = GPSSatellite( jD, coord )

%% Gives the location of the GPS satellites at JD.
%   Choice of Earth-fixed or ECI reference frames.
%
%   Type GPSSatellite for a demo.
%
%--------------------------------------------------------------------------
%   Forms:
%   [r, v] = GPSSatellite( jD )
%   [r, v] = GPSSatellite( jD, coord )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD            (1,1)   Julian Date
%   coord         (1,:)   'ef' or 'eci' (eci is the default)
%
%   -------
%   Outputs
%   -------
%   r             (3,24)  Satellite locations
%   v             (3,24)  Satellite velocity
%
%--------------------------------------------------------------------------
%   Reference: Kayton, M. and W. R. Fried. (1997.) "Avionics Navigation 
%              Systems," John Wiley & Sons.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc.  
%   All rights reserved.
%--------------------------------------------------------------------------

jDEpoch = Date2JD( [ 1993 7 1 0 0 0] );

if( nargin < 2 )
  coord = [];
end

if( nargin < 1 )
  jD = [];
end

if( isempty(coord) )
  coord = 'eci';
else
  coord = lower(coord);
end

if( isempty(jD) )
  jD = Date2JD;
end

degToRad = pi/180;

% Orbital elements
%-----------------
a       = 26559.8;
W       = [272.847 332.847 32.847 92.847 152.847 212.847]*degToRad;
dMPlane = [0 15 30 45 60 75]*degToRad;
e       = 0;
i       = 55*degToRad;
w       = 0;

p       = 0;
dM      = OrbRate(a,a)*(jD - jDEpoch)*86400;
r       = zeros(3,24);
v       = zeros(3,24);

for k = 1:6
  c = CP2I( i, W(k), w );
  for j = 1:4
    p       = p + 1;
    M       = (pi/2)*(j-1) + dMPlane(k) + dM;
    cf      = cos(M);
    sf      = sin(M);  
    rp      = a*[ cf; sf; 0 ];
    vp      = sqrt(3.98600436e5/a)*[-sf; cf; 0];
    r(:,p)  = c*rp;
    v(:,p)  = c*vp;
  end   
end

% Transform into the earth fixed frame
%-------------------------------------
if( strcmp(coord,'ef'))
  c     = TruEarth( JD2T( jD) );
  omega = EarthRte(jD);
  r     = c*r;
  v     = c*v - Cross([0;0;omega],r);
end


% Plot if no arguments are entered
%---------------------------------
if( nargout == 0 )
  NewFig('GPS Constellation ');
  
  % Draw the earth
  %---------------
  p       = Map;
  [x,y,z] = sphere(24);
  hSurf   = surface(p.radius*x,p.radius*y,p.radius*z);
  set(hSurf,'CData',double(flipud(p.planetMap)),'FaceColor','texturemap','edgecolor','none')
  colormap( p.planetColorMap );
  hold on
  view(3)
  
  % Transform into the earth fixed frame
  %-------------------------------------
  if( ~strcmp(coord,'ef') )
    c  = TruEarth( JD2T( jD ) );
    r = c*r;
  end
  
  % Draw the satellites
  %--------------------
  plot3(r(1,:),r(2,:),r(3,:),'*',0,0,0,'or')
  s = sprintf('GPS Satellites at JD =  %12.2f in the EF frame',jD);
  
  % Plot the orbital planes
  %------------------------
  for k = 1:6
    z = c*RVFromKepler( [a;i;W(k);w;e;0] );
    plot3( z(1,:), z(2,:), z(3,:), 'm' )
  end
  hold off 
  rotate3d on

  % Plot labels and axis control
  %-----------------------------
  grid
  XLabelS('X (km)')
  YLabelS('Y (km)')
  ZLabelS('Z (km)')
  TitleS(s)
  Axis3D('Equal')
  axis square
  rotate3d on
  clear r
end

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 12:37:25 -0400 (Tue, 09 May 2017) $
% $Revision: 44511 $

