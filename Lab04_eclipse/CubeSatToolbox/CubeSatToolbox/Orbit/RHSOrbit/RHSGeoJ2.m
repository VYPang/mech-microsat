function xDot = RHSGeoJ2( x, t, d )

%% Computes the right hand side for Earth gravity with J2.
% Uses a local version of AGravityC that explicitly uses only the J2 term.
%--------------------------------------------------------------------------
%   Form:
%   xDot = RHSGeoJ2( x, t, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x           (6,1)    Position vector [rECI (km); vECI (km)];
%   t           (1,1)    Time since start Julian Date (s) 
%   d            (.)     Gravity model struct
%                        .j2    (1,2)	J2 term (unnormalized and positive)
%                        .mu    (1,1)	Spherical gravitational potential
%                        .a     (1,1)	Planet radius
%                        .jD0	  (1,1) Start Julian Date    
%
%   -------
%   Outputs
%   -------
%   xDot        (6,1)   [rDot;vDot]
%
%--------------------------------------------------------------------------
% See also: ECIToEF, RHSGeoGarm
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	 Copyright (c) 2011 Princeton Satellite Systems, Inc.
%    All rights reserved.
%   Since version 2014.
%--------------------------------------------------------------------------

if( nargin < 1 )
  x  = [6.935199226610737e+03; 6.935199226610738e+03; 1.950903220161282e+03;0;0;0];
  t  = 0;
  xDot = RHSGeoJ2( x, t );
  return;
end

if nargin < 3
  % GEM-T1 coefficients
  d.j2  = [0.00108262563430956]; % unnormalized value
  d.a   = 6378.137;
  d.mu  = 398600.436;
  d.jD0 = 2451545;
end

jD       = d.jD0 + t/86400;
mECIToEF = ECIToEF( JD2T( jD ) );

rEF = mECIToEF*x(1:3);

[aG, aS, aZ] = AGravityC( rEF, d );

xDot = [x(4:6);mECIToEF'*aG];

if( nargout == 0 )
  aG
  aS
  aZ
end

%--------------------------------------------------------------------------
%   Compute the gravitational acceleration in cartesian coordinates. 
%   Acceleration vectors are a [ aX;aY;aZ ].
%--------------------------------------------------------------------------
%	 Reference: Bond, V. R. and M. C. Allman (1996.) Modern Astrodynamics.
%               Princeton. pp. 212-213.
%--------------------------------------------------------------------------
function [aG, aS, aZ] = AGravityC( r, d )

% Lump the j terms into c
%------------------------
% coefficients from EGM2008
c = [0 0 0; -d.j2 -2.66739475237484e-10 1.57461532572292e-06]; % unnormalized
s = [0 0; 1.78727064852404e-09 -9.03872789196567e-07];
s = [[0;0] s];
nN = 2;
nM = 0;

rMagSq    = r'*r;
rMag      = sqrt(rMagSq);
u         = r/rMag;
aOR       = d.a/rMag;
nu        = u(3);
  
% C and S Hat are functions of r only
%------------------------------------
cHat = [1 u(1)];
sHat = [0 u(2)];

% p(n,m) is a function of nu only
%--------------------------------
p      = zeros(nN+1,nM+2);
p(1,1) = 1;
p(2,1) = nu;
p(1,2) = 0;
p(2,2) = 1;  
p(3,1) = (3*nu*p(2,1) - p(1,1))/2;
p(3,2) = p(1,2) + 3*p(2,1);

dVMZ = [0;0;0];

% m = 0
%------
cS      = c(2,1)*cHat(1) + s(2,1)*sHat(1);
hNM     =        cS*p(3,2);
bNM     = 3*cS*p(3,1);
dVM     = -u*(nu*hNM + bNM) + [0;0;hNM];
dVMZ    = dVMZ + dVM*aOR^2;

aZ   =  d.mu*dVMZ/rMagSq;
aS   = -d.mu*u/rMagSq;
aG   = aS + aZ;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2020-05-12 16:28:55 -0400 (Tue, 12 May 2020) $
% $Revision: 52219 $
