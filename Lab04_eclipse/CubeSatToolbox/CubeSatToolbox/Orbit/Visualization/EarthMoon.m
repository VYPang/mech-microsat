function EarthMoon( r, jD, scale, rMoon )

%% Plot an orbit track in the Earth/Moon System.
%   The plots are in the ECI frame. Has a built-in demo for an orbit with an 
%   apogee of 400,000 km, a perigee of 7000 km, and a duration of 5 days.
%   See also MoonV1, MoonEl.
%--------------------------------------------------------------------------
%   Forms:
%   EarthMoon( r, jD, scale, rMoon )
%   EarthMoon( elements, jD, scale, rMoon )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r                (3,:) ECI position vectors (km) -or-
%                    (1,6) elements
%   jD               (:)   Julian dates
%   scale            (1,2) Planet scale (optional, default is [1 1])
%   rMoon            (3,:) Moon position
%
%   -------
%   Outputs
%   -------
%   none                  
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 2004 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  [a, e] = RPRA2AE( 7000, 400000 );
  t      = linspace( 0, 5.6*86400, 1000 );
  jD     = JD2000+2.3 + t/86400;
  elM    = MoonEl( jD(1) );
  el     = [a elM(2) elM(3) 0 e 0];
  EarthMoon( el, jD, [3 5] );
  return;
end

% Scale the planet pictures correctly
%------------------------------------
if( nargin < 3 )
  scale = [1 1];
end

% Generate the orbital positions if elements are entered
%-------------------------------------------------------
[m, n] = size(r);

if( m == 1 && n == 6 )
  r = RVFromKepler( r, (jD - jD(1))*86400 );
end

% Generate the moon orbit
%------------------------
if( nargin < 4 ) 
  rMoon = zeros(3,length(jD));
  for k = 1:length(jD)
    [uT, rT] = MoonV1( jD(k) );
    rMoon(:,k) = rT*uT;
  end
end 

% Get the planet textures and data
%---------------------------------
pE = Map('EarthMR');
pM = Map('Moon');

NewFig('Earth Moon System')

% Sphere
%-------
[x,y,z] = sphere(24);

% Earth
%------
radius  = pE.radius*scale(1);
hSurf   = surface(radius*x,radius*y,radius*z);
grid;
set(hSurf,'CData',double(flipud(pE.planetMap)),'FaceColor','texturemap','edgecolor','none')
colormap( pE.planetColorMap );


% Moon Start
%-----------
x       = pM.radius*x*scale(2);
y       = pM.radius*y*scale(2);
z       = pM.radius*z*scale(2);
hSurf   = surface(x+rMoon(1,1),y+rMoon(2,1),z+rMoon(3,1));
grid;
set(hSurf,'CData',double(flipud(pM.planetMap)),'FaceColor','texturemap','edgecolor','none')
colormap( pM.planetColorMap );

hSurf   = surface(x+rMoon(1,end),y+rMoon(2,end),z+rMoon(3,end));
grid;
set(hSurf,'CData',double(flipud(pM.planetMap)),'FaceColor','texturemap','edgecolor','none')
colormap( pM.planetColorMap );


view(3);
XLabelS('x (km)')
YLabelS('y (km)')
ZLabelS('z (km)')
rotate3d on
hold on;
plot3( r(1,:),     r(2,:) ,    r(3,:),     'color', 'r', 'linewidth', 1 );
plot3( rMoon(1,:), rMoon(2,:) ,rMoon(3,:), 'color', 'b', 'linewidth', 1 );

% Add text
t  = (jD - jD(1))*86400;

n  = length(t);
j  = ceil(linspace(1,n,5));


[t, ~, tU] = TimeLabl(t);

for k = 1:length(j)
  jK  = j(k);
  s   = sprintf('t = %3.1f %s',t(jK),tU);
  text(     r(1,jK),     r(2,jK),     r(3,jK), s );
  text( rMoon(1,jK), rMoon(2,jK), rMoon(3,jK), s );
end

Axis3D('Equal')
axis image
hold off

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-23 17:34:37 -0400 (Tue, 23 Jun 2020) $
% $Revision: 52881 $
