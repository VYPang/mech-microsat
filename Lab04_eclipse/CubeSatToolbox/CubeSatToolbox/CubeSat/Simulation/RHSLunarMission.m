function [xDot, p] = RHSLunarMission( x, t, d )

%% Right hand side for orbit and attitude dynamics for a lunar mission simulation.
%
% Includes solar disturbances and the power model. Any number of reaction wheels
% can be simulated. Reaction wheels are optional. It also includes states for
% the IMU (gyro and accelerometer) bias.
%
% * The gravity model includes the Earth, Sun and the Moon.
%   The Moon gravity model can have spherical harmonics.
% * The solar power model includes eclipses due to the Moon and Earth
%   but not self-shadowing.
%
% You can select the Moon or Earth as the coordinate center for orbit
% propagation. Get the default data structure by typing:
%
%   d = RHSLunarMission
%
% Set up the state name output by typing:
%
%   RHSLunarMission( x );
%
% You must initialize the JPL ephemerides prior to using this function.
% Type:
%
%   PlanetPosJPL( 'initialize', [0 3 10] );
%
%--------------------------------------------------------------------------
%   Forms:
%           d = RHSLunarMission;            % data structure
%               RHSLunarMission( x );       % initialize persistent variables
%   [xDot, p] = RHSLunarMission( x, t, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x     (:,1)   State [rECI;vECI;qECIToBody;omega;massFuel;pBattery;
%                        iMUBiasAccel;iMUBiasGyro;omegaRWA]
%   t     (1,1)   Time
%   d     (.)     Data structure
%                      .jD0        (1,1) Julian date of epoch
%                      .mass       (1,1) Spacecraft mass (kg)
%                      .inertia    (3,3) Spacecraft inertia (kg-m2)
%                      .power       (.)  Power data, see SolarCellPower 
%                      .opticalModel * Handle, see CubeSatRadiationPressure
%                      .surfData    (.)  optional; empty to skip optical calcs
%                      .thruster    (.)
%                      .rWA         (.)
%                      .iMU         (.)
%                      .gravity     (.)
%                      .forceBody  (3,1) Body forces (N)
%                      .torqueBody (3,1) Body torques (Nm)
%
%   -------
%   Outputs
%   -------
%   xDot  (:,1)   dx/dt
%   p     (.)     Data structure with internally computed variables
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%--------------------------------------------------------------------------

persistent stateNames auxNames

% Constants
mToKm         = 0.001;

if( nargin < 1 )
  % Default data structure
  xDot = DataStructure;
  return
elseif( nargin == 1 )
  % Initialize the names including the correct number of wheels
  stateNames	= StateNames(x);
  auxNames    = AuxNames;
  PlanetPosJPL( 'initialize', [0 3 10] );
  return
end

s = CubeSatLunarEnvironment( x, t, d );

% Extract states
vECI        = x( 4: 6);
qECIToBody	= x( 7:10);
omega       = x(11:13);
massFuel    = x(14);
pBattery    = x(15);
omegaRWA    = x(22:end);

% Add thrusters to force and torque. Thrusters can only fire if there is fuel
% left.
thrusterForce = [0;0;0];
if( massFuel > 0 )
  thrusterForce 	= d.thruster.u*d.thruster.thrust;
  massDot         = -sum(d.thruster.thrust)/d.thruster.uE;
else
  massDot         = 0;
end
r               = d.thruster.r - DupVect(d.surfData.cM,size(d.thruster.r,2));
thrusterTorque	= Cross(r,d.thruster.u)*d.thruster.thrust;
torque          = sum(thrusterTorque,2) + d.torqueBody;
thrusterForce   = sum(thrusterForce,2);

% Mass
mass            = d.mass + massFuel;

% Add optical pressure disturbances
solarForce = [0;0;0];
solarTorque = [0;0;0];
if( ~isempty(d.surfData) )
  d.surfData.att.qECIToBody = qECIToBody;
  [solarForce, solarTorque] = feval( d.opticalModel, s, d.surfData );
end
torque  = solarTorque + torque;
force   = solarForce + d.forceBody;

% Rotational dynamics
h  = d.inertia*omega;
if( ~isempty(d.rWA) )
  hRWA            = d.rWA.inertia*d.rWA.u*omegaRWA;
  h               =	h + hRWA;
  % Account for wheel friction
	deltaOmega      = omegaRWA - d.rWA.u'*omega;
  torqueRWA       = d.rWA.torque - d.rWA.fDamping.*deltaOmega;
  k               = find( deltaOmega > 0 );
  torqueRWA(k)    = torqueRWA(k) - d.rWA.fCoulomb(k);
  k               = find( deltaOmega < 0 );
  torqueRWA(k)    = torqueRWA(k) + d.rWA.fCoulomb(k);
  
  torqueRWABody   = d.rWA.u*torqueRWA;
else
  torqueRWABody   = [0;0;0];
end

thrusterForceECI = QTForm(qECIToBody,thrusterForce);

forceECI          = QTForm( qECIToBody, force);
omegaDot          = d.inertia\(torque - torqueRWABody - Skew(omega)*h);
vDot        = s.accelGrav + (thrusterForceECI+forceECI)*mToKm/mass;
% Reaction wheel derivative
if( ~isempty(d.rWA) )
  omegaRWADot   = torqueRWA/d.rWA.inertia - d.rWA.u'*omegaDot;
else
  omegaRWADot = [];
end

% Power model
uSunBody       = QForm( qECIToBody, s.uSun );
pSun           = s.nEcl*s.solarFlux*uSunBody;
pSolar         = SolarCellPower( d.power, pSun );
pRWA   = d.rWA.torque'*omegaRWA;
pDot   = pSolar - d.power.powerConsumption - pRWA;
if( pBattery < 0 || pBattery > d.power.batteryCapacity )
  pDot = 0;
end

% IMU
biasGDot = d.iMU.accelBiasNoise.*randn(3,1);
biasADot = d.iMU.gyroBiasNoise.*randn(3,1);

% State derivative
qDot = QIToBDot( qECIToBody, omega );
xDot = [vECI;vDot;qDot;omegaDot;massDot;pDot;biasADot;biasGDot;omegaRWADot];

% Auxiliary output
if( nargout > 1 )
  p.stateNames = stateNames;
  p.auxNames   = auxNames;
  p.aux        = [  sum(thrusterTorque,2);...
                    thrusterForceECI;...
                    solarTorque;...
                    solarForce;...
                    pSolar;...
                    pRWA;...
                    s.uSun;...
                    xDot(4:6);...
                    s.rMoon;...
                    s.vMoon];
end

%--------------------------------------------------------------------------
%   Default data structure
%--------------------------------------------------------------------------
function d = DataStructure

rWA           = struct(	'inertia',  	0.01,...
                        'fDamping',   [0;0;0],...
                        'u',          eye(3),...
                        'torque',     [0;0;0],...
                        'fCoulomb', 	[0;0;0]);

thruster      = struct( 'uE', 285*9.806,'u',[1;0;0],'r',[-0.15;0;0],'thrust',0);

massTotal     = 6;
inertia       = InertiaCubeSat([3 2 1],massTotal);

iMU           = struct( 'accelBiasNoise',[0;0;0],'gyroBiasNoise',[0;0;0]);

% Dimensions
x             = 0.3;
y             = 0.2;
z             = 0.1;

power                 = SolarCellPower;
power.solarCellNormal = [0 0 0 0;1 -1 0 0;0 0 1 -1];
power.solarCellArea   = x*[z z y y];
power.solarCellEff    = 0.32;
power.consumption     = 10;
power.batteryCapacity = 1e6;
                  
gravity       = struct( 'center',0, 'harmMoon',[] );                  
 
opticalModel   = @CubeSatRadiationPressure;
surfData       = CubeSatRadiationPressure;
c              = [0.2;0.3;0.5];
surfData.sigma = c*ones(1,6);
surfData.rFace = 0.5*[x -x 0 0 0 0; 0 0 y -y 0 0;0 0 0 0 z -z];
surfData.nFace = [1 -1 0 0 0 0;0 0 1 -1 0 0;0 0 0 0 1 -1];
surfData.area  = [y*z y*z x*z x*z x*y x*y];

d             = struct( 'jD0',      	  Date2JD,...
                        'mass',         massTotal,...
                        'inertia',      inertia,...
                        'power',        power,...
                        'surfData',     surfData,...
                        'opticalModel', opticalModel,...
                        'forceBody', 	  [0;0;0],...
                        'torqueBody',	  [0;0;0],...
                        'rWA',       	  rWA,...
                        'thruster',     thruster,...
                        'iMU',      	  iMU,...
                        'uECI',         [0;0;0],...
                        'gravity',  	  gravity);
 
% obsolete fields - temporary for testing
d.solar       	= struct( 'u',[1 -1 0 0 0 0;0 0 1 -1 0 0;0 0 0 0 1 -1],...
                        'r',0.5*[x -x 0 0 0 0; 0 0 y -y 0 0;0 0 0 0 z -z],...
                        'area',[y*z y*z x*z x*z x*y x*y],...
                        'coeff',[c c c c c c]);
d.power.u                 = [0 0 0 0;1 -1 0 0;0 0 1 -1];
d.power.area              = x*[z z y y];
d.power.eff               = [0.32 0.32 0.32 0.32];
d.power.powerConsumption	= 10;

%--------------------------------------------------------------------------
%   State names. Allows for a variable number of wheels.
%--------------------------------------------------------------------------
function p = StateNames( x )

n = length(x);
p = cell(n,1);

p{ 1} = 'x (km)';
p{ 2} = 'y (km)';
p{ 3} = 'z (km)';
p{ 4} = 'v_x (km/s)';
p{ 5} = 'v_y (km/s)';
p{ 6} = 'v_z (km/s)';
p{ 7} = 'q_s';
p{ 8} = 'q_x';
p{ 9} = 'q_y';
p{10} = 'q_z';
p{11} = '\omega_x (rad/s)';
p{12} = '\omega_y (rad/s)';
p{13} = '\omega_z (rad/s)';
p{14} = 'fuel (kg)';
p{15} = 'battery energy (J-s)';
p{16} = 'accel bias_x (km/s)';
p{17} = 'accel bias_y (km/s)';
p{18} = 'accel bias_z (km/s)';
p{19} = 'gyro bias_x (rad/s)';
p{20} = 'gyro bias_y (rad/s)';
p{21} = 'gyro bias_z (rad/s)';

for k = 1:n-21
  p{21+k} = sprintf('\\omega_%d (rad/s)',k);
end


%--------------------------------------------------------------------------
%   Auxiliary names
%--------------------------------------------------------------------------
function p = AuxNames

p = cell(23,1);
k = 1;
p{ k} = 'Thrust T_x (Nm)';      k = k + 1;
p{ k} = 'Thrust T_y (Nm)';      k = k + 1;
p{ k} = 'Thrust T_z (Nm)';      k = k + 1;
p{ k} = 'Thrust F_x ECI (N)';   k = k + 1;
p{ k} = 'Thrust F_y ECI (N)';   k = k + 1;
p{ k} = 'Thrust F_z ECI (N)';   k = k + 1;
p{ k} = 'Solar T_x (Nm)';       k = k + 1;
p{ k} = 'Solar T_y (Nm)';       k = k + 1;
p{ k} = 'Solar T_z (Nm)';       k = k + 1;
p{ k} = 'Solar F_x (N)';        k = k + 1;
p{ k} = 'Solar F_y (N)';        k = k + 1;
p{ k} = 'Solar F_z (N)';        k = k + 1;

p{ k} = 'Solar Power (W)';      k = k + 1;
p{ k} = 'RWA Power (W)';        k = k + 1;

p{ k} = 'sun_x';                k = k + 1;
p{ k} = 'sun_y';                k = k + 1;
p{ k} = 'sun_z';                k = k + 1;
p{ k} = 'accel_x';              k = k + 1;
p{ k} = 'accel_y';              k = k + 1;
p{ k} = 'accel_z';              k = k + 1;
p{ k} = 'moon x (km)';          k = k + 1;
p{ k} = 'moon y (km)';          k = k + 1;
p{ k} = 'moon z (km)';          k = k + 1;
p{ k} = 'moon vx (km/s)';       k = k + 1;
p{ k} = 'moon vy (km/s)';       k = k + 1;
p{ k} = 'moon vz (km/s)';      

%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $


