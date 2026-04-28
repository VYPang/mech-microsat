function [u, r] = MoonV1( jd, rSc )

%% Generate the moon vector in an earth or spacecraft centered frame.
%   The earth-centered inertial frame is default or, if a spacecraft vector is 
%   input, the vector is in the spacecraft centered frame. 
%   This is the low precision model. 
%   See also MoonV2.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   [u, r] = MoonV1( jd, rSc )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jd        (:)     Julian date
%   rsc       (:)     Spacecraft vector in the ECI frame (km)
%
%   -------
%   Outputs
%   -------
%   u         (3,:)   Unit moon vector
%   r         (:)     Distance from origin to moon (km) 
%
%--------------------------------------------------------------------------
%	References:	  The 1993 Astronomical Almanac, U.S. Government Printing
%                Office, p. D46. 
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  jd = Date2JD;
end

% Days from J2000.0

T = (jd - 2451545.0)/36525;

% Ecliptic longitude

lam = 218.32 + 481267.883*T + 6.29*SinD(134.9+477198.85*T) - 1.27*SinD(259.2-413335.38*T) + .66*SinD(235.7+890534.23*T)+0.21*SinD(269.9+954397.70*T)-0.19*SinD(357.5+35999.05*T) - 0.11*SinD(186.6+966404.05*T);

% Ecliptic latitude

beta = 5.13*SinD(93.3+483202.03*T) + 0.28*SinD(228.2+960400.87*T) - 0.28*SinD(318.3+6003.18*T)-0.17*SinD(217.6-407332.20*T);

% The unit vector

cb = CosD(beta);
sb = SinD(beta);
cl = CosD(lam);
sl = SinD(lam);

u = [cb.*cl;0.91748*cb.*sl-0.39778*sb;0.39778*cb.*sl+0.91748*sb];

if ( nargin == 2 || nargout == 2 ),
  p = 0.9508 + 0.0518*CosD(134.9+477198.85*T)+0.0095*CosD(259.2-413335.38*T)+0.0078*CosD(235.7+890534.23*T)+0.0028*CosD(269.9+954397.70*T); 
  r = 6378.137./SinD(p);
end


% Account for parallax
%---------------------
if ( nargin == 2 ),
  u = [r.*u(1,:) - rSc(1,:);...
       r.*u(2,:) - rSc(2,:);...
       r.*u(3,:) - rSc(3,:)];
  r = Mag(u);
  u = Unit(u);
end


% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
  
