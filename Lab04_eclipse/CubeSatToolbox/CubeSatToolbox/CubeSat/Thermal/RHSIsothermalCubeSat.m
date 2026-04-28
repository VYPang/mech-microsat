function [tDot, Teq] = RHSIsothermalCubeSat( t0, ~, d, p )

%% An isothermal CubeSat model dynamical right-hand-side.
% The entire spacecraft is assumed to be at the same temperature.
% p should be the net input vector and include sun, albedo and earth 
% radiation. You should also factor in eclipses.  The total power is the 
% internal power that is absorbed by the spacecraft. The specific heat is
% the average over the whole spacecraft. If mass is a vector it will
% compute temperatures separately for each face. An optional matrix
% k provides face thermal conductivities. For multiple faces, 
% internal power is per face. 
%
% If there are no output arguments the demo will plot the equilibrium
% temperature.
%
%--------------------------------------------------------------------------
%   Form:
%   RHSIsothermalCubeSat -- demo
%   d = RHSIsothermalCubeSat -- default data structure
%   [tDot, Teq] = RHSIsothermalCubeSat( t0, t, d, p )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   t0     (1,6) or (1,1) Temperature of faces or total temperature
%   t      (1,1)     Time (unused)
%   d      (1,1)     Data structure
%                    .mass       (1,6) or (1,1) face masss or total mass
%                    .uSurface   (3,6) Surface unit vectors
%                    .alpha      (1,6) Absorptivity
%                    .epsilon    (1,6) Emissivity
%                    .area       (1,6) Area
%                    .cP         (1,1) Specific heat
%                    .powerTotal (1,6) or (1,1) Internal power (W)
%                    .k          (6,6) Thermal conductivity (W/deg-K)
%   p      (3,:)     Thermal flux in the body frame (W/m2)
%
%   -------
%   Outputs
%   -------
%   tDot     (:,6) or (1,:) Temperature derivative of faces or total
%   Teq      (:,6) or (1,:) Equilibrium temperature of faces or total
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2014, 2019 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d = DataStructure;
  if nargout == 1
    tDot = d;
    return;
  end
  d.mass       = 1;
  d.uSurface   = [1 -1 0 0 0 0;0 0 1 -1 0 0;0 0 0 0 1 -1];
  d.alpha      = [0.8  0.8  0.15 0.3  0.3  0.15];
  d.epsilon    = [0.82 0.82 0.8  0.04 0.04 0.8];
  d.area       = 0.1*0.1*ones(1,6);
  d.cP         = 900;
  d.powerTotal = 8;
  n            = 200;
  angle        = linspace(0,2*pi,n);
  RHSIsothermalCubeSat( 0, 0, d, 1367*[zeros(1,n);sin(angle);cos(angle)]);
  return
end

% Initialize
%-----------
[~,n] = size(p);
calcTeq = 0;
Teq  = zeros(1,n);
tDot = zeros(1,n);
if( nargout == 0 || nargout == 2 )
  calcTeq = 1;
end

% Boltzmann constant
%-------------------
sigma = 5.67e-8;

m = length(d.mass);

if( m == 1 )
  for k = 1:n
    flux    = p(:,k)'*d.uSurface;
    j       = flux < 0;
    flux(j) = 0;
    netIn   = sum(flux.*d.alpha.*d.area) + d.powerTotal;
    f       = sigma*sum(d.epsilon.*d.area);
    netOut  = f*t0.^4;
    if( calcTeq )
      Teq(k) = (netIn/f)^0.25;
    end
    tDot(k) = (netIn - netOut)/(d.cP*d.mass);
  end
else
  tDot = zeros(size(p,2),6);
  for k = 1:n
    flux        = p(:,k)'*d.uSurface;
    j           = flux < 0;
    flux(j)     = 0;
    netIn       = flux.*d.alpha.*d.area + d.powerTotal;
    f           = sigma*d.epsilon.*d.area;
    netOut      = f'.*t0'.^4;
    tDot(k,:)   = ((netIn' - netOut - d.k*t0')./(d.cP*d.mass'))';
  end
end

% Default output
%---------------
if( nargout < 1 )
  Plot2D( (0:(n-1)), Teq, 'Sample', 'T (deg-K)', 'Equilibrium temperature');
end
    
%--------------------------------------------------------------------------
% Default data structure
%--------------------------------------------------------------------------
function d = DataStructure

[~,n,~] = CubeSatFaces('1U',1);

d.mass       = 1;
d.uSurface   = n;
x = 0.75;  y = 0.3; % Solar panel
a = 0.8;   b = 0.1; % Gold foil
d.alpha      = [x  x  a  x  x  a];
d.epsilon    = [y  y  b  y  y  b];
d.area       = a;
d.cP         = 900;
d.powerTotal = 1;
d.k          = zeros(6,6);

%--------------------------------------
% $Date: 2020-03-31 14:55:04 -0400 (Tue, 31 Mar 2020) $
% $Revision: 51695 $
