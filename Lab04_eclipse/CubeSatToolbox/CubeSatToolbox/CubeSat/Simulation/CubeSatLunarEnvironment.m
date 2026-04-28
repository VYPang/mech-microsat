function env = CubeSatLunarEnvironment( x, t, d )

%% Lunar environment calculations for the CubeSat dynamical model.
%
% Computes sun location with SunV1 and accounts for eclipses from the Earth and
% the Moon via Eclipse. All environment constants including gravity are defined
% here.
%--------------------------------------------------------------------------
%   Form:
%   e = CubeSatLunarEnvironment             % data structure
%   e = CubeSatLunarEnvironment( x, t, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x        (14,1)    [r;v;q;w;b]
%   t         (1,1)    Time, sec
%   d          (.)     Data structure
%                      .jD0          Julian date of epoch
%                      .surfData (.) optional; empty to skip optical calcs
%                      .gravity  (.) 
%                           .center  Index of gravity center
%
%   -------
%   Outputs
%   -------
%   env        (.)     Environmental data
%                      .r            ECI position (km)
%                      .v            ECI velocity (km/s)
%                      .q            ECI to body quaternion
%                      .mu           Gravitational constant (km3/s2)
%                      .radiusPlanet Radius of the center planet (km)
%                      .rho          Distance from the Moon (km)
%                      .radiation    Planetary radiation W/m2
%                      .albedo       Planet bond albedo fraction
%                      .uSun         Sun unit vector (ECI)
%                      .rSun         Sun distance (km)
%                      .solarFlux    Solar flux at position (W/m2)
%                      .nEcl         Eclipse fraction (source intensity, 0-1)
%                      .accelGrav    Acceleration due to gravity
%                      .rMoon        Moon position
%                      .vMoon        Moon velocity
% 
%--------------------------------------------------------------------------
%   See also SunV1, Eclipse, AtmDens2, AtmJ70, BDipole
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1.
%--------------------------------------------------------------------------

if nargin == 0
  env = DefaultStruct;
  return;
end

persistent AU SOLAR_FLUX ALBEDO RADIATION RADIUS_MOON RADIUS_EARTH

% First look up constants if needed
if isempty(AU)
  AU = 149597870;  % km
end
if isempty(SOLAR_FLUX)
  SOLAR_FLUX = 1367; % W/m2 at 1 AU
end
if isempty(ALBEDO)
  ALBEDO = [0.39 0.067]; % fraction [earth moon]
end
if isempty(RADIATION)
  RADIATION = [429.41 6.63309804]; % W/m2 [earth moon]
end
if isempty(RADIUS_MOON)
  RADIUS_MOON = 1738; % km
end
if isempty(RADIUS_EARTH)
  RADIUS_EARTH = 6378.1; % km
end

% Data structure to fill in
%--------------------------
env = DefaultStruct;

% Get the states
%---------------
rECI  = x(1:3); % ECI frame
vECI  = x(4:6);
if ~isempty(d.surfData)
  d.surfData.att.qECIToBody = x(7:10);
  q = CubeSatAttitude( d.surfData.att, rECI, vECI );
else
  q = [];
end

% Julian date
%------------
jD     = d.jD0 + t/86400;

% Ephemeris
%----------
% Column 1: sun
% Column 2: Earth
% Column 3: Geocentric moon
% rho(:,1): vector to the sun
[rP, mu, vP]	= PlanetPosJPL( 'update', jD );
kEarth = 0;
if( d.gravity.center == kEarth )
  rho = [rP(:,1)-rP(:,2) rP(:,3)];
  accelGrav = APlanet( rECI, mu([1 3]), rho ) - mu(2)*rECI/Mag(rECI)^3;
  env.radiusPlanet = RADIUS_EARTH;
  env.radiation = RADIATION(1);
  env.albedo = ALBEDO(1);
else
  % center is the moon
  rho = [rP(:,1)-rP(:,2)-rP(:,3) -rP(:,3)];
  if( isempty(d.sphHarmMoon) )
    accelGrav	= APlanet( rECI, mu(1:2), rho ) - mu(3)*rECI/Mag(rECI)^3;
  else
    bECIToMoon	= MoonRot( jD );   
    accelMoon   = GravityNormalized( bECIToMoon*rho, d.sphHarmMoon );
    accelGrav   = APlanet( rECI, mu(1:2), rho ) - bECIToMoon'*accelMoon;
  end
  env.radiusPlanet = RADIUS_MOON;
  env.radiation = RADIATION(2);
  env.albedo = ALBEDO(2);
end

% Sun vector and distance - account for location in Earth/Moon system
%------------------------
uSun = Unit(rho(:,1));
rSun = Mag(rho(:,1));
if( d.gravity.center == kEarth )
  n1  = Eclipse(rECI,rho(:,1),[0;0;0],RADIUS_EARTH);
  n2  = Eclipse(rECI,rho(:,1),rho(:,2),RADIUS_MOON);
else
  n1  = Eclipse(rECI,rho(:,1),[0;0;0],RADIUS_MOON);
  n2  = Eclipse(rECI,rho(:,1),rho(:,2),RADIUS_EARTH);
end
nEcl = n1*n2;
flux = SOLAR_FLUX/(rSun/AU)^2;

% Store in the structure format
%------------------------------
env.r    = rECI;
env.v    = vECI;
env.uSun = uSun;
env.rSun = rSun;
env.solarFlux = flux; 
env.nEcl = nEcl;
env.accelGrav = accelGrav;
env.rMoon = rP(:,3);
env.vMoon = vP(:,3);

%--------------------------------------------------------------------------
% Default data structure
%--------------------------------------------------------------------------
function d = DefaultStruct

% These will be adjusted during update calls
d           = struct;
d.r         = [7000;0;0];
d.v         = [0;7;0];
d.q         = [];
d.rMoon     = [0;0;0];
d.vMoon     = [0;0;0];
d.uSun      = [1;0;0];
d.rSun      = 149597870;
d.solarFlux = 1367;    % W/m2 at 1 AU
d.nEcl      = 1;
d.accelGrav = [0;0;0];
d.radiusPlanet = 6378.1; % km
d.radiation   = 0;       % W/m2
d.albedo      = 0;       % fraction


%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
