function xDot = FOrbitMultiSpacecraft( t, x, d )

%% Multispacecraft orbit model designed to work with ode113.
% You can include aerodynamic, radiation pressure and thrust models. Sun,
% earth, and moon perturbations are computed if the planet (Earth or
% Moon) is given. Uses SunV1 and MoonV1 for ephemeris. 
%--------------------------------------------------------------------------
%   Form:
%      d = FOrbitMultiSpacecraft             % data structure
%   xDot = FOrbitMultiSpacecraft( t, x, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   t                Time
%   x       (7*n,1)  The state vector [r1;v1;m1;r2;v2;m2;...]
%   d       (:)      Data structure array
%                    .jD0                       (1,1)   Julian date at start
%
%                    This is only needed for planetary disturbances
%                    and if a gravity model is entered:
%
%                    .planet                   (1,:)   Planet name, 'earth', 'moon'
%
%                    These are optional:
%
%                    .thrusterModel            (1,:)   Thrust function handle
%                    .thrusterData             (.)     Thrust data structure
%                    .opticalModel             (1,:)   Optical function handle
%                    .aeroModel                (1,:)   Aero function handle
%                    .surfData                 (.)     Surface data structure
%                    .gravityModel             (.)     Gravity model structure;
%                                                        default is point-mass.
%                    The following are only needed if you want J70, otherwise
%                    AtmDens2 will be used.
%
%                    .atm.aP                   (1,1)   Geomagnetic index 6.7 hours before the computation
%                    .atm.f                    (1,1)   Daily 10.7 cm solar flux (e-22 watts/m^2/cycle/sec)
%                    .atm.fHat                 (1,1)   81-day mean of f (e-22 watts/m^2/cycle/sec)
%                    .atm.fHat400              (1,1)   fHat 400 days before computation date
%
%   -------
%   Outputs
%   -------
%   xDot    (7*n,1)  The state vector derivative [v1;r1Dot;m1Dot...]
%
%--------------------------------------------------------------------------
%   See also CubeSatEnvironment, ECIToPlanet, AGravityC, FOrbCart,
%   PlanetaryAccelerations CubeSatRadiationPressure, CubeSatAero,
%   CubeSatPropulsion
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-2000, 2009, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8. 
%   2016.1 Update to make structure consistent with RHSCubeSat.
%   Add default structure function and a local environment function which can be
%   optimized. Also a local BDipole to avoid calculating cECItoEF twice.
%   2019.1 Fixed BUG that would prevent a full gravity model from running. It
%   will now use all terms in the loaded gravity model.
%--------------------------------------------------------------------------

if nargin < 1
  xDot = DefaultStruct;
  return;
end

persistent AU SOLAR_FLUX SKEW_OMEGA_EARTH MU ALBEDO RADIATION RADIUS_MOON RADIUS_EARTH

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
if( isempty(MU) )
  MU(1) = Constant( 'mu sun'   );
  MU(2) = Constant( 'mu moon'  );
  MU(3) = Constant( 'mu earth' );
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


earthCenter = false;
moonCenter = false;
if( ~isempty(d(1).planet) )
  switch lower(d(1).planet)
    case 'earth'
      earthCenter = true;
    case 'moon'
      moonCenter = true;
    otherwise
      error('PSS:SCT','Planet %s not supported.',d(1).planet);
  end
end

% Determine the number of spacecraft
%-----------------------------------
p = length(x);
n = p/7;

xDot = zeros(p,1);

jD = d(1).jD0 + t/86400;

mToKm = 0.001;

% Sun ephemeris
[uSun, rSun] = SunV1( jD );
% Moon ephemeris
[uMoon,rMoon] = MoonV1( jD );
rToMoon = rMoon*uMoon;
% ECI to planet fixed matrix
cECIToPF = ECIToPlanet( jD + t/86400, d(1).planet, -1 );

% Run through all of the spacecraft
%----------------------------------
for k = 1:n
  j = 7*(k-1);
  r = x(j+1:j+3);
  v = x(j+4:j+6);
  m = x(j+7);
  dS = d(k);

  if earthCenter
    aPlanet = APlanet( r, MU(1), rSun*uSun ) ...
              + APlanet( r, MU(2), rToMoon );
    rToSun = rSun*uSun;
    thisMu = MU(3);
  elseif moonCenter
    rEarth  = -rToMoon;
    rToSun  = rEarth + rSun*uSun;
    aPlanet = APlanet( r, MU(1), rToSun   ) ...
              + APlanet( r, MU(3), rEarth );
    thisMu = MU(2);
    rSun = Mag(rToSun);
    uSun = Unit(rToSun);
  end

  % Environment data
  %-----------------
  rPF = cECIToPF*r;
  env = Environment( [r;v], dS );
  env.uSun = uSun;
  env.rSun = rSun;
  env.solarFlux = SOLAR_FLUX/(rSun/AU)^2;

  % Set to zero
  %------------
  aAero   = zeros(3,1);
  aSolar  = zeros(3,1);

  if( ~isempty(dS.thrusterModel) )       
      [force, ~, mDot] = feval( dS.thrusterModel, m, env, dS.thrusterData );
      aThrust      = force*mToKm/m;
  else
      aThrust      = [0;0;0];
      mDot = 0;
  end

  % Compute the gravitational acceleration
  %---------------------------------------
  if( ~isempty(dS.gravityModel) )
      aGravity = cECIToPF'*AGravityC( rPF, [], [], dS.gravityModel );
  else
      aGravity = FOrbCart( [r;v], t, [0;0;0], thisMu ); 
      aGravity = aGravity(4:6);
  end

	% Find the perturbing acceleration due the atmosphere (Earth only)
	%----------------------------------------------------
	if( earthCenter && ~isempty(dS.aeroModel) )
      aAero = feval( dS.aeroModel, env, dS.surfData )*mToKm/m;
  end

  % Find the perturbing acceleration due the sun
  %---------------------------------------------
  if( ~isempty(dS.opticalModel) )
      aSolar = feval( dS.opticalModel, env, dS.surfData )*mToKm/m;
  end

  % Add the perturbations
  %----------------------
  vDot          = aGravity + aPlanet + aSolar + aThrust + aAero;
  xDot(j+1:j+7) = [v;vDot;mDot];
end


function d = DefaultStruct
% Default data structure
%-----------------------

d.jD0 = JD2000;
d.planet = 'earth';

% Function handles
d.gravityModel = [];
d.thrusterModel  = [];
d.thrusterData   = [];
d.aeroModel    = [];
d.opticalModel = [];
d.atm          = [];
d.surfData     = [];

end

function env = Environment( x, d )

%% Environment calculations for the CubeSat dynamical model.
%
% Uses the J70 atmosphere model or AtmDens2 if the data required by J70 is
% absent. Computes sun location with SunV1 and accounts for eclipses from the
% Earth via Eclipse. All environment constants including gravity are defined
% here.
%   Outputs
%   -------
%   env        (.)     Environmental data
%                      .r            ECI position (km)
%                      .v            ECI velocity (km/s)
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
%   See also SunV1, Eclipse, AtmDens2, AtmJ70, BDipole, MoonV1
%--------------------------------------------------------------------------

% Data structure to fill in
%--------------------------
env = EnvironmentStruct;

% Get the states
%---------------
rL     = x(1:3); % ECI frame
vL     = x(4:6);
if ~isempty(d.surfData)
  qL = CubeSatAttitude( d.surfData.att, rL, vL );
else
  qL = [];
end

% Sun vector and distance - account for location in Earth orbit
%------------------------
if( earthCenter )
  n1  = Eclipse(rL,rToSun,[0;0;0],RADIUS_EARTH);
  n2  = Eclipse(rL,rToSun,rToMoon,RADIUS_MOON);
else
  n1  = Eclipse(rL,rToSun,[0;0;0],RADIUS_MOON);
  n2  = Eclipse(rL,rToSun,-rToMoon,RADIUS_EARTH);
end
nEcl = n1*n2;

% Magnetic field
%---------------
if earthCenter
  env.bField = BDipole;
end

rho = 0;
vRel = vL;
if( earthCenter && ~isempty(d.surfData) )
	% Find the perturbing acceleration due the atmosphere
	%----------------------------------------------------
  if isempty(d.atm)  
    rho = AtmDens2(Mag(rL)-env.radiusPlanet);
  else
    dAtm      = d.atm;
    dAtm.rECI = rL;
    dAtm.jD   = jD;
    rho       = AtmJ70( dAtm )*1000;
  end
  
  % Adjust velocity for Earth rotation
  %-----------------------------------
	vRel = vL - cECIToPF'*SKEW_OMEGA_EARTH*rPF; % Account for earth rotation
end

% Store in the structure format
%------------------------------
env.r    = rL;
env.v    = vL;
env.q    = qL;
env.rho  = rho;
env.vRel = vRel;
env.nEcl = nEcl;

end % environment function

function d = EnvironmentStruct
% Environment data structure

d           = struct;
d.r         = [7000;0;0];
d.v         = [0;7;0];
d.q         = QZero;
d.mu        = 3.98600436e5; % km3/s2
if earthCenter
  d.radiusPlanet = RADIUS_EARTH; % km
  d.radiation = RADIATION(1);  % W/m2
  d.albedo    = ALBEDO(1);    % fraction
elseif moonCenter
  d.radiusPlanet = RADIUS_MOON; % km
  d.radiation = RADIATION(2);  % W/m2
  d.albedo    = ALBEDO(2);    % fraction
end
d.vRel      = [0;6.5;0];
d.rho       = 0;
d.uSun      = [1;0;0];
d.rSun      = 149597870;
d.solarFlux = 1367;    % W/m2 at 1 AU
d.nEcl      = 1;
d.bField    = [0;0;0];

end % environment struct

function b = BDipole
% Computes the geocentric magnetic field based on a tilted dipole model. 
% The output is in geocentric inertial coordinates (ECI).
%--------------------------------------------------------------------------
%   Reference:  Wertz, J., ed. "Spacecraft Attitude Determination and
%               Control," Kluwer, 1976, 783-784.
%
%   Includes 1995 IGRF coefficients as of Jan. 1999
%--------------------------------------------------------------------------

jD1995     = -1826.5;
jDFrom2000 = jD - JD2000;

dJD       = (jDFrom2000(1)-jD1995)/365.25;

g10       = -29652   + 22.4*dJD; 
g11       =  -1787.5 + 11.3*dJD;  
h11       =   5367.5 - 15.9*dJD;  

h0        = sqrt( h11^2 + g11^2 + g10^2 ); 
a         = 6371.2;

cosThetaM = g10/h0;
thetaM    = acos( cosThetaM ); 
sinThetaM = sin( thetaM );
phiM      = atan2( h11, g11 );
uDipoleEF = [sinThetaM*cos( phiM ); sinThetaM*sin( phiM ); cosThetaM];

aCuH      = a^3*h0*1.e-9;		  

rMag = Mag( rPF );
uR   = rPF/rMag;
bEF  = (aCuH/rMag^3)*(3*(uDipoleEF'*uR)*uR-uDipoleEF);
b    = cECIToPF'*bEF;

end % BDipole

end % FOrbitMultiSpacecraft


%--------------------------------------
% $Date: 2020-05-29 16:41:24 -0400 (Fri, 29 May 2020) $
% $Revision: 52563 $
