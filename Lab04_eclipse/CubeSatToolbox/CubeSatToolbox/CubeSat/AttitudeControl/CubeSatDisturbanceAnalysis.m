function [tT, fECI, h, hECI,force,torque,power] = CubeSatDisturbanceAnalysis( d, q, r, v, jD )

%% CubeSat disturbance analysis from batch data using RHSCubeSat. 
%
% Compute the drag, magnetic, gravity gradient, and optical disturbances. The
% environment is computed using AtmJ70, BDipole, and SunV1. AtmDens2
% can be used instead by supplying an empty matrix for d.atm.
%
% The built-in demo computes the disturbances on a 3U satellite for one day.
% The center of mass is assumed to be offset from the geometric center of the
% spacecraft by a few cm. Note the growth in momentum. the gravity gradient
% torque is zero in the demo because the attitude entered is perfect LVLH and
% the inertia is symmetric.
%------------------------------------------------------------------------
%   Form:
%   [tT, fECI, h, hECI, f, t, power] = CubeSatDisturbanceAnalysis( d, q, r, v, jD )
%   CubeSatDisturbanceAnalysis  % demo
%------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d        (.)      Data structure from RHSCubeSat
%   q       (4,:)     Quaternion, ECI to body
%   r       (3,:)     Position vector
%   v       (3,:)     Velocity vector
%   jD      (1,:)     Julian dates
%
%   -------
%   Outputs
%   -------
%   tT      (3,:)   Torque in body (Nms)
%   fECI    (3,:)   Force in ECI (N)
%   h       (3,:)   Body momentum (Nms)
%   hECI    (3,:)   ECI momentum (Nms)
%   torque   (.)    Torque structure
%                     .total   (3,:)  Torque in body frame
%                     .aero    (3,:)  Aerodynamic torque
%                     .mag     (3,:)  Magnetic torque
%                     .optical (3,:)  Optical torque
%                     .gg      (3,:)  Gravity gradient torque
%   force    (.)    Force structure
%                    .total   (3,:)  Force in ECI frame
%                    .aero    (3,:)  Aerodynamic force
%                    .optical (3,:)  Optical force
%
%------------------------------------------------------------------------
%   See also CubeSatAero, CubeSatRadiationPressure, GravityGradientFromR,
%   RHSCubeSat
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc.
%   All rights reserved.
%------------------------------------------------------------------------
% Since version 10.
% 2016.1 Update to use RHSCubeSat rather than a custom struct and code.
%------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d      = RHSCubeSat;
  t      = linspace(0,24,1000)*3600;
  el     = [7100 pi/2 0 0 0 0];
  [r, v] = RVFromKepler( el, t );
  % LVLH - align z axis with nadir
  q      = QLVLH( r, v );
  % Introduce some quaternion offset for more interesting results
  qDelta = AU2Q( 0.1*sin(t/Period(7100)), [1;1;1] );
  for k = 1:length(t)
    q(:,k) = QMult(q(:,k),qDelta(:,k));
  end
  jD = Date2JD([2013 4 2 0 0 0]) + t/86400;
  % Introduce some CM offset (m)
  d.surfData.cM = [0.02;0.02;0];
  % differentiate the optical properties
  solarOpt = OpticalSurfaceProperties('solar cell');
  pSolar = [solarOpt.sigmaA;solarOpt.sigmaS;solarOpt.sigmaD];
  radOpt = OpticalSurfaceProperties('radiator');
  pRadiator = [radOpt.sigmaA;radOpt.sigmaS;radOpt.sigmaD];
  d.surfData.sigma = [pSolar pSolar pRadiator pSolar pSolar pRadiator];
  % Residual magnetic dipole (ATM^2)
  d.dipole = [0;0;0.01];
  CubeSatDisturbanceAnalysis( d, q, r, v, jD );
  Figui;
  clear t;
  return
end

% Calculation
%------------
n          = length(jD);
h          = zeros(3,n);
time       = (jD - jD(1))*86400;
d.jD0      = jD(1);
d.surfData.att.type = 'eci';
x0         = [r(:,1);v(:,1);q(:,1);0;0;0;0];
[~,dist,~] = RHSCubeSat( x0, time(1), d );
dists(n)   = dist; % serves to preallocate array
powers(n)  = 0;

for k = 1:n
  x = [r(:,k);v(:,k);q(:,k);0;0;0;0];
  [~,dist,power] = RHSCubeSat( x, time(k), d );
  dists(k) = dist;
  powers(k) = power;
  
  % Momentum in the body frame
  %---------------------------
  if k>1
    h(:,k) = h(:,k-1) + dists(k-1).tTotal*(time(k) - time(k-1));
  end
end

fS   = [dists(:).fOptical];
tS   = [dists(:).tOptical];
fD   = [dists(:).fAerodyn];
tD   = [dists(:).tAerodyn];
tGG  = [dists(:).tGG];
tRD  = [dists(:).tMag];
tT   = [dists(:).tTotal];
fECI = [dists(:).fTotal];
rho  = [dists(:).rho];
b    = [dists(:).bField];

% Transform into the ECI frame
%-----------------------------
hECI = QTForm( q, h );

% Default output
%---------------
if( nargout < 1 )
  [s,sL] = TimeLabl( time );
  Plot3D( r, [],[],[], 'CubeSat Orbit');
  PlotPlanet([0;0;0],6378);
  AxesCart(6400,6400,6400);
  view(150,30);

  Plot2D( s, q, sL, 'q', 'CubeSat Quaternion')
  legend('q_s','q_x','q_y','q_z')
  Plot2D( s, b,  sL, {'B_x (T)' 'B_y (T)', 'B_z (T)'}, 'CubeSat B Field')
  yL = {'v_x','v_y','v_z' '\rho (kg/m^3)'};   
	Plot2D( s, [v;rho],  sL, yL, 'CubeSat Velocity and Atmospheric Density')

  yL = {'T_x (\mu Nm)','T_y (\mu Nm)','T_z (\mu Nm)'};
  Plot2D( s, tT *1e6, sL, yL, 'CubeSat Torque Total')
  Plot2D( s, tGG*1e6, sL, yL, 'CubeSat Torque Gravity Gradient')
  Plot2D( s, tRD*1e6, sL, yL, 'CubeSat Torque Residual Dipole')
  Plot2D( s, tD*1e6,  sL, yL, 'CubeSat Torque Drag')
  Plot2D( s, tS*1e6,  sL, yL, 'CubeSat Torque Optical')

  yL = {'F_x (\mu N)','F_y (\mu N)','F_z (\mu N)'};
  Plot2D( s, fECI*1e6, sL, yL, 'CubeSat ECI Force Total')
  Plot2D( s, fD*1e6, sL, yL, 'CubeSat Force Drag')
  Plot2D( s, fS*1e6, sL, yL, 'CubeSat Force Optical')

  yL = {'H_x (mNms)','H_y (mNms)','H_z (mNms)'};
  Plot2D( s, h*1e3, sL, yL, 'CubeSat Body Momentum')
  Plot2D( s, [hECI;Mag(hECI)]*1e3, sL, [yL,{'|H|'}], 'CubeSat ECI Momentum')
  
  Plot2D( s, powers, sL, 'Power (W)', 'Solar Power')
  clear t;
end

if nargout > 4
  torque = struct;
  torque.total = tT;
  torque.aero = tD;
  torque.gg   = tGG;
  torque.optical = tS;
  torque.mag     = tRD;
  force = struct;
  force.total = fECI;
  force.aero = fD;
  force.optical = fS;
end


%--------------------------------------
% $Date: 2019-11-07 14:27:23 -0500 (Thu, 07 Nov 2019) $
% $Revision: 50274 $
