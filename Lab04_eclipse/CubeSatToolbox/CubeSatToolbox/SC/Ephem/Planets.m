function [name, a, e, i, W, w, L, jDRef, mu, m, radius] = Planets( units, k )

%% Simplified planet ephemerides from the almanac.
%   Has functions for the orbital elements of the planets in the 
%   heliocentric frame. The elements are row vectors as follows:
%
%   a = [   a1 a0] semi-major axis
%   e = [   e1 e0] eccentricity
%   i = [   i1 i0] inclination
%   W = [   W1 W0] longitude of the ascending node
%   w = [   w1 w0] argument of perigee
%   L = [L2 L1 L0] mean longitude: L2 is revolutions per century
%
%   where
%
%   x = b1*T + b0 where T is Julian Centuries from J2000.0
%
%   and bi is a coefficient. Output of the angular quantities is
%   either in degrees or radians.
%
%   If one output is specified it will be a data structure containing
%   the planet information.
%
%   Type Planets for a demo. See SolarSys for computing planet locations.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   Planets;               % demo
%   planetList = Planets;  % list of planets
%   [name, a, e, i, W, w, L, jDRef, mu, m, radius] = Planets( units, k )
%   d = Planets( units, k )  % output a data structure array
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   units           (1,3) Angular units ('deg' or 'rad')
%   k         (1,1) or {} Planet IDs, if not input get all nine;
%                         can be a cell array
%
%   -------
%   Outputs
%   -------
%   name            (n,:) Name of planet
%   a               (n,2) Mean distance (au)
%   e               (n,2) Eccentricity
%   i               (n,2) Inclination wrt ecliptic plane (units)
%   W               (n,2) Longitude of ascending node wrt vernal equinox (units)
%   w               (n,2) Argument of perhelion (units)
%   L               (n,3) Mean longitude (units)
%   jDRef           (1,1) Reference Julian date
%   mu              (n,2) Gravitational parameter (km^3/s^2)
%   m               (n,1) Mass  (kg)
%   radius          (n,1) Radius (km)
%     - OR -
%   d                (:)  Data structure array with above fields
% 
%                    n is the number of planets
%
%--------------------------------------------------------------------------
% References:  Seidelmann, P. K., ed., Explanatory Supplement to the Astronomical
%              Almanac, University Science Books, 1992.
%              Table 5.8.1. p. 316.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2002, 2013, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   2013: allow struct output
%   2016: update demo to use struct
%--------------------------------------------------------------------------

%% Demo
if( nargin < 1 )
  if nargout == 1
    name = PlanetList;
    return;
  end
  % Plots the paths of the planets using simplified ephemerides. These are 
  % suitable for testing control and navigation systems but not for real
  % mission planning.
  units = 'rad';
  Planets(units);
  k = 2:4;
  dP = Planets(units,k); 
  SolarSys(dP)
  return;
end

if ( nargin < 2 )
  k = 1:9;
  [name,a,e,i,W,w,L,jDRef,mu,m,radius] = Planets(units,k); 
  return; 
end

%%
if( ischar(k) || iscell(k) )
  planets = PlanetList;
  if( ischar(k) )
    c = {k};
  else
    c = k;
  end
  k = [];
  for j = 1:length(c)
    k = [k strmatch(lower(c{j}),planets)];
  end
end

% Name

named(1,:) = 'Mercury';
named(2,:) = 'Venus  ';
named(3,:) = 'Earth  ';
named(4,:) = 'Mars   ';
named(5,:) = 'Jupiter';
named(6,:) = 'Saturn ';
named(7,:) = 'Uranus ';
named(8,:) = 'Neptune';
named(9,:) = 'Pluto  ';

% Reference date

jDRef = 2451545;

% Elements:        [a e i W w L]
% Delta elements : [da de di dW dw dL]
% Last number is orbits per century

% Elements matrix
%----------------
ke(1,:)  = [ 0.38709893 0.20563069  7.00487  48.33167  77.45645 252.25084];
ke(2,:)  = [ 0.72333199 0.00677323  3.39471  76.68069 131.53298 181.97973];
ke(3,:)  = [ 1.00000011 0.01671022  5e-5    -11.26064 102.94719 100.46435];
ke(4,:)  = [ 1.52366231 0.09341233  1.85061  49.57854 336.04084 355.45332];
ke(5,:)  = [ 5.20336301 0.04839266  1.3053  100.55615  14.75385  34.40438];
ke(6,:)  = [ 9.53707032 0.0541506   2.48446 113.71504  92.43194  49.94432];
ke(7,:)  = [19.19126393 0.04716771  0.76986  74.22988 170.96424 313.23218];
ke(8,:)  = [30.06896348 0.00858587  1.76917 131.72169  44.97135 304.88003];
ke(9,:)  = [39.48168677 0.24880766 17.14175 110.30347 224.06676 238.92881];

dke(1,:) = [ 6.6e-7      2.527e-5  -23.51   -446.3    573.57  261628.29 415];
dke(2,:) = [ 9.2e-7     -4.938e-5   -2.86   -996.89  -108.8   712136.06 162];
dke(3,:) = [-5e-8       -3.804e-5  -46.94 -18228.25  1198.28 1293740.63  99];
dke(4,:) = [-7.221e-5    1.1902e-4 -25.47  -1020.19  1560.78  217103.78  53];
dke(5,:) = [ 6.0737e-4  -1.288e-4   -4.15   1217.17   838.93  557078.35   8];
dke(6,:) = [-0.0030153  -0.00036762  6.11  -1591.05 -1948.89  513052.95   3];
dke(7,:) = [ 0.00152025 -1.915e-4   -2.09   1681.4   1312.56  246547.79   1];
dke(8,:) = [-0.00125196  2.514e-5   -3.64   -151.25  -844.43  786449.21   0];
dke(9,:) = [-7.6912e-4   6.465e-5   11.07    -37.33  -132.25  522747.9    0]; 

% Convert from arcseconds per century to deg/century
%---------------------------------------------------
dke(:,1:6) = dke(:,1:6)/3600;

% Mass
%-----
md     = [0.33022 4.869 5.9742 0.64191 1898.8 568.5 86.625 102.78 0.015]*1e24;
mud    = 6.672e-20*md;
radius = [2439.7 6051.9 6378.14 3397 71492 60268 25559 24764 1151]';


% Angular units conversion
%-------------------------
if ( units == 'rad' ),
  conversion = pi/180;
else
  conversion = 1.0;
end

name   = named(k,:);
a      = [          ke(k,1) dke(k,1)];
e      = [          ke(k,2) dke(k,2)];
i      = [          ke(k,3) dke(k,3)]*conversion;
W      = [          ke(k,4) dke(k,4)]*conversion;
w      = [          ke(k,5) dke(k,5)]*conversion;
L      = [dke(k,7) [ke(k,6) dke(k,6)]*conversion];
m      = md(k)';
mu     = mud(k)';
radius = radius(k)';

% Output a data structure
%------------------------
if( nargout == 1 )
  d.name    = name;
  d.a       = a;
  d.e       = e;
  d.i       = i;
  d.W       = W;
  d.w       = w;
  d.L       = L;
  d.m       = m;
  d.mu      = mu;
  d.jDRef   = jDRef;
  d.radius	= radius;
  name      = d;
end

function planets = PlanetList

planets = {'mercury' 'venus' 'earth' 'mars' 'jupiter' 'saturn' 'uranus' 'neptune' 'pluto'};

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
