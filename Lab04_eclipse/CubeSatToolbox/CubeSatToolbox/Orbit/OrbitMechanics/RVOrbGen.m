function [r, v, t] = RVOrbGen( elI, t, uSun, mu, rPlanet, tol )

%% Generate an orbit by propagating Keplerian elements. 
% The orbit may have any eccentricity, including parabolic or hyperbolic.
%
% If t is not entered it generate one orbit. If there are no arguments it
% will plot the orbit. Enter rPlanet to draw a planet sphere. If the sun 
% vector is entered as well the planet sphere will be illuminated.
%--------------------------------------------------------------------------
%   Form:
%   [r, v, t] = RVOrbGen( el, t, uSun, mu, rPlanet, tol )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   elI        (1,6) Elements vector [a,i,W,w,e,M] or structure
%   t          (1,:) Time vector (sec)
%   uSun       (3,1) Sun vector*
%   mu         (1,1) Gravitational parameter
%   rPlanet    (1,1) Planet radius*
%   tol        (1,1) Orbit propagation tolerance (1e-8)
%                    * inputs for plotting purposes only
%
%   -------
%   Outputs
%   -------
%   r          (3,:) Position vectors for times t
%   v          (3,:) Velocity vectors for times t
%   t          (1,:) Times at which r and v are calculated
%
%
%--------------------------------------------------------------------------
%   See also RVFromKepler
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright 1995-1998,2014 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2016.1 - update demo to use RPRA2AE
%   2019.1 Update default value of mu
%--------------------------------------------------------------------------

if( nargin < 6 )
	tol = [];
end

if( nargin < 5 )
  rPlanet = [];
end

if( nargin < 4 )
  mu = [];
end

if( nargin < 3 )
  uSun = [];
end

if( nargin < 2 )
  t = [];
end

if( nargin < 1 )
  % Demo inputs
  i         = 0.4;
  a         = -4000;
  e         = 3;
  elI       = [a,i,0,0,e,0];
  uSun      = [1;0;0];
  rPlanet 	= 6378;
	tol       = 1e-8;
  [r, v, t] = RVOrbGen( elI, [], uSun, [], rPlanet, tol );
  if nargout == 0
    CreatePlots(t,r,v,rPlanet,uSun);
    clear r;
  end
  return;
end

if( isstruct(elI) )
  el(1) = elI.a;
  el(2) = elI.i;
  el(3) = elI.W;
  el(4) = elI.w;
  el(5) = elI.e;
  el(6) = elI.M;
else
	el    = elI;
end

a = el(1);
e = el(5);

if( isempty(tol) )
	tol = 1e-8;
end

if( isempty(mu) )
  mu = 3.98600436e5;
end

wo = sqrt(mu/abs(a)^3);
if( isempty(t) )
  if( e < 1 )
    t = linspace(0,2*pi/wo);
  else
    M = Nu2M(e,pi/2);
    t = linspace(-M/wo,M/wo);
  end
end

% Transforms from the perifocal frame to the inertial frame
%----------------------------------------------------------
c       = CP2I( el(2), el(3), el(4) );

M       = wo*t + el(6);

E       = M2E( e, M, tol );

theta   = E2Nu( e, E );

cTheta  = cos( theta );
sTheta  = sin( theta );

p       = SLR( e, a );

rMag    = p./(1 + e*cTheta); 

r       = c*[rMag.*cTheta;rMag.*sTheta;zeros(size(t))];
v       = sqrt(mu/p)*c*[-sTheta;e+cTheta;zeros(size(t))]; 

% Plot if no outputs are specified
%---------------------------------
if( nargout == 0 )
  CreatePlots(t,r,v,rPlanet,uSun);
  clear r;
end

function CreatePlots(t,r,v,rPlanet,uSun)

if( isempty(uSun) )
  showSun = 0;
else
  showSun = 1;
end

h = NewFig('Orbital Position');
plot3(r(1,:),r(2,:),r(3,:));
view(150,20)
XLabelS('X ECI (KM)')
YLabelS('Y ECI (KM)')
ZLabelS('Z ECI (KM)')
grid
axis('equal')
if( ~isempty(rPlanet) )
  Axis3D('Equal')
  hold on;
  [x,y,z] = sphere(24);
  if( showSun == 1 )
    surfl(rPlanet*x,rPlanet*y,rPlanet*z,uSun',[0,0.5,0.5,2]);
    shading interp;
    colormap('gray')
  else
    surf(rPlanet*x,rPlanet*y,rPlanet*z);
  end
  hold off;
end
rotate3d on
Watermark('Spacecraft Control Toolbox',h)

[t,c] = TimeLabl( t );
Plot2D(t,v,c,{'v_x (km/s)' 'v_y (km/s)' 'v_z (km/s)'},'Orbital Velocity');

%--------------------------------------
% $Date: 2020-04-24 23:47:44 -0400 (Fri, 24 Apr 2020) $
% $Revision: 51969 $
