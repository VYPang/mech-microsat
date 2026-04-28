function simData = FFSim( simOptions )

%% Formation flying simulation for circular orbits. 
%
% *** Notes on Usage ***
%
% Once this function has run and the outputs have been created, use the
% "FFSimPlotter" function to plot the data.
%
% *** Inputs ***
%   Supply the initial state of the reference (el0) and the initial relative 
%   state (dEl0), define the desired relative motion (goals), how many 
%   orbits to simulate (nOrbits), the number of simulation points per orbit 
%   (nSPO), the disturbance options (distOpt), the cross-sectional area, mass.
%
% *** Estimated Absolute and Relative States (ECI) ***
%   The estimated absolute and relative ECI position and velocity are provided 
%   by adding noise to the true state. This emulates the data provided by a 
%   relative navigation unit.
%
% *** Estimated Relative State (Hills) ***
%   The estimated relative position and velocity in the Hill's frame is 
%   computed via a transformation from the estimated absolute and relative 
%   ECI position and velocity. This computation is performed in the 
%   "AbsRelECI2Hills" function.
%
% *** Estimated Orbital Elements ***
%   The estimated mean orbital elements and mean orbital element differences
%   are computed from the estimated absolute and relative ECI position and
%   velocity. This computation is performed in the "ECI2MeanElements" function.
%
% *** Desired Orbital Elements ***
%   At each step in the simulation, the initial goals are used along with the 
%   current estimate of the mean orbital elements to compute the desired 
%   orbital element differences. 
%
% *** Desired Relative State (Hills) ***
%   The desired element differences are transformed to the Hill's frame, 
%   defining the desired relative position and velocity.
%
% *** Relative State Error (Hills) ***
%   The relative position errors and relative velocity errors are computed by
%   comparing the desired and estimated states.
% 
%--------------------------------------------------------------------------
%   Usage:
%   simData = FFSim( simOptions );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   simOptions    (.)   Data structure with the following fields:
%     - el0            (1,6)  Initial reference orbital elements  (Alfriend format) [a,theta,i,q1,q2,W]
%     - dEl0           (1,6)  Initial orbital element differences (Alfriend format)
%     - goals           (.)   Goals data structure defining desired relative motion
%     - nOrbits         (1)   Number of orbits to simulate
%     - nSPO            (1)   Number of simulation points per orbit
%     - distOpt        (1,3)  Disturbance options (flags)
%                          (1) solar:  whether to simulate with solar pressure or not
%                          (2) drag:   whether to simulate with drag or not
%                          (3) J2:     whether to simulate with J2 or not
%     - mass           (1,2)  Mass of reference and relative [kg]
%     - area           (1,2)  Cross-sectional area of reference and relative [m^2]
%
%   -------
%   Outputs
%   -------
%   simData       (.)   Simulation output data structure with the following fields
%     - time          (1,:)   Time vector [orbits] 
%     - rE            (3,:)   True ECI position of reference
%     - vE            (3,:)   True ECI velocity of reference
%     - rE_est        (3,:)   Estimated ECI position of reference
%     - vE_est        (3,:)   Estimated ECI velocity of reference
%     - rH            (3,:)   True Hills-frame relative position
%     - vH            (3,:)   True Hills-frame relative velocity
%     - rH_est        (3,:)   Estimated Hills-frame relative position
%     - vH_est        (3,:)   Estimated Hills-frame relative velocity
%     - rH_des        (3,:)   Desired Hills-frame relative position
%     - vH_des        (3,:)   Desired Hills-frame relative velocity
%     - dElMean       (6,:)   True mean element differences
%     - dElMean_est   (6,:)   Estimated mean element differences
%     - dElMean_des   (6,:)   Desired mean element differences
%     - elRefMean_est (6,:)   Estimated mean elements of reference
%     - fDiffDragH    (3,:)   Hills-frame differential drag force
%     - fDiffDragE    (3,:)   ECI-frame differential drag force
%     - fDiffSolarH   (3,:)   Hills-frame differential solar force
%     - fDiffSolarE   (3,:)   ECI-frame differential solar force
%     - fDiffJ2H      (3,:)   Hills-frame differential J2 force (apparent)
%     - fDiffJ2E      (3,:)   ECI-frame differential J2 force (apparent)
%
%--------------------------------------------------------------------------
% See also FFSimPlotter, AbsRelECI2Hills, ECI2MeanElements, Alfriend2El
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

if( nargin < 1 )
  a   = 6928.14;
  th  = 0;
  i   = 35.4*pi/180;
  e   = 1e-8;
  w   = 0;
  W   = 0;
  el0 = [a, th, i, e*cos(w), e*sin(w), W];

  goals = Geometry_Structure;  
  goals.aE = 0.06;

  simOptions.el0 = el0;
  simOptions.deadband = ones(1,3)*.01;
  simOptions.noise    = zeros(1,4);
  simOptions.nOrbits  = 5;

  g0 = Geometry_Structure;
  g0.y0 = 0.3;
  simOptions.dEl0 = Goals2DeltaElem(el0,g0);

  simOptions.goals = goals;
  simOptions.nSPO = 300;
  simOptions.distOpt = [1 1 1];
  simOptions.area = [5 5];
  simOptions.mass = [150 150];
end

% get input data
f = fieldnames( simOptions );
for i=1:length(f)
   eval([f{i}, ' = simOptions.',f{i},';']);
end

% default area
if( ~exist('area','var') )
   beta  = 0.0;
   dbeta = 0.0*pi/180;
   area0 = 12.984;
   area1 = 0.575;
   diffArea = (area0*sin(beta+dbeta)+area1*cos(beta+dbeta))-(area0*sin(beta)+area1*cos(beta));
   area  = [area0,area0 + diffArea];
end

if( ~exist('mass','var') )
   mass = [150 150];
end

% default disturbance options
if( ~exist('distOpt','var') )
   solar   = 1;
   drag    = 0;
   J2      = 0;
   distOpt = [solar, drag, J2];
end

% default nSPO
if( ~exist('nSPO','var') )
   nSPO = 300;
end

% default nOrbits
if( ~exist('nOrbits','var') )
   nOrbits = 3;
end

% default formation goals
if( ~exist('goals','var') )
   goals.y0           = .1;
   goals.aE           = .1;
   goals.beta         = 0;
   goals.zInc         = .01;
   goals.zLan         = .01;
end

% default initial orbital element differences
if( ~exist('dEl0','var') )
   dEl0 = zeros(1,6);
end

% default reference elements
if( ~exist('controlMethod','var') )
   el0 = [6928.14, pi/4, .6178, 0, 0, 0];
end

% mass
%-----
mass0 = mass(1);
mass1 = mass(2);

% Constants
%----------
solarPressure    = Constant('solar pressure mks')*1e-3;  % kN/m^2

% Disturbance options
%--------------------
solar = distOpt(1);     % flag (0 or 1)
drag  = distOpt(2);     % flag (0 or 1)
J2    = distOpt(3);     % flag (0 or 1)

% J2 data
%--------
if( J2 )
   gM      = LoadGravityModel( 'load file', 'GEMT1.geo', false );
%   J2      = 0.001082;
   J2      = abs(gM.j(2));
   recordJ2 = 1;
else
   recordJ2 = 0;
   fDiffJ2H = zeros(3,1);
end

% Time info
%----------
jD   = JD2000;
w0   = OrbRate( el0(1) );
T    = 2*pi/w0;
dT   = T/nSPO;
tF   = round(nOrbits*T/dT)*dT;

% Sample
%-------
sampleRate = 1;
nS         = ceil(tF/dT/sampleRate);

% Intial states
%--------------
el1   = OrbElemDiff( -el0, dEl0, 1 );
[r,v] = El2RV( Alfriend2El(el0) ); 
x0    = [r;v];
[r,v] = El2RV( Alfriend2El(el1) );
x1    = [r;v];

% Initilize variables
%--------------------
d.time          = zeros(1,nS);
d.rE            = zeros(3,nS);
d.vE            = zeros(3,nS);
d.rE_est        = zeros(3,nS);
d.vE_est        = zeros(3,nS);
d.rH            = zeros(3,nS);
d.vH            = zeros(3,nS);
d.rH_est        = zeros(3,nS);
d.vH_est        = zeros(3,nS);
d.dElMean       = zeros(6,nS);
d.dElMean_est   = zeros(6,nS);
d.elRefMean_est = zeros(6,nS);
d.dElMean_avg   = zeros(6,nS);
d.elRefMean_avg = zeros(6,nS);
distarray       = zeros(3,nS);

t      = 0;
i      = 1;
k      = 1;
j      = 0;

d.nManeuvers         = 0;

% initialize noise data
%----------------------
absPosNoise = 0;
absVelNoise = 0;
relPosNoise = 0;
relVelNoise = 0;

% differential drag force terms
%------------------------------
if( drag )
   Cd          = 2;
else
   aECI_drag_0 = zeros(3,1);
   aECI_drag_1 = zeros(3,1);
   fDiffDragH  = zeros(3,1); 
end

% differential solar force terms
%-------------------------------
if( solar )
   coefFrac = [.27 .24333 .48667 0]';
else
   aECI_solar_0 = zeros(3,1);
   aECI_solar_1 = zeros(3,1);
   fDiffSolarH  = zeros(3,1);
end

% cross-sectional area of reference and relative
%  (used when computing solar and drag forces)
%-----------------------------------------------
area0 = area(1);
area1 = area(2);

areaRatio = area1/area0;
massRatio = mass1/mass0;

% for keeping track of how much time is left
%-------------------------------------------
nextOrbit = 0;
tic

% basic orbit RHS
rhs = @(x,a) [x(4:6); a - (3.98600436e5)*x(1:3)/norm(x(1:3))^3];

% orbit RHS with J2 perturbation
if( J2 )
   rhsJ2 = @(x,t,aExt) OrbitRHS_J2( x, aExt, t, jD, gM );
end

% Simulation
%-----------
while( t < tF )
   
   % terms for convenience
   %----------------------
   dx  = x1 - x0;
   rE  = x0(1:3,1);
   vE  = x0(4:6,1);
   drE = dx(1:3,1);
   dvE = dx(4:6,1);
      
   % Estimated Absolute and Relative State (ECI)
   %-------------------------------------------
   rE_est  =  rE + absPosNoise;
   vE_est  =  vE + absVelNoise;
   drE_est = drE + relPosNoise;
   dvE_est = dvE + relVelNoise;
   
   % Estimated Relative State (Hills)
   %-------------------------------------------
   [rH_est,vH_est] = AbsRelECI2Hills( rE_est, vE_est, drE_est, dvE_est );
   
   % Estimated Orbital Elements
   %-------------------------------------------
   xE_est      = [rE_est;   vE_est];
   dxE_est     = [drE_est; dvE_est];
   [elRefMean_est,dElMean_est] = ECI2MeanElements( xE_est, dxE_est, J2 );
      
   % Desired Relative State - assume circular
   %-------------------------------------------
   xH_des = Goals2Hills( elRefMean_est, goals );
   dElMean_des = Hills2DeltaElem( elRefMean_est, xH_des );
   rH_des = xH_des(1:3,1);
   vH_des = xH_des(4:6,1);
   
    
   % ECI to Hills quaternion (for future computations)
   %------------------------
   qEH            = QHills(rE,vE);                 
   
   dist_force = zeros(3,1);
   % Compute Differential Drag acceleration
   %-------------------------------------------
   if( drag )
      backECI     = QTForm( qEH, [0;-1;0] );       % unit vector in ECI, pointing backwards along-track

      % check if backECI == -Unit(vE)
      
      alt         = real(Altitude( rE*1e3 ))*1e-3;
      rho         = AtmDens2(alt);                 % [kg/m^3]
      v02         = power(Mag(vE)*1e3,2);          % [m/s]^2
      v12         = power(Mag(vE+dvE)*1e3,2);      % [m/s]^2
      
      fDrag0      = 0.5*rho*v02*Cd*area0;        % drag force experienced by reference
      fDrag1      = 0.5*rho*v12*Cd*area1;        % drag force experienced by relative
      aECI_drag_0 = fDrag0*backECI/mass0*1e-3;    % acceleration due to drag on reference
      aECI_drag_1 = fDrag1*backECI/mass1*1e-3;    % acceleration due to drag on relative

      fDiffDragH  = QForm(qEH,aECI_drag_1*mass1 - aECI_drag_0*mass0);
      dist_force  = fDiffDragH;
  end
   
   % Compute differential solar force and acceleration
   %--------------------------------------------------
   if( solar )
      [uS, rS]     = SunV1( jD+t/86400, rE );
      rSunE        = uS*rS;
      source       = Unit(rSunE - rE);
      ecl          = Eclipse( rE, rSunE );      
      aECI_solar_0 = ecl*SolarF( solarPressure, coefFrac, source, source, area0 )/mass0;
      aECI_solar_1 = aECI_solar_0*areaRatio/massRatio;

      fDiffSolarH  = QForm(qEH,aECI_solar_1*mass1 - aECI_solar_0*mass0);
      dist_force   = dist_force + fDiffSolarH;
      
  end

  % compute differential J2 force
  %------------------------------
  if( recordJ2 )
     aECI_0       = aECI_drag_0 + aECI_solar_0;
     aECI_1       = aECI_drag_1 + aECI_solar_1;
     deltaxdot0   = rhsJ2(x0,t,aECI_0) - rhs(x0,aECI_0);
     deltaxdot1   = rhsJ2(x1,t,aECI_1) - rhs(x1,aECI_1);
     xdotdist     = deltaxdot1 - deltaxdot0;

     fDiffJ2H     = QForm(qEH,xdotdist(4:6)) * mass1;
     dist_force   = dist_force + fDiffJ2H;     
  end
  
  
   % Integrate orbit states
   %-----------------------
   aECI_0 = [0;0;0];
   aECI_1 = [0;0;0];
   if( J2 )
      x0 = RK4(rhsJ2,x0,dT,t, aECI_0 );
      x1 = RK4(rhsJ2,x1,dT,t, aECI_1 );
   else
      x0 = RK4TI(rhs,x0,dT,aECI_0);
      x1 = RK4TI(rhs,x1,dT,aECI_1);
   end

   % Store data
   %-----------
   if( j == 0 )
               
      rH = rH_est;
      vH = vH_est;
      dElMean = dElMean_est;
      
      
      d.rE(:,k)            = rE;
      d.vE(:,k)            = vE;
      d.rE_est(:,k)        = rE_est;
      d.vE_est(:,k)        = vE_est;
      d.rH(:,k)            = rH;
      d.vH(:,k)            = vH;
      d.rH_est(:,k)        = rH_est;
      d.vH_est(:,k)        = vH_est;
      d.rH_des(:,k)        = rH_des;
      d.vH_des(:,k)        = vH_des;
      d.dElMean(:,k)       = dElMean';
      d.dElMean_est(:,k)   = dElMean_est';
      d.dElMean_des(:,k)   = dElMean_des';
      d.elRefMean_est(:,k) = elRefMean_est';
      d.fDiffDragH(:,k)    = fDiffDragH;
      d.fDiffDragE(:,k)    = QTForm(qEH,fDiffDragH);
      d.fDiffSolarH(:,k)   = fDiffSolarH;
      d.fDiffSolarE(:,k)   = QTForm(qEH,fDiffSolarH);
      d.fDiffJ2H(:,k)      = fDiffJ2H;
      d.fDiffJ2E(:,k)      = QTForm(qEH,fDiffJ2H);
      
      d.time(k)            = t;
      distarray(:,k)       = dist_force; 
      
      j = sampleRate;
      k = k + 1;
      
   end
   
   % Increment time
   %---------------
   t  = t + dT;
   i  = i + 1;
   j  = j - 1;
      
   % Display Status
   %---------------
   if( t/T > nextOrbit )
      rate     = t/toc;
      timeToGo = (nOrbits*T - t)/rate;
      
      if( timeToGo > 0 )
         hours    = floor(timeToGo/3600);
         timeToGo = timeToGo - 3600*hours;
         minutes  = floor(timeToGo/60);
         timeToGo = timeToGo - 60*minutes;
         seconds  = floor(timeToGo);
         fprintf(1,'%2.1f orbits remaining ... should be done in %d hours, %d minutes, %d seconds\n',...
           nOrbits-nextOrbit,hours,minutes,seconds);
         nextOrbit = nextOrbit + 1;
      end
   end

end

d.time = d.time/T;

d.meanDistMag = mean(Mag(distarray));
d.meanDistX   = mean(distarray(1,:));
d.meanDistY   = mean(distarray(2,:));
d.meanDistZ   = mean(distarray(3,:));

simData = d;

if( nargout < 1 )
   FFSimPlotter(simData);
end


%--------------------------------
% Orbit RHS with J2
%--------------------------------
function xdot = OrbitRHS_J2( x, aExt, t, jD, gM )

% Find the ECI to EF matrix
%--------------------------
cECIToEF = ECIToEF( JD2T( jD + t/86400 ) );
rEF      = cECIToEF*x(1:3);
r        = Mag( x(1:3) );

% Compute the gravitational acceleration
%---------------------------------------
lambda   = atan2( rEF(2), rEF(1) );
theta    = acos( rEF(3)/r );
aEFSph   = AGravity( 2, 0, r, lambda, theta, gM );
aEF      = RPhiTheta2Cart(rEF)*aEFSph;
xdot     = [x(4:6);cECIToEF'*aEF + aExt];


%--------------------------------------
% $Date: 2020-05-29 16:41:11 -0400 (Fri, 29 May 2020) $
% $Revision: 52562 $
