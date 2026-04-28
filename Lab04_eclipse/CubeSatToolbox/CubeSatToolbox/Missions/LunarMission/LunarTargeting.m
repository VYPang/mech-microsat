function [x0,elL,v,jD0,jDP] = LunarTargeting( date, el0, rP, inc, fIf, simJDP, opts )

%% Generate transfer orbit elements for a lunar mission.
%
% Uses the JPL Ephemerides for the Earth and moon. The target is the
% perilune altitude of the hyperbolic passage of the moon. The function
% propagates the resulting trajectory using ode113. It propagates to the
% target point. You can specify radius of perilune and orbit inclination.
%
% This function uses Lambert to target a point on the Earth/Moon interface.
% The point is where the hyperbolic passage of the moon starts. This 
% justifies the single body Lambert solution.
%
% The spacecraft starts in any Earth orbit.
%
% Requires fmincon in the optimization toolbox. See fmincon for the
% definition of the argument opts.
%
% Type LunarTargeting for a demo.
%
%--------------------------------------------------------------------------
%   Form:
%   [x0,eL,v,jD0] = LunarTargeting( date, a0, rP, inc, fIf, opts )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   date    (1,:)  Date [yy mm dd hh mm ss] or Julian date
%                  of lunar encounter. "Encounter": When spacecraft reaches
%                  earth/moon interface.
%   el0     (1,5)  Initial keplerian orbital elements [a,i,W,w,e] in km and
%                  radians 
%   rP      (1,1)  Desired perilune distance (km)
%   inc     (1,1)  Desired Lunar orbit inclination (rad)
%   fIf     (1,1)  The Earth/Moon gravitational interface point from the
%                  moon
%   simJDP  (1,1)  Logical. If false, jDP is computed from Keplerian lunar
%                  elements. If true, jDP is computed more accurately via
%                  simulation. Default: False
%   opts    (.)    Optimization tolerance data structure
%
%   -------
%   Outputs
%   -------
%   x0      (1,6)  Initial state [r,v] in km and km/s
%   elL     (6,1)  Final lunar keplerian orbital elements [a,i,W,w,e,M] in
%                  km and radians 
%   v       (3,2)  Initial and interface velocity in km/s
%   jD0     (1,1)  Start Julian date
%   jDP     (1,1)  Julian date of perilune
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%   2020.1 Fixed a bug due to a change in PlanetPosJPL
%          Added fIf as an input.
%          Added perilune Julian Date as an output
%--------------------------------------------------------------------------

% license check
if( ~HasOptimizationToolbox )
  error('You need the optimization toolbox to use fmincon in this function');
end

% Demo
if( nargin < 1 )
  el0 = [8000 pi/3 0 0 0];
  LunarTargeting( [2016 5 10 1 30 0], el0, 3000, 1 );
  return
end

if( nargin < 5 )
  fIf = [];
end

if( nargin < 6 )
  simJDP = [];
end

% fmincon options
if( nargin < 7 )
  opts      = optimset('Display','iter-detailed',...
                        'TolFun',1e-4,...
                        'algorithm','interior-point',...
                        'TolCon',1e-4,...
                        'MaxFunEvals',10000);
end

% The input date can be calendar or Julian date
if( length(date) > 1 )
  jD = Date2JD(date);
else
  jD = date;
end

% Find the moon position using the JPL ephemerides
PlanetPosJPL( 'initialize', [3 10] ); % 3 is the Earth, 10 the moon
[rPl, mu, vPl]	= PlanetPosJPL( 'update', jD );

% Default interface point. Measured from the moon.
if( isempty(fIf) )
  fIf = 0.1498;
end
if isempty(simJDP)
  simJDP = false;
end

%% Initial values
d.rP  = rP; % Desired perigee
d.inc = inc; % Desired inclination
d.el0 = el0; % Starting elements
d.rM  = rPl(:,2); % Moon position
d.vM  = vPl(:,2); % Moon velocity
d.muM = mu(2); % Moon gravity
d.muE = mu(1); % Earth gravity
d.rS  = fIf*Mag(rPl(:,2)); % Earth/Moon interface
 
%% Control vector

% The cost is initial velocity magnitude. It is returned from LambertTOF in
% function "RandV" 
costFun   = @(u) Cost(u,d);

% Equality constraints are final perilune and final lunar orbit inclination
% These are determined by interface Lambert state in function "Elements"
constFun	= @(u) Const(u,d);

% u is [alpha, delta, time of flight in days, mean anomaly]
% alpha and delta are the angles of the interface point with respect to the
% moon. 

% Lower and upper bounds
lB        = [0   -pi/2 1 0];
uB        = [2*pi pi/2 6 2*pi];

% Initial guess for control vector
u0        = [0    0    4 0];

%% Perform the optimization
u         = fmincon(costFun,u0,[],[],[],[],lB,uB,constFun,opts);

% Get the velocity and position
[v,r]     = RAndV( u, d );

% The initial point for the simulation
x0        = [r;v(:,1)];

% Time of flight
dT        = u(3)*86400;

% Initial Julian day number
jD0       = jD - dT/86400;

% Generate the elements in the lunar frame
[elL, rPSim, xS]  = Elements( u, v, d );

% Julian day of perilune
dTP       = Period(-elL(1),d.muM)*elL(6)/2/pi;
jDP       = jD + dTP/86400;

if simJDP
  [r, rM, jDSim]	= Simulate( x0, dT*1.2, jD0 );
  dR = Mag(r-rM);
  jDP = jDSim(dR==min(dR));
  dTP = 86400*(jDP-jD);
end

%% Report

% Hyperbolic elements
fprintf(1,'Hyperbolic Lunar Elements\n');
fprintf(1,'Radius of perilune %12.2f km\n',rPSim);
fprintf(1,'Semi major axis    %12.2f km \n',elL(1));
fprintf(1,'Inclination        %12.2f deg\n',elL(2)*180/pi);
fprintf(1,'Longitude          %12.2f deg\n',elL(3)*180/pi);
fprintf(1,'Perigee            %12.2f deg\n',elL(4)*180/pi);
fprintf(1,'Eccentricity       %12.2f \n',elL(5));
fprintf(1,'Mean anomaly       %12.2f deg\n',elL(6)*180/pi);
fprintf(1,'Start JD           %16.4f day\n',jD0);
fprintf(1,'Transfer Time      %16.4f days\n',dT/86400);
 
% Plot the results
if( nargout == 0 )
  [r, rM, jD]	= Simulate( x0, dT*1.2, jD0 );
  EarthMoon( r, jD, [1, 1], rM );
  SimulateLunarOrbit( xS, d, dTP );
  clear x0
end

%--------------------------------------------------------------------------
%  Cost function
%  Accepts control vector and struct
%  Returns magnitude of initial velocity
%--------------------------------------------------------------------------
function y = Cost(u,d)

v       = RAndV( u, d );
y       = Mag(v(:,1)); % Lambert initial velocity

%--------------------------------------------------------------------------
%  Constraint function
%  Accepts control vector and struct
%  Returns perilune radius difference and lunar orbit inclination
%  difference as equality constraint (=0)
%--------------------------------------------------------------------------
function  [cIn, cEq] = Const(u,d)

v         = RAndV( u, d );
[el, rP]	= Elements( u, v, d ); % This uses final Lambert state, central body model
cIn       = [];
cEq       = [ rP   	- d.rP;...
              el(2)	- d.inc];
            
%--------------------------------------------------------------------------
%  Lunar elements
%  el are the orbital elements in the lunar frame
%--------------------------------------------------------------------------
function [el, rP, xS] = Elements( u, v, d )

vS      = v(:,2) - d.vM; % CPS: v(:,2) is end of Lambert solution. Central body model, no lunar gravity
alpha   = u(1);
delta   = u(2);
cDelta  = cos(delta);
rS      = d.rS*[cos(alpha)*cDelta;sin(alpha)*cDelta;sin(delta)];
el      = RV2El( rS, vS, d.muM );
rP      = el(1)*(1-el(5));
xS      = [rS;vS];

%--------------------------------------------------------------------------
%  Helper function
%  Accepts control vector and struct
%  Returns initial velocity and position, and interface velocity
%--------------------------------------------------------------------------
function [v,r] = RAndV( u, d )

el = [d.el0 u(4)];
r  = El2RV(el); % Initial position
r2 = d.rM - d.rS*[cos(u(1))*cos(u(2));sin(u(1))*cos(u(2));sin(u(2))]; 
v  = LambertTOF(r,r2,u(3)*86400); % Initial and interface velocity. Interface velocity is final Lambert velocity

%--------------------------------------------------------------------------
%  Simulation
%  Returns ECI spacecraft position and moon position in the Earth/Moon
%  system.
%--------------------------------------------------------------------------
function [r, rM, jD] = Simulate( x0, tEnd, jD0 )

xODEOptions	= odeset( 'AbsTol', 1e-4, 'RelTol', 1e-4 );
[t,z]       = ode113( @RHS, [0 tEnd], x0, xODEOptions, jD0 );
r           = z(:,1:3)';
jD          = jD0 + t'/86400;
n           = size(r,2);
rM          = zeros(3,n);

for k = 1:n
  rP      = PlanetPosJPL( 'update', jD(k) );
  rM(:,k)	= rP(:,2);
end

%--------------------------------------------------------------------------
%  Simulation in the lunar frame.
%  Plots the hyperbolic lunar orbit
%--------------------------------------------------------------------------
function SimulateLunarOrbit( x0, d, dTP )

tEnd        = 2*dTP;
x0(4:6)     = -x0(4:6);
xODEOptions	= odeset( 'AbsTol', 1e-4, 'RelTol', 1e-4 );
[t,z]       = ode113( @RHSLunar, [0 tEnd], x0, xODEOptions, d );
Plot3D(z(:,1:3)','x (km)', 'y (km)', 'z (km)', 'Lunar Orbit',1738);
hold on;
iHalf       = 1:numel(t);
iHalf       = iHalf(abs(t-dTP)==min(abs(t-dTP)));
plot3(z(iHalf,1),z(iHalf,2),z(iHalf,3),'*');

t           = t';
k           = length(t)/3;
k           = [1 floor(k) 2*floor(k) length(t)];
[t,~,tU]    = TimeLabl(t);
for j = 1:4
  i = k(j);
  text(z(i,1),z(i,2),z(i,3),sprintf('t = %4.1f %s',t(i),tU));
end
text(z(iHalf,1),z(iHalf,2),z(iHalf,3),sprintf('Perilune'));

%--------------------------------------------------------------------------
%  Right hand side for lunar simulation
%--------------------------------------------------------------------------
function xDot = RHSLunar( ~, x, d )

r         = x(1:3); 
xDot      = [x(4:6);-d.muM*r/Mag(r)^3];

%--------------------------------------------------------------------------
%  Right hand side for simulation
%--------------------------------------------------------------------------
function xDot = RHS( t, x, jD0 )

jD        = jD0 + t/86400;
[rP, mu]	= PlanetPosJPL( 'update', jD );
r         = x(1:3); 
a         = APlanet( r, mu(2), rP(:,2) ) - mu(1)*r/Mag(r)^3;
xDot      = [x(4:6);a];


%--------------------------------------
% $Date: 2020-05-08 14:41:04 -0400 (Fri, 08 May 2020) $
% $Revision: 52176 $