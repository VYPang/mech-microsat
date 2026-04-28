function h = PltOrbit( el, jD, uSpin, planet )

%% Plots one orbit and the sun vector looking down on the ECI Plane.
%   The input is a set of Kepler elements and a Julian date. It also plots 
%   the line of nodes and the line between apogee and perigee, and, 
%   optionally, a spin axis located at the beginning of the orbit.
%
%   Specify a planet name to use SunVectorECI instead of SunV1.
%
%   Has two built-in demos, one for an Earth orbit and one for Mars.
%
%--------------------------------------------------------------------------
%   Form:
%   h = PltOrbit( el, jD, uSpin, planet )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el            (1,6)   Orbital elements [a i W w e M]
%   jD            (1,1)   Julian date
%   uSpin         (3,1)   Spin axis (optional)
%   planet        (1,:)   Planet name (optional)
%
%   -------
%   Outputs           
%   -------
%   h             (1,1)   Figure handle
%
%--------------------------------------------------------------------------
%   See also: SunV1, SunVectorECI, PlotPlanet, AxesCart, Axis3D
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994-1998, 2015, 2018 Princeton Satellite Systems, Inc.
%   All rights reserved. 
%--------------------------------------------------------------------------
%   Since version 1.
%   2018.1 Now draws map of planet
%--------------------------------------------------------------------------

if nargin == 0
  el  = [7000 0.005 0 0 0 0];
  jD  = Date2JD;
  h   = PltOrbit( el, jD, [0;0;1], 'Mars' );
  clear h
  return;
end
  
if nargin == 4
  SunVectorECI( 'initialize', planet )
  mu      = Constant(['mu ' planet]);
  rECI    = El2RV(el,[],mu);
  uSun    = SunVectorECI('update',jD,rECI);
  radius  = Constant(['equatorial radius ' planet]);
else
  uSun    = SunV1(jD);  
  radius  = 6378;
  planet  = 'Earth';
end

a    = el(1);
i    = el(2);
W    = el(3);
w    = el(4);
e    = el(5);
M0   = el(6);
dM   = 2*pi/100;

if( e >= 1 )
  error('PSS:PltOrbit:error','Orbit must be elliptic');
end

if( a < 0 )
  error('PSS:PltOrbit:error','Semi-major axis must be positive');
end

rW1  = a*(1-e^2)/(1 + e*cos(-w));
rW2  = a*(1-e^2)/(1 + e*cos(pi-w));
rp   = a*(1-e);
ra   = a*(1+e);

% Line of nodes
uW   = [rW1*[cos(W);sin(W);0], rW2*[cos(W+pi);sin(W+pi);0]];

% Apogee/perigee line
uw   = CP2I(i,W,w)*[[-ra;0;0],[rp;0;0]]; 

ci   = cos(i);
si   = sin(i); 
cW   = cos(W); 
sW   = sin(W);

if M0 < 0,
  M0 = M0 + 2*pi;
end  

% Compute 100 points along the orbit
%-----------------------------------
rx = zeros(1,101);
ry = zeros(1,101);
rz = zeros(1,101);

for k = 1:101

  M     = M0 + (k-1)*dM;

  nu    = E2Nu(e,M2EEl(e,rem(M,2*pi))); 

  cn    = cos(nu+w); 
  sn    = sin(nu+w); 

  rMag  = a*(1-e^2)/(1+e*cos(nu));  

  rx(k) = rMag*(cn*cW-sn*ci*sW);
  ry(k) = rMag*(cn*sW+sn*ci*cW);
  rz(k) = rMag*sn*si;

end

uS = [];
if (nargin >= 3 && ~isempty(uSpin))
  % Compute plottable spin vector uS
  %---------------------------------
  uSpin = 0.2*max([max(abs(rx)) max(abs(ry)) max(abs(rz))])*uSpin;
  uS    = [rx(1) rx(1)+uSpin(1);ry(1) ry(1)+uSpin(2);rz(1) rz(1)+uSpin(3)];
end

h = NewFig([planet ' Orbit']);

c = load([planet '.mat']);
PlotPlanet([0;0;0],radius,c.planet);
light('position',uSun);
AxesCart(radius,radius,radius);
xlabel('X ECI','FontWeight','bold','FontName','Helvetica')
ylabel('Y ECI','FontWeight','bold','FontName','Helvetica')
zlabel('Z ECI','FontWeight','bold','FontName','Helvetica')
view(150,30);
rotate3d on
hold on;

plot3(rx,ry,rz,uw(1,:),uw(2,:),uw(3,:),'b',uW(1,:),uW(2,:),uW(3,:),'g')
if ~isempty(uS)
 plot3(uS(1,:),uS(2,:),uS(3,:),'c')
end
Axis3D('Equal')
axis square
hold off;
grid on

Watermark('Spacecraft Control Toolbox',h)


%--------------------------------------
% $Date: 2018-11-12 15:26:40 -0500 (Mon, 12 Nov 2018) $
% $Revision: 47432 $
