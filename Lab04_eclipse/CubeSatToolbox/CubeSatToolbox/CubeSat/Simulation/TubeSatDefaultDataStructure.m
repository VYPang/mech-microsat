function d = TubeSatDefaultDataStructure( l, jD )

%% Default data structure for TubeSat model.
%--------------------------------------------------------------------------
%   Form:
%   d = TubeSatDefaultDataStructure( l, jD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   l          (1,1)   Either (1,2,3,4) for single, double, triple or quad
%   jD         (1,1)   Julian date for solar data, optional
%
%   ------
%   Outputs
%   ------
%   d          (.)     Data structure
%                      .jD0
%                      .mass
%                      .inertia
%                      .power
%                      .dipole
%                      .surfData, optional; empty to skip drag calcs
%                      .aeroModel
%                      .opticalModel
%                      .atm
%                      .kWheels, empty if no wheels
%                      .inertiaRWA, optional
%                      .tRWA, optional
%
%--------------------------------------------------------------------------
%   See also InertiaTubeSat, TubeSatFaces, RHSCubeSat, SurfaceProperties
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
%   Copyright (c) 2013 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 11.
%   2016.1 - Update to use RHSCubeSat and SurfaceProperties; update power model
%   to use correct faces
%   2016.0.1 Fix function name to be OpticalSurfaceProperties
%--------------------------------------------------------------------------

if nargin < 1
  l = 1;
end
if nargin < 2
  % Default Julian date
  jD = Date2JD([2012 4 5 0 0 0]);
end

d = RHSCubeSat;
d.jD0  = jD; 
d.mass = l*0.75; % kg
d.inertia = InertiaTubeSat(l,d.mass);
d.dipole  = [0;0;0];
[aP, f, fHat, fHat400] = SolarFluxPrediction( d.jD0, 'nominal' );
d.atm.aP      = aP(1); 
d.atm.f       = f(1); 
d.atm.fHat    = fHat(1); 
d.atm.fHat400 = fHat400(1);

% Surface data - 18 faces total
[a,n,r] = TubeSatFaces( l, 1 );
kCells = [1 3 5 7 10 12 14 16]; % faces with solar cells
d.surfData.nFace = n;
d.surfData.rFace = r;
d.surfData.area = a;

optCells = OpticalSurfaceProperties('solar cell');
optGold = OpticalSurfaceProperties('gold foil');
sigma = repmat([optGold.sigmaA;optGold.sigmaS;optGold.sigmaD],1,18);
sigma(:,kCells) = repmat([optCells.sigmaA;optCells.sigmaS;optCells.sigmaD],1,8);

d.surfData.sigma = sigma;

% Power
d.power.solarCellNormal    = n(:,kCells);
d.power.solarCellEff       = 0.27;  % Based on solar modules used
d.power.effPowerConversion = 0.8;   % Based on solar modules used
d.power.solarCellArea      = 0.0954*0.0155*ones(1,8);  
d.power.consumption        = 0.1;   % Based on on board electronics
d.power.batteryCapacity    = 34632; % Joules (2600 mAh, 3.7 V)


%--------------------------------------
% $Date: 2019-09-07 14:57:11 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49731 $
