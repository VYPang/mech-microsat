%% Example CubeSat disturbance analysis
% Demonstrate how to use CubeSatDisturbanceAnalysis to calculate disturbances
% over an orbit. The spacecraft is nadir-pointing along a LEO orbit. Some
% surfaces are given solar cell optical properties and some radiator properties.
%
% See also QLVLH, CubeSatDisturbanceAnalysis, RHSCubeSat, Period, 
% RVFromKepler, OpticalSurfaceProperties, Figui, AU2Q, QMult, Date2JD

%--------------------------------------------------------------------------
%   Copyright (c) 2017 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2017.1
%--------------------------------------------------------------------------

% CubeSat model - default in RHS.
% This is a 1U with body-mounted solar panels on +/- x faces.
d = RHSCubeSat;

% Introduce some CM offset (m)
d.surfData.cM = [0.02;0.02;0];

% Initialize a polar LEO orbit
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

% Epoch
jD = Date2JD([2013 4 2 0 0 0]) + t/86400;

% Differentiate the optical properties for solar cells and radiator panels
solarOpt = OpticalSurfaceProperties('solar cell');
pSolar = [solarOpt.sigmaA;solarOpt.sigmaS;solarOpt.sigmaD];

radOpt = OpticalSurfaceProperties('radiator');
pRadiator = [radOpt.sigmaA;radOpt.sigmaS;radOpt.sigmaD];

d.surfData.sigma = [pSolar pSolar pRadiator pSolar pSolar pRadiator];

% Residual magnetic dipole (ATM^2)
d.dipole = [0;0;0.01];

CubeSatDisturbanceAnalysis( d, q, r, v, jD );
Figui;


%--------------------------------------
% $Date: 2019-09-07 17:12:12 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49734 $