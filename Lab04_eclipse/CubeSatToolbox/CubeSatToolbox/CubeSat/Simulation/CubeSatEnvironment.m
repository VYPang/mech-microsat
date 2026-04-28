function env = CubeSatEnvironment( x, t, d )

%% Environment calculations for the CubeSat dynamical model.
%
% Uses the J70 atmosphere model or AtmDens2 if the data required by J70 is
% absent. Computes sun location with SunV1 and accounts for eclipses from the
% Earth via Eclipse. All environment constants including gravity are defined
% here.
%--------------------------------------------------------------------------
%   Form:
%   e = CubeSatEnvironment             % data structure
%   e = CubeSatEnvironment( x, t, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x        (14,1)    [r;v;q;w;b]
%   t         (1,1)    Time, sec
%   d          (.)     Data structure
%                      .jD0          Julian date of epoch
%                      .att      (.) Attitude
%                      .atm      (.) optional; empty to skip J70 and use AtmDens2
%                      .surfData (.) optional; empty to skip drag/optical calcs
%
%   -------
%   Outputs
%   -------
%   env        (.)     Environmental data
%                      .r            ECI position (km)
%                      .v            ECI velocity (km/s)
%                      .q            ECI to body quaternion
%                      .mu           Gravitational constant (km3/s2)
%                      .planetRadius Radius of the planet (km)
%                      .vRel         Velocity relative to the atmosphere (km/s)
%                      .rho          Atmospheric density (kg/m3)
%                      .radiation    Planetary radiation W/m2
%                      .albedo       Planet bond albedo fraction
%                      .uSun         Sun unit vector (ECI)
%                      .rSun         Sun distance (km)
%                      .solarFlux    Solar flux at position (W/m2)
%                      .nEcl         Eclipse fraction (source intensity, 0-1)
%                      .bField       Magnetic field (T)
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

persistent AU SOLAR_FLUX SKEW_OMEGA_EARTH

% First look up constants if needed
if isempty(AU)
  AU = 149597870;  % km
end
if isempty(SOLAR_FLUX)
  SOLAR_FLUX = 1367; % W/m2 at 1 AU
end
if isempty(SKEW_OMEGA_EARTH)
  SKEW_OMEGA_EARTH = Skew([0;0;7.291e-5]);
end

% Data structure to fill in
%--------------------------
env = DefaultStruct;

% Get the states
%---------------
r      = x(1:3); % ECI frame
v      = x(4:6);
if ~isempty(d.surfData)
  d.surfData.att.qECIToBody = x(7:10);
  q = CubeSatAttitude( d.surfData.att, r, v );
else
  q = [];
end

% Julian date
%------------
jD     = d.jD0 + t/86400;

% Sun vector and distance - account for location in Earth orbit
%------------------------
[uSun, rSun] = SunV1( jD );
nEcl         = Eclipse( r, uSun*rSun);
flux         = SOLAR_FLUX/(rSun/AU)^2;

% Magnetic field
%---------------
env.bField = BDipole( r, jD );

rho = 0;
vRel = v;
if( ~isempty(d.surfData) )
	% Find the perturbing acceleration due the atmosphere
	%----------------------------------------------------
  if isempty(d.atm)  
    rho = AtmDens2(Mag(r)-env.radiusPlanet);
  else
    dAtm      = d.atm;
    dAtm.rECI = r;
    dAtm.jD   = jD;
    rho       = AtmJ70( dAtm )*1000;
  end
  
  % Adjust velocity for Earth rotation
  %-----------------------------------
	cECIToEF = ECIToEF( JD2T(jD) );
  rEF = cECIToEF*r;
	vRel = v - cECIToEF'*SKEW_OMEGA_EARTH*rEF; % Account for earth rotation

end

% Store in the structure format
%------------------------------
env.r    = r;
env.v    = v;
env.q    = q;
env.uSun = uSun;
env.rSun = rSun;
env.solarFlux = flux; 
env.rho  = rho;
env.vRel = vRel;
env.nEcl = nEcl;

%--------------------------------------------------------------------------
% Default data structure
%--------------------------------------------------------------------------
function d = DefaultStruct

d           = struct;
d.r         = [7000;0;0];
d.v         = [0;7;0];
d.q         = [];
d.mu        = 3.98600436e5; % km3/s2
d.radiusPlanet = 6378.1; % km
d.vRel      = [0;6.5;0];
d.rho       = 0;
d.radiation = 429.41;  % W/m2
d.albedo    = 0.39;    % fraction
d.uSun      = [1;0;0];
d.rSun      = 149597870;
d.solarFlux = 1367;    % W/m2 at 1 AU
d.nEcl      = 1;
d.bField    = [1;0;0];

%--------------------------------------
% $Date: 2019-09-07 14:57:11 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49731 $
