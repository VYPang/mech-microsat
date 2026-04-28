function r = LatLonAltToEF( x, f, a )

%% Convert [latitude;longitude;altitude] to an earth fixed position vector.
% Altitude is the distance above the subsatellite point. Assumes an
% ellipsoidal planet.
%
% Type LatLonAltToEF for a demo.
%--------------------------------------------------------------------------
%   Form:
%   r = LatLonAltToEF( x, f, a )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x         (3,:)   [lat (rad); lon (rad); altitude (km)]
%   f         (1,1)   Flattening factor
%   a         (1,1)   Equatorial radius
%   tol       (1,1)   Tolerance
%
%   -------
%   Outputs
%   -------
%   r         (3,:)   Vectors
%
%--------------------------------------------------------------------------
%   Reference: Escobal, P. Methods of Orbit Determination.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2000 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 3 )
  a   = [];
end

if( nargin < 2 )
  f   = [];
end

if( nargin < 1 )
  x = [0.59956414878627;1.26628752143138;5085.215739382978];
  x = [x x];
end

if( isempty( a ) )
  a = Constant('equatorial radius earth');
end

if( isempty( f ) )
  f = Constant('earth flattening factor');
end

% The squared planet eccentricity
%--------------------------------
eSq      = f*(2-f);

% Latitude
%----------
sPhi     = sin( x(1,:) );
d        = sqrt( 1 - eSq*sPhi.^2 );

xC       = (        a./d + x(3,:)).*cos(x(1,:));
zC       = ((1-eSq)*a./d + x(3,:)).*sPhi;

% Longitude
%----------
c        = cos( x(2,:) );
s        = sin( x(2,:) );

r        = [xC.*c;xC.*s;zC];

%--------------------------------------
% $Date: 2016-07-09 18:51:35 -0400 (Sat, 09 Jul 2016) $
% $Revision: 42793 $
