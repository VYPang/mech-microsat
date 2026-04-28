function t = IsothermalCubeSatSim( d, r, q, jD, t0 )

%% An isothermal CubeSat simulation using Euler integration.
% The entire spacecraft is assumed to be at the same temperature.
% The spacecraft temperature is computed over the given orbit.  
%--------------------------------------------------------------------------
%   Form:
%   IsothermalCubeSatSim -- demo
%   t = IsothermalCubeSatSim( d, r, q, jD, t0 )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d       (.)      Data structure
%                    .mass       (1,1) Total mass
%                    .uSurface   (3,6) Surface unit vectors
%                    .alpha      {1,6} Absorptivity
%                    .epsilon    {1,6} Emissivity
%                    .area       (1,6) Area
%                    .cP         (1,1) Specific heat
%                    .powerTotal (1,1) Internal power (W)
%   r      (3,:)     Orbit
%   q      (4,:)     Quaternion
%   jD     (1,:)     Julian date
%   t0     (1,1)     Initial Temperature( deg-K )
%
%   -------
%   Outputs
%   -------
%   t      (1,:)     Temperature
%
%--------------------------------------------------------------------------
%   See also SunV1, Eclipse, RHSIsothermalCubeSat.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009-2010 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 10. 
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d = RHSIsothermalCubeSat;
  if nargout == 1
    t = d;
    return;
  end
  d.mass       = 3;
  d.uSurface   = [1  1  1 -1 -1 -1  0  0  0  0  0  0  0  0;...
                  0  0  0  0  0  0  1  1  1 -1 -1 -1  0  0;...
                  0  0  0  0  0  0  0  0  0  0  0  0  1 -1];
	x = 0.75;  y = 0.3; % Solar panel
	a = 0.8;   b = 0.1; % Gold foil
  d.alpha      = [x  a  x  x  a  x  x  a  x  x  a  x  0.3 0.3];
  d.epsilon    = [y  b  y  y  b  y  y  b  y  y  b  y  0.8 0.8];
  d.area       = 0.1*0.1*ones(1,14);
  d.cP         = 900;
  d.powerTotal = 1;
  sma          = 7100;
  time         = linspace(0,86400,2000);
  el           = [sma 0*pi/180 0 0 0 0];
  [r,v]        = RVFromKepler( el, time );
  jD           = Date2JD([2013 4 4 0 0 ]) + time/86400;
  q            = QLVLH( r, v );
  t0           = 285;
  IsothermalCubeSatSim( d, r, q, jD, t0);
  return
end

n = size(r,2);
t = zeros(1,n);
f = zeros(1,n);

t(1) = t0;
dT = (jD(2) - jD(1))*86400;

for k = 2:n
  [t(k), f(k)] = Euler( t(k-1), dT, d, r(:,k), q(:,k), jD(k) );
end

% Default output
%---------------
if( nargout < 1 )
  Plot2D( jD - jD(1), [t;f], 'Days', {'T (deg-K)' 'Q (W)'}, 'Isothermal temperature');
  clear t;
end
    
%--------------------------------------------------------------------------
%   Euler integration of thermal right hand side.
%   Inputs:
%     t  Temperature (K)
%    dT  Time step
%     d  Data structure with spacecraft model
%     r  ECI frame position
%     q  ECI to body quaternion
%    jD  Julian date
%   See theory book Thermal Chapter, section 8, "Isothermal Model"
%--------------------------------------------------------------------------
function [t, f] = Euler( t, dT, d, r, q, jD)

[uSun, rSun] = SunV1( jD, r );
p       = QForm( q, 1367*uSun );
n       = Eclipse( r, rSun*uSun, [0;0;0] );
flux    = (p'*d.uSurface).*d.area;
j       = flux < 0;
flux(j) = 0;
f       = sum(n*flux);    
tDot    = RHSIsothermalCubeSat( t, 0, d, n*p );
t       = t + dT*tDot;

%--------------------------------------
% $Date: 2020-03-31 14:55:04 -0400 (Tue, 31 Mar 2020) $
% $Revision: 51695 $
