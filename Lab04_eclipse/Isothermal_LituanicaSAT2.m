% "Isothermal_LituanicaSAT2.m"
% modified by Pokwang Kwan, MAE, HKUST
% 14aug17

%% Isothermal satellite demo
% The entire CubeSat is assumed to be at the same temperature. This is a
% very useful first approximation of the spacecraft temperatures on orbit.
% The oscillations in the temperatute reflect the eclipses.
%
% Model a 3U satellite with different materials comprising the faces. Each
% area is 1U for a total of 14 surfaces. The surfaces are either solar
% cell, gold foil, or radiator.
%
% See also RHSThermalCubeSat.
%%
%------------------------------------------------------------------------
%   Copyright (c) 2009-2010,2014 Princeton Satellite Systems, Inc.
%   All rights reserved.
%------------------------------------------------------------------------

% CubeSat thermal properties
%   d      (1,1)     Data structure
%                    .mass       (1,1) Total mass
%                    .uSurface   (3,6) Surface unit vectors
%                    .alpha      (1,6) Absorptivity
%                    .epsilon    (1,6) Emissivity
%                    .area       (1,6) Area
%                    .cP         (1,1) Specific heat
%                    .powerTotal (1,1) Internal power (W)

% Solar panel geometry
%   d      (1,1)     Data structure
%                    .massComponents       (1,1) mass of components
%                    .solarPanel.dim       (1,3) [width, length, thickness]
%                    .solarPanel.nPanels       (1,1) number of solar cells per panels
%                    .solarPanel.rPanel       (3,4) distance of panels from centre of mass
%                    .solarPanel.sPanel       (3,4) direction of each panels
%                    .solarPanel.cellNormal       (3,4) normal of each panels

% Date and time
%   datetime      (1,6) [year month day hour minute seconds]

%% Geometry and properties of CubeSat
%{
LituanicaSAT-2 example:

Size:             3U
Launch date:      23 June 2017, 03:59 UTC
Rocket:           PSLV-XL C38
Launch site:      Satish Dhawan FLP
Contractor:       ISRO
Reference system: Geocentric
Regime:           Sun-synchronous
Perigee:          505 km (314 mi)
Apogee:           505 km (314 mi)
Inclination:      97.44 degrees
Period:           94.72 minutes
Put in orbit:     23 minutes 18.94 seconds after lift-off
%}
% 14 facets on the 3U CubeSat main body + solar panels

% Spacecraft model - 3U with various materials.
% The +/- Z ends are assumed to have radiators. The specific heat of aluminum
% is used as a good approximation for the bulk spacecraft properties.

% solar Cell properties
aC = 0.91;    % absorptivity
eC = 0.82;    % emissivity
% Goldized Kapton properties
aG = 0.3;    % absorptivity
eG = 0.04;    % emissivity
% Radiators
aR = 0.15;    % absorptivity
eR = 0.8;    % emissivity

% Orbit date and time: [year month day hour minute seconds]
OrbitDateTime = [2017 05 17 08 38 36];

% Generate the data structure for CubeSat 
d = CubeSatModel( 'struct' );
cube = '1U';    % CubeSat size

% mass of CubeSat
d.mass = 1;    % total
d.massComponents = 0.8;    % interior component


% Surface area of each surface panel
% E, W, N, S, U, D, and the solar panels deployed
Area1U = 0.1*0.1;    % area in m^2
cellArea = 30.18 / 10000; % Convert cm� to m�
cellsPerPanel = 2; % Two cells in series per panel
panelArea = cellArea * cellsPerPanel; % Total active area per panel

% Surface area configuration
Area1U = 0.1*0.1;               % 1U face area in m^2
Area3U = 0.1*0.3;               % 3U face area in m^2

cellArea = 30.18 / 10000;       % Convert cm^2 to m^2
cellsPerPanel = 2;              % Two cells in series per panel
panelArea = cellArea * cellsPerPanel; % Total active area per panel

% We have 6 CubeSat body faces (assuming 3U: two 1U ends, four 3U sides)
% plus 8 faces for 4 double-sided solar panels.
bodyAreas  = [Area3U, Area3U, Area3U, Area3U, Area1U, Area1U];
panelAreas = repmat(panelArea, 1, 8);
d.area = [bodyAreas, panelAreas];

% Surface normal of each panel (one element for each external side of the panel)
% 6 faces for the CubeSat body (+x, -x, +y, -y, +z, -z)
bodyNormals = [
    1, -1,  0,  0,  0,  0;
    0,  0,  1, -1,  0,  0;
    0,  0,  0,  0,  1, -1
];

% 4 double-sided solar panels (8 faces). Assuming they face +/- x and +/- y 
panelNormals = [
    1, -1,  0,  0,  1, -1,  0,  0;
    0,  0,  1, -1,  0,  0,  1, -1;
    0,  0,  0,  0,  0,  0,  0,  0
];

d.uSurface = Unit([bodyNormals, panelNormals]);

% Thermal properties of each surface panel
% Assuming the body has Goldized Kapton (aG, eG) and radiators at ends (aR, eR)
% and solar arrays are solar cells (aC, eC)
d.alpha   = [aG, aG, aG, aG, aR, aR, repmat(aC, 1, 8)]; 
d.epsilon = [eG, eG, eG, eG, eR, eR, repmat(eC, 1, 8)];


% Specific heat for whole spacecraft
d.cP         = 900;

% Power consumption (W) - internal power that is generated and absorbed by the spacecraft
d.powerTotal = 3;

%% Orbit and ephemeris

% Orbit parameters
altitude    = 768.6;              % km       % <--- Orbit information
radiusEarth = 6378.165;         % km
inc         = 51.6392*pi/180;     % deg      % <--- Launched from Satish Dhawan FLP

% Orbit (calcuations)
sma_base = 6781.117;
inc_base_deg = 51.6392;

%% Parametric Studies
figure('Position', [100, 100, 600, 800]); % Tall figure for two subplots
set(gcf, 'DefaultAxesFontName', 'Times New Roman');
set(gcf, 'DefaultTextFontName', 'Times New Roman');
colors = lines(5);

%% 1. Altitude Variation (SMA)
sma_list = sma_base + [-200, -100, 0, 100, 200];
subplot(2,1,1);
hold on;
labels_sma = cell(1,5);

for i = 1:5
    sma_i = sma_list(i);
    el = [sma_i inc 0 0 0 0];
    
    timep_i = Period(sma_i);
    timenP = 3000;
    time_i = linspace(0, 0.5*86400, timenP);    % Simulate exactly 0.5 days (12 hours)
    
    [r_i, v_i] = RVFromKepler( el, time_i );
    q_i        = QLVLH( r_i, v_i );
    jD_i       = Date2JD(OrbitDateTime) + time_i/86400;
    
    t_temp = zeros(1, timenP);
    t_temp(1) = 285; % Initial temperature
    dT_i = (jD_i(2) - jD_i(1))*86400;
    
    for k = 2:timenP
        [uSun, rSun] = SunV1( jD_i(k) );
        flux    = QForm( q_i(:,k), 1367*uSun );
        n_val   = Eclipse( r_i(:,k), rSun*uSun, [0;0;0] );
        if (n_val>0)
            d.powerTotal = 6;
        else
            d.powerTotal = 0.6;
        end
        t_temp(k) = RK4( @RHSIsothermalCubeSat, t_temp(k-1), dT_i, 0, d, n_val*flux );
    end
    
    plot(jD_i - jD_i(1), t_temp, 'Color', colors(i,:), 'LineWidth', 1.5);
    diff_sma = sma_i - sma_base;
    if abs(diff_sma) < 1e-3
        labels_sma{i} = sprintf('Baseline (%.1f km)', sma_i);
    else
        labels_sma{i} = sprintf('%+.0f km (%.1f km)', diff_sma, sma_i);
    end
end
hold off;
grid on;
xlabel('Days');
ylabel('T (deg-K)');
title('Isothermal Temperature with Varying Altitude');
legend(labels_sma, 'Location', 'best');

%% 2. Inclination Variation
inc_list_deg = inc_base_deg + [-40, -20, 0, 20, 40];
subplot(2,1,2);
hold on;
labels_inc = cell(1,5);

for i = 1:5
    inc_deg = inc_list_deg(i);
    inc_i = inc_deg * pi/180;
    el = [sma_base inc_i 0 0 0 0];
    
    timep_i = Period(sma_base);
    timenP = 3000;
    time_i = linspace(0, 0.5*86400, timenP);    % Simulate exactly 0.5 days (12 hours)
    
    [r_i, v_i] = RVFromKepler( el, time_i );
    q_i        = QLVLH( r_i, v_i );
    jD_i       = Date2JD(OrbitDateTime) + time_i/86400;
    
    t_temp = zeros(1, timenP);
    t_temp(1) = 285; % Initial temperature
    dT_i = (jD_i(2) - jD_i(1))*86400;
    
    for k = 2:timenP
        [uSun, rSun] = SunV1( jD_i(k) );
        flux    = QForm( q_i(:,k), 1367*uSun );
        n_val   = Eclipse( r_i(:,k), rSun*uSun, [0;0;0] );
        if (n_val>0)
            d.powerTotal = 6;
        else
            d.powerTotal = 0.6;
        end
        t_temp(k) = RK4( @RHSIsothermalCubeSat, t_temp(k-1), dT_i, 0, d, n_val*flux );
    end
    
    plot(jD_i - jD_i(1), t_temp, 'Color', colors(i,:), 'LineWidth', 1.5);
    diff_inc = inc_deg - inc_base_deg;
    if abs(diff_inc) < 1e-3
        labels_inc{i} = sprintf('Baseline (%.1f deg)', inc_deg);
    else
        labels_inc{i} = sprintf('%+.0f deg (%.1f deg)', diff_inc, inc_deg);
    end
end
hold off;
grid on;
xlabel('Days');
ylabel('T (deg-K)');
title('Isothermal Temperature with Varying Inclination');
legend(labels_inc, 'Location', 'best');


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2014-06-25 14:38:13 -0400 (Wed, 25 Jun 2014) $
% $Revision: 37956 $
