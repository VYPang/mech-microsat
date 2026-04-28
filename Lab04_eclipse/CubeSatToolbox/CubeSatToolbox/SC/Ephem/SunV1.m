function [u, r] = SunV1( jD, rSc )

%% Generate the sun vector in the earth-centered inertial frame. 
%   Low precision formula. Will output the distance to the sun from the 
%   earth if two output arguments are given.
%
%--------------------------------------------------------------------------
%   Form:
%   [u, r] = SunV1( jD, rSc )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD        (1,:)   Julian date
%   rSc       (3,:)   Spacecraft vector in the ECI frame (km)
%
%   -------
%   Outputs
%   -------
%   u         (3,:)   Unit sun vector (vector TO the sun)
%   r         (1,:)   Distance from origin to sun (km)
%
%--------------------------------------------------------------------------
%   References: The 1993 Astronomical Almanac, U.S. Government
%               Printing Office, p. C24.
%               The 2015 Astronomical Almanac, p. C5
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 1.1
%--------------------------------------------------------------------------

if( nargin < 1 )
  jD = [];
end

% Today
if( isempty(jD) )
  jD = Date2JD;
end

% Days from J2000.0
n = jD - 2451545.0;

% Mean anomaly
g    = 357.528 + 0.9856003*n;

% Ecliptic longitude
lam  = rem(280.460 + 0.9856474*n,360) + 1.915*SinD(g) + 0.02*SinD(2*g);

% Obliquity of ecliptic
obOfE  = 23.439 - 4.00e-7*n;

% Equatorial rectangular coordinates of the Sun 
sLam = SinD(lam);

u    = [CosD(lam); CosD(obOfE).*sLam; SinD(obOfE).*sLam];

if ( nargin == 2 || nargout == 2 ),
  r = (1.0014 - 0.01671*CosD(g) - 0.00014*CosD(2*g))*149600e3;
end

% Account for parallax
if ( nargin == 2 )
  u = [r.*u(1,:) - rSc(1,:);...
       r.*u(2,:) - rSc(2,:);...
       r.*u(3,:) - rSc(3,:)];
  r = Mag(u);
  u = Unit(u);
end

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
