function [aG, aS, aZ, aT] = AGravity( nZ, nT, r, lambda, theta, s, c, j, mu, a )

%% Compute the gravitational acceleration in spherical coordinates. 
% Acceleration vectors are a [ a(r), a(lambda), a(theta) ].
% The coefficients should be unnormalized. If they are not the function will
% throw a warning and unnormalize them.
%
%   [s, c, j, mu, a] = LoadGEM( 1 )
%
%   for k = 1:kMax
%     [a, aS, aZ, aT] = AGravity( nZ, nT, r, lambda, theta, s, c, j, mu, a );
%   end
%
%   than
%
%   for k = 1:kMax
%     [a, aS, aZ, aT] = AGravity( nZ, nT, r, lambda, theta );
%   end
%
%--------------------------------------------------------------------------
%   Form:
%   [aG, aS, aZ, aT] = AGravity( nZ, nT, r, lambda, theta, d )
%   [aG, aS, aZ, aT] = AGravity( nZ, nT, r, lambda, theta, s, c, j, mu, a )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   nZ                   Highest zonal harmonic (m = 0) (empty gives the max #) 
%   nT                   Highest sectorial and tesseral harmonic (empty gives the max #) 
%   r                    Radius
%   lambda               Equatorial angle
%   theta                Angle from pole
%   d            (.)     Gravity model struct
%      -or-
%   s           (:,:)    S terms
%   c           (:,:)    C terms
%   j              (:)   m = 0 terms
%   mu                   Spherical gravitational potential
%   a                    Earth radius
%
%   -------
%   Outputs
%   -------
%   aG           (3,1)   Total gravitational acceleration km/sec^2
%   aS           (3,1)   Spherical term                   km/sec^2
%   aZ           (3,1)   Zonal term                       km/sec^2
%   aT           (3,1)   Tesseral term                    km/sec^2
%
%--------------------------------------------------------------------------
%   See also AGravityC, PDAL, SCHarm
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 1996 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2019.1 Add gravity struct input
%--------------------------------------------------------------------------

if( nargin < 6 )
  s = LoadGEM( 1 );
end
if isstruct(s)
  gM = s;
  if gM.isNormalized
    warning('Gravity coefficients should be unnormalized');
    gM = UnnormalizeGravity( gM );
  end
  s  = gM.s;
  c  = gM.c;
  j  = gM.j;
  mu = gM.mu;
  a  = gM.a;
end

if( isempty( nZ ) )
  nZ = size(s,1);
end

if( isempty( nT ) )
  nT = size(s,2);
end

if ( r == 0 )
  aG = [ 0 0 0 ]';
  aS = [ 0 0 0 ]';
  aZ = [ 0 0 0 ]';
  aT = [ 0 0 0 ]';
  return
end

% Spherical gravity radial term
%------------------------------
muORSq = mu/r^2;

% Set up the vectors and compute the spherical earth acceleration vector
%-----------------------------------------------------------------------
aS = [ -muORSq; 0; 0 ];
aZ = [ 0; 0; 0 ];
aT = [ 0; 0; 0 ];

% Return if only the spherical earth model is requested
%------------------------------------------------------
if( nZ == 0 && nT == 0 )
  aG = aS;
  return;
end

% Compute powers of a/r
%----------------------
zTMax = max(nZ,nT);
aOR   = zeros(1,zTMax);
aORK  = zeros(1,zTMax);

aOR(1)  = a/r;
aORK(1) = 2*aOR(1);
for n = 2:zTMax
  aOR (n) =       aOR(n-1)*aOR(1);
  aORK(n) = (n+1)*aOR(n);
end
aORK = -aORK;

% PDAL returns p(n+1,m+1)
%------------------------
sTheta  = sin(theta);
[p, pD] = PDAL( zTMax, nT, cos(theta), -sTheta );
rZ      = 2:(nZ+1);

% Compute the zonal accelerations
%--------------------------------
aZ  = muORSq*[ sum( aORK(1:nZ).*j(1:nZ).* p(rZ,1)');...
               0;...
               sum(  aOR(1:nZ).*j(1:nZ).*pD(rZ,1)')];

% Compute the tesseral and sectorial accelerations
%-------------------------------------------------
rP      = 2:(nT+1);
p       =  p(rP,rP);
pD      = pD(rP,rP);

% sin(m*lambda), cos(m*lambda)
%-----------------------------
if( nT > 0 )
  [sL, cL] = SCHarm( lambda, nT );
end

% Sum over n
%-----------
for n = 1:nT
  m  = 1:n;
  cS = c(n,m).*cL(m) + s(n,m).*sL(m);
  aT = aT + [ aORK(n)*sum(p(n,m).*cS); 0; aOR(n)*sum(pD(n,m).*cS) ];
  if( sTheta ~= 0 )
  	cS    = m.*(s(n,m).*cL(m) - c(n,m).*sL(m));
    aT(2) = aT(2) + aOR(n)*sum(p(n,m).*cS)/sTheta;
  end
end

aT = muORSq*aT;

% Total acceleration
%-------------------
aG = aS + aZ + aT;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2019-12-16 15:58:34 -0500 (Mon, 16 Dec 2019) $
% $Revision: 50603 $
