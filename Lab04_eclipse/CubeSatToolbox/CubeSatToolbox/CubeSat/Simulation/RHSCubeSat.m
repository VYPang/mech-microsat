function [xDot,dist,power] = RHSCubeSat( x, t, d )

%% Right-hand-side for a CubeSat orbit and attitude dynamical model.
% Includes drag and optical surface disturbances, magnetic dipole,
% gravity gradient, rigid body dynamics and power. Uses the J70
% atmosphere model and applies a point-mass gravity model. Computes sun
% location with SunV1 and accounts for eclipses from the Earth. The
% surface parameters in surfData are passed to both the optical and
% aerodynamic disturbance model functions.
%
% The states are [position;velocity;quaternion;angular velocity; battery charge].
% The battery charge must always be the last state. Its units are J. If there
% are wheel states they must be between the spacecraft angular velocity and the
% battery charge, and the indices be logged in kWheels.
%
% Can output the disturbance forces and torques for post-processing.
% There is also a call to retrieve the default data structure.
%--------------------------------------------------------------------------
%   Form:
%   [xDot,dist,power] = RHSCubeSat( x, t, d )
%   d = RHSCubeSat
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x        (14,1)    [r;v;q;w;wRWA;b]
%   t         (1,1)    Time, sec
%   d          (.)     Data structure
%                      .jD0      (1,1) Julian date of epoch
%                      .mass     (1,1) Spacecraft mass (kg)
%                      .inertia  (3,3) Inertia matrix (kg-m2)
%                      .dipole   (3,1) Residual dipole (ATM^2)
%                      .power     (.)  Power data, see SolarCellPower 
%                      .aeroModel    * Handle, see CubeSatAero
%                      .opticalModel * Handle, see CubeSatRadiationPressure
%                      .surfData  (.)  optional; empty to skip drag/optical calcs
%                                      .cD    (3,1) Drag coefficient
%                                      .cM    (3,1) Center of mass (m)
%                                      .area  (1,n) Area (m2)
%                                      .nFace (3,n) Face normals
%                                      .rFace (3,n) Face locations (m)
%                                      .att    (.)  Attitude model
%                                      .sigma (3,n) Optical coefficients
%                                      .planet (1)  Planet effects flag
%                      .atm       (.) optional; empty to skip J70 and use AtmDens2
%                      .kWheels         (n), empty if no wheels, indices of wRWA
%                      .inertiaRWA     (1,1), optional, polar inertia (kg-m2)
%                      .tRWA           (3,1), optional, wheel torque (Nm)
%
%   -------
%   Outputs
%   -------
%   x           (14,1)	   d[r;v;q;w;b]/dt
%   dist         (.)       Disturbances data
%    .fTotal  	   (3,1)   Total force, ECI frame  (N)
%    .tTotal       (3,1)   Total torque, body frame (Nm)
%    .fAerodyn	   (3,1)   Aerodynamic force
%    .tAerodyn     (3,1)   Aerodynamic torque
%    .fOptical	   (3,1)   Optical force
%    .tOptical     (3,1)   Optical torque
%    .tMag         (3,1)   Magnetic torque
%    .tGG          (3,1)   Gravity gradient torque
%   power       (1,1)      Power from solar cells (W)
% 
%--------------------------------------------------------------------------
% See also SolarCellPower, CubeSatAero, CubeSatRadiationPressure,
% SolarFluxPrediction, CubeSatEnvironment, CubeSatSimulation,
% CubeSatRWASimulation
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2011 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8 (2009).
%   2016.1 Update to use new function CubeSatEnvironment
%   2020.1 Added states and default initial state
%--------------------------------------------------------------------------
%%  
if nargin == 0
  xDot = DefaultStruct;
  return;
end

% Get the states
%---------------
r      = x(1:3);
v      = x(4:6);
q      = x(7:10);
w      = x(11:13);
b      = x(end);
xDot   = zeros(size(x));

% Environment data
%-----------------
s = CubeSatEnvironment( x, t, d );

% Total power in - power out
%---------------------------
uSunBody       = QForm( q, s.uSun );
pSun           = s.nEcl*s.solarFlux*uSunBody;
power          = SolarCellPower( d.power, pSun );
p              = power - d.power.consumption;

% Limit the battery charging
%---------------------------
if( b >= d.power.batteryCapacity )
  if( p > 0 )
    p = 0;
  end
elseif( b <= 0 )
  if( p < 0 )
    p = 0;
  end
end

% Magnetic field
%---------------
bField = QForm( q, s.bField );
tMag   = Cross( d.dipole, bField );

% Gravity gradient
%-----------------
tGG    = GravityGradientFromR( q, d.inertia, r, s.mu );

% Add the drag/solar force and torque
%------------------------------------
fAerodyn = [0;0;0];
tAerodyn = [0;0;0];
fOptical = [0;0;0];
tOptical = [0;0;0];
if( ~isempty(d.surfData) )
  %d.surfData.att.qECIToBody = q;
	[fAerodyn, tAerodyn]    = feval( d.aeroModel, s, d.surfData );
  [fOptical, tOptical]    = feval( d.opticalModel, s, d.surfData );
end

tTotal = tGG + tMag + tAerodyn + tOptical;
fTotal = fOptical + fAerodyn;

% Ideal orbital dynamics
%-----------------------
vDot   = fTotal*1e-3/d.mass - s.mu*r/Mag(r)^3;

% Dynamical equations
%--------------------
if ~isempty(d.kWheels)
  c      = x(d.kWheels); % Reaction wheel rates
  hT     = d.inertia*w + d.inertiaRWA*(c + w);
  wDot   = d.inertia\(tTotal - d.tRWA + Cross(w,hT));
  cDot   = d.tRWA/d.inertiaRWA - wDot;
  xDot(d.kWheels) = cDot;
else
  wDot   = d.inertia\(tTotal - Cross(w,d.inertia*w));
end

% RHS
%----
xDot(1:13) = [v;vDot;QIToBDot( q, w );wDot];
xDot(end) = p;

if nargout > 1
  dist.fOptical = fOptical;
  dist.tOptical = tOptical;
  dist.fAerodyn = fAerodyn;
  dist.tAerodyn = tAerodyn;
  dist.tGG      = tGG;
  dist.tMag     = tMag;
  dist.fTotal   = fTotal;
  dist.tTotal   = tTotal;
  dist.rho      = s.rho;
  dist.bField   = bField;
end

%--------------------------------------------------------------------------
% Default data structure
%--------------------------------------------------------------------------
function d = DefaultStruct

d                       = struct;
d.jD0                   = Date2JD(2010);
d.mass                  = 1;
d.inertia               = 0.0016667*eye(3);
d.dipole                = [0;0;0];
d.power                 = SolarCellPower;
d.power.consumption     = 0.5;
d.power.batteryCapacity = 100;
d.surfData              = CubeSatAero;
d.surfData.att.type     = 'eci'; % for simulating, always use ECI quaternion
d.aeroModel             = @CubeSatAero;
d.opticalModel          = @CubeSatRadiationPressure;
d.surfData              = CubeSatRadiationPressure(d.surfData);
[aP, f, fHat, fHat400]  = SolarFluxPrediction( d.jD0, 'nominal' );
d.atm.aP                = aP(1); 
d.atm.f                 = f(1); 
d.atm.fHat              = fHat(1); 
d.atm.fHat400           = fHat400(1);
d.kWheels               = [];
d.inertiaRWA            = [];
d.tRWA                  = [];
d.states                = { 'r_x (km)' 'r_y (km)' 'r_z (km)' 'v_x (km/s)'...
                            'v_y (km/s)' 'v_z (km/s)'...
                            'q_s' 'q_x' 'q_y' 'q_z' '\omega_x (rad/s)' ...
                            '\omega_y (rad/s)' '\omega_z (rad/s)' ...
                            '\omega_x (rad/s)' '\omega_y (rad/s)'...
                            '\omega_z (rad/s)' 'b (Wh)'};

el    = ISSOrbit;
[r,v] = El2RV(el);

q    = [1;0;0;0];               % Quaternion
w    = [0;0;0];                 % Angular rate of spacecraft
c    = [0;0;0];                 % Reaction wheel rates
b    = 2*3600;                  % Battery state of charge (J = Wh*3600)

% State is [position;velocity;quaternion;angular velocity;wheels;battery charge]
d.x0    = [r;v;q;w;c;b];


%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
