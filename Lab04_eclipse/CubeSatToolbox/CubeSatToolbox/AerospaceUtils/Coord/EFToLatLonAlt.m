function x = EFToLatLonAlt( r, f, a, tol )

%% Convert an earth fixed position vector to [latitude;longitude;altitude]
% Altitude is the distance above the subsatellite point. Assumes an
% ellipsoidal planet.
%--------------------------------------------------------------------------
%   Form:
%   x =  EFToLatLonAlt( r, f, a, tol )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r         (3,:)   Vectors
%   f         (1,1)   Flattening factor*
%   a         (1,1)   Equatorial radius*
%   tol       (1,1)   Tolerance*
%                        * optional
%
%   -------
%   Outputs
%   -------
%   x         (3,:)   [lat (rad); lon (rad); altitude]
%
%--------------------------------------------------------------------------
%   Reference: Vallado, D. A. (1999) Fundamentals of Astrodynamics and 
%              Applications. pp. 204-205.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2000 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 4 )
  tol = [];
end

if( nargin < 3 )
  a   = [];
end

if( nargin < 2 )
  f   = [];
end

if( nargin < 1 )
   m = ECIToEF( JD2T( 2449773.0 ) );
   r = m*[6524.834;6862.875;6448.296];
   r = [r r];
end

if( isempty( tol ) )
  tol = 1e-8;
end

if( isempty( a ) )
  a = 6.378140000000000e+03; % Constant('equatorial radius earth')
end

if( isempty( f ) )
  f = 0.00335281317790; % Constant('earth flattening factor')
end

% The squared planet eccentricity
%--------------------------------
eSq      = f*(2-f);

% Allocate memory for the output
%-------------------------------
x        = zeros(3,size(r,2));

% Longitude
%----------
x(2,:)   = atan2( r(2,:), r(1,:) );

% Latitude
%---------
u        = Unit( r );
rD       = Mag( r(1:2,:) );
phiGdOld = asin( u(3,:) );
phiGd    = phiGdOld;
rK       = r(3,:);
deltaPhi = 1e6;

if( abs(rD) > 0 )

  while( norm(deltaPhi) > tol )
    s        = sin( phiGd );
    c        = a./sqrt(1-eSq*s.^2);
    phiGd    = atan( (rK + eSq*c.*s)./rD );
    deltaPhi = phiGd - phiGdOld;
    phiGdOld = phiGd;
  end

  x(1,:) = phiGd;
  x(3,:) = (rD./cos(phiGd)) - c;
  
else
  x(1,:) = sign(rK)*pi/2;
  x(3,:) = abs(rK) - a*(1-f);
end

%--------------------------------------
% $Date: 2016-05-13 11:31:16 -0400 (Fri, 13 May 2016) $
% $Revision: 42475 $
