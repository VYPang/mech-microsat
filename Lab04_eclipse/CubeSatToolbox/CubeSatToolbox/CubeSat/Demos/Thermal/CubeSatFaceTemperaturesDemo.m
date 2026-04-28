%% Demonstrate temperatures of faces of a CubeSat
% The default flux is 45 degrees above the xy-plane. The conductivity 
% matrix between panels is zero except for between +X and -Z. 
% It you make dT too large you will run into numerical integration issues.
%
%--------------------------------------------------------------------------
%   Copyright (c) 2019 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------


%% Incoming flux
a             = linspace(0,8*pi,1500);
n             = length(a);
p             = 0.7071*1367*[cos(a);sin(a);zeros(1,n)]; % Solar flux

%% Set up the thermal model
d             = RHSIsothermalCubeSat; % Get defaults
d.mass        = ones(1,6)/6; % Make each panel separate
d.powerTotal  = [0.5 0.5 0 0 0 0]; % Internal power on each panel
d = AddThermalConductivity(d,1,6,0.3); % Add a thermally conductive channel between faces 1 and 6. Watts/Kelvins

tP            = zeros(n,6);
tK            = 300*ones(1,6); % Initial temperatures

%% Propagate
dT            = 1; % sec
for k = 1:n-1
  tP(k,:) = tK;
  tK      = RK4(@RHSIsothermalCubeSat,tK,dT,0,d,p(:,k));
end
tP(n,:) = tK;

%% Plot
[t,tL] = TimeLabl((0:n-1)*dT);

yL = {'T_{+X} (deg-K)' 'T_{-X} (deg-K)' 'T_{+Y} (deg-K)'...
      'T_{-Y} (deg-K)' 'T_{+Z} (deg-K)' 'T_{-Z} (deg-K)'...
      'p_x (W/m^2)' 'p_y (W/m^2)' 'p_z (W/m^2)'};
Plot2D(t,tP',tL,yL(1:6),'Panel Temperatures');
Plot2D(t,p, tL,yL(7:9),'Incoming Flux Vector');


%--------------------------------------
% $Date: 2019-07-15 12:57:52 -0400 (Mon, 15 Jul 2019) $
% $Revision: 49279 $



