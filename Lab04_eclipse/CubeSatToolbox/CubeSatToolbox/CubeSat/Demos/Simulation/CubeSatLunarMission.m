%% Lunar Mission Demo
% Simulate a mission from Earth orbit to lunar orbit.
% The spacecraft has 3 orthogonal reaction wheels and a single delta-v
% thruster.
% The mission plan does not perform the lunar insertion burn.
%
% It uses the default values from RHSLunarMission for a 6U CubeSat.
% The dimensions are 30 x 20 x 10 cm.

%%
%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%   2020.1 Fixed the lunar insertion burn and the lunar orbit plotting
%--------------------------------------------------------------------------

%% Constants
rMoon                       = 1738;
dayToSec                    = 86400;

%% User inputs
dateEncounter               = [2016 5 10 1 30 0]; % "Encounter" is passing into lunar sphere of influence
dT                          = 2;    % integration time step seconds
el0                         = [7000 0 0 0 0];
rLunarOrbit                 = 3000; % km 
incLunarOrbit               = 1;
surfaceMagnificationFactor  = 10;   % For lunar terrain display
timeAdded                   = 36000; % sec added simulation time after intercept
useSphericalHarmonics       = 0;

%% Control setup

% Find transfer orbit to the moon
jDEncounter   = Date2JD( dateEncounter );
InterpolateState([],[],'bin2000.405');
if( HasOptimizationToolbox )
  [x0,el,~,jD0,jDP] = LunarTargeting( jDEncounter, el0, rLunarOrbit, incLunarOrbit, [], true );
else
  disp('LunarMission: Optimization toolbox not installed; using hard-coded values.')
  x0  = [-2.8408    6.3976         0   -0.0034    0.0099    0.0018]'*1e3;
  el  = [-5.2588    0.0010    0.0001    0.0041    0.0016    0.0088]*1e3;
  jD0 = 2.457514449298204e+06;
end

tEnd      = (jDP-jD0)*dayToSec + timeAdded;

% Get the default data structure
dC        = LunarMissionControl;

dC.dT     = dT;
dC        = LunarMissionControl('initialize',jD0,dC);
dRHS      = RHSLunarMission;

if( useSphericalHarmonics )
  dRHS.sphHarmMoon    = LoadSGM150( 'SGM150.geo' ); %#ok<*UNRCH>
  dRHS.sphHarmMoon.nN = 3;
  dRHS.sphHarmMoon.nM = 3;
end

% Set up the control data structure
dC.mass   = struct('mass',dRHS.mass,'inertia',dRHS.inertia,'cM',dRHS.surfData.cM);
dC.rWA    = dRHS.rWA;

% This command list is for an lunar orbit insertion
cList     = { jDP-1e3/dayToSec,...
                  'lunar orbit insertion prepare',...
                  struct('thrust',20,'massInitial',6, 'uE', 290*9.806,'body_vector',[1;0;0],'hLunarOrbit',200);...
                  +2,...
                  'align for lunar insertion',...
                  [];...
                  +1e3,...
                  'start main engine',...
                  struct('iD',1,'thrust',20)};

% Initial state setup
qECIToBody                  = [1;0;0;0];
omega                       = [0;0;0];  % rad/s
omegaRWA                    = [0;0;0];  % rad/s
accelBias                   = [0;0;0];  % km/s^2
gyroBias                    = [0;0;0];  % rad/s
massFuel                    = 3;        % kg

%% Initialize the simulation model

% Initialize JPL Ephemerides to include the Sun, Earth and Moon
PlanetPosJPL( 'initialize', [0 3 10] );

nSim          = ceil(tEnd/dT);
dRHS.jD0      = jD0;
x             = [x0;qECIToBody;omega;massFuel;dRHS.power.batteryCapacity;...
                  accelBias;gyroBias;omegaRWA];
                
% This initializes the state and auxiliary output names
RHSLunarMission( x );

%% Run the simulation
t       = 0;
xP      = zeros(length(x),nSim);
[~, p]	= RHSLunarMission( x, t, dRHS );
pP      = zeros(length(p.auxNames),nSim);

% Globals for the time tracking GUI
global simulationAction
simulationAction = ' ';

for k = 1:nSim
  
  % Plot storage
  [~, p]      = RHSLunarMission( x, t, dRHS );
  q = x(7:10);
  xP(:,k)     = x;
  pP(:,k)     = p.aux;
  
  % The controller
  jD          = jD0 + t/dayToSec;
  dC.rMoon    = pP(21:23,k);
  dC.vMoon    = pP(24:26,k);
  [dC, dRHS]	= LunarMissionControl( 'update', jD, dC, dRHS, x, cList );
 
  % Propagate
  x           = RK4(@RHSLunarMission,x,dT,t,dRHS);
  t           = t + dT;
  
  switch simulationAction
    case 'pause'
      pause
      simulationAction = ' ';
    case 'stop'
      LunarMissionControl( 'terminate' );
      return;
    case 'plot'
      break;
  end
  
end
LunarMissionControl( 'terminate' );

%% Plot the results
if k<nSim
  xP = xP(:,1:k);
  pP = pP(:,1:k);
  nSim = k;
end
tS      = (0:nSim-1)*dT;
jD      = jD0 + t/dayToSec; % in days

[t,tL]	= TimeLabl(tS);

% Plot the states
k = 1:3;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'Position');          k = 4:6;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'Velocity');          k = 7:10;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'Quaternion');        k = 11:13;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'Angular Velocity');  k = 14:15;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'Fuel and Battery');  k = 16:18;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'IMU Accel Bias');    k = 19:21;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'IMU Gyro Bias');     k = 22:24;
Plot2D(t,xP(k,:),tL,p.stateNames(k),'Reaction Wheel Rates');

% Plot the auxiliary outputs
k = 4:6;
Plot2D(t,pP(k,:),tL,p.auxNames(k),'Thruster Force');        k = k+3;
Plot2D(t,pP(k,:),tL,p.auxNames(k),'Solar Torque');        k = 10:12;
Plot2D(t,pP(k,:),tL,p.auxNames(k),'Solar Force');         k = 13:14;
Plot2D(t,pP(k,:),tL,p.auxNames(k),'Power');               k = 21:23;

dR = xP(1:3,:) - pP(k,:);
dV = Mag(xP(4:6,:) - pP(24:26,:));
h  = Mag(dR) - rMoon;
yL = {'x (km)', 'y (km)', 'z (km)', 'h (km)' '|v| (km/s)'};
Plot2D(t,[dR;h;dV],tL,yL,'Moon Relative Position'); 

% Plot the trajectory for the Earth/Moon transfer
EarthMoon( xP(1:3,:), jD, [1, 1], pP(21:23,:) );

% Display from encounter time
jD    = jD0 + tS/dayToSec;
kB = find(jD>jDEncounter);

if ~isempty(kB)
  k = kB(1):nSim;
  dR    = dR(:,k);
  jD    = jD(1,k);
  uSun  = SunV1(jD(1));

  PlotLunarOrbit( dR, jD, uSun, pP(4:6,k), surfaceMagnificationFactor );
end
Figui;


%--------------------------------------
% $Date: 2020-07-13 15:07:55 -0400 (Mon, 13 Jul 2020) $
% $Revision: 53042 $