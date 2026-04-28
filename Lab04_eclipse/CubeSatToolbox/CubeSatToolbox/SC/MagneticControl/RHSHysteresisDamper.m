function [zDot, p] = RHSHysteresisDamper( x, bECI, bDotECI, d )

%% Right hand side for a dynamical model of magnetic hysteresis.
%   In Kumar p = 1 and q0 = 0. This can be called by RK4 directly.
%
%   Since version 2014.1
%--------------------------------------------------------------------------
%   Form:
%   [zDot, p] = RHSHysteresisDamper( x, bECI, bDotECI, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x                  (:,1) States [r;v;q;w;z]
%   bECI               (3,1) Magnetic field ECI (T)
%   bDotECI            (3,1) Magnetic field derivative (T/s)
%   d                  (1,1) Data structure
%                            .bS (1,1) Saturation flux density (T)
%                            .hC (1,1) Coercive force (A/m)
%                            .bR (1,1) Remanance (T)
%                            .v  (1,:) Volume (m^3)
%                            .u  (3,:) Unit vectors
%
%   -------
%   Outputs
%   -------
%   zDot               (:,1) Derivative of the flux density
%   p                  (1,1) Data structure
%                            .torqueDamper (3,1) Torque (N)
%                            .hMag         (:,1) Magnitude of h in each bar
%                            .hDotMag	     (:,1) Magnitude of h dot in each bar
%
%--------------------------------------------------------------------------
%   See also MagneticHysteresis, TorqueHysteresisDamper
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2014 Princeton Satellite Systems, Inc.
%   All Rights Reserved
%--------------------------------------------------------------------------

% Permeability of free space
%---------------------------
mu0         = 4e-7*pi;

% Damper states
%--------------
q           = x(7:10);
omega       = x(11:13);
z           = x(14:end);
n           = length(z);

% Transformation matrix and its derivative
%-----------------------------------------
c           = Q2Mat( q ); % ECI to body
b           = c*bECI;
bDot        = c*(bDotECI - Skew(c'*omega)*bECI);

p.torqueDamper = zeros(3,1);
p.hDotMag      = zeros(n,1);
p.hMag         = zeros(n,1);
zDot           = zeros(n,1);   

for k = 1:n
  u              = d.u(:,k);
  p.hMag(k)      = Dot(u,b   )/mu0;
  p.hDotMag(k)   = Dot(u,bDot)/mu0;
  zDot(k)        = MagneticHysteresis( z(k), 0, p.hMag(k), p.hDotMag(k), d );
  p.torqueDamper = p.torqueDamper + TorqueHysteresisDamper( u, z(k), d.v(k), b );
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 13:56:08 -0400 (Thu, 11 May 2017) $
% $Revision: 44558 $
