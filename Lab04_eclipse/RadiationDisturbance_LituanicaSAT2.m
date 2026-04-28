% "RadiationDisturbance_LituanicaSAT2.m"
% modified by Pokwang Kwan, MAE, HKUST
% 14aug17

%% Radiation pressure disturbance demo.
% Compute the radiation pressure force and torque for a complete orbit in
% LEO, assuming an offset from LVLH pointing. The disturbances are calculated
% both with and without the planetary components (albedo and radiation).
%
% Things to try:
%
%   1. Change the optical coefficients
%   2. Different center of mass
%   3. Higher or lower orbital altitude.
%
% Since version 2014.1
%
%  ----------------------------------------------------------------------
%  See also CubeSatRadiationPressure, Eclipse
%  ----------------------------------------------------------------------
%%
%------------------------------------------------------------------------
%   Copyright (c) 2009, 2014 Princeton Satellite Systems, Inc.
%   All rights reserved.
%------------------------------------------------------------------------
% 2016.0.1 - Initialize p from CubeSatEnvironment to have correct fields 
% including q
%------------------------------------------------------------------------

%{
LituanicaSAT-2 example:

Size:             3U
Launch date:      23 June 2017, 03:59 UTC
Rocket:           PSLV-XL C38
Launch site:      Satish Dhawan FLP
Contractor:       ISRO
Reference system: Geocentric
Regime:           Sun-synchronous
Perigee:          802.3 km (314 mi)
Apogee:           816.1 km (314 mi)
Inclination:      98.5 degrees
Period:           100.9 minutes
Put in orbit:     23 minutes 18.94 seconds after lift-off
%}

%   d         (.)    Surface data structure
%                    .nFace      (3,:) Face outward unit normals
%                    .rFace      (3,:) Face vectors with respect to the origin
%                    .cM         (3,1) Center of mass with respect to the orgin
%                    .area       (1,:) Area of each face

%% Orbit and ephemeris
% Orbit (specifications)
altitude    = 768.6;              % km       % <--- Orbit information
radiusEarth = 6378.165;         % km
inc         = 51.6392*pi/180;     % deg      % <--- Launched from Satish Dhawan FLP
sma = 6781.117;
el = [sma inc 0 0 0 0];

% Orbit date and time: [year month day hour minute seconds]
OrbitDateTime = [2017 05 17 08 38 36];

% Generate the data structure template for a CubeSat
d = CubeSatRadiationPressure;

% Provide an attitude offset from LVLH
d.att.type        = 'lvlh';
d.att.qLVLHToBody = AU2Q( 0.1, -[1;1;1] );

% Specify CubeSat geometry
%   d         (.)    Surface data structure
%                    .nFace      (3,:) Face outward unit normals
%                    .rFace      (3,:) Face vectors with respect to the origin
%                    .cM         (3,1) Center of mass with respect to the orgin
%                    .area       (1,:) Area of each face

% Centre of Mass of CubeSat body
d.cM = [0; 0.005; 0]; % Assumed center of mass matrix for AAUSAT3

% CubeSat surface area (one element for each facet)
Area1U = 0.1*0.1;               % 1U face area in m^2
Area3U = 0.1*0.3;               % 3U face area in m^2
cellArea = 30.18 / 10000;       % Convert cm² to m²
cellsPerPanel = 2;              % Two cells in series per panel
panelArea = cellArea * cellsPerPanel; % Total active area per panel

% We have 6 CubeSat body faces (assuming 3U: two 1U ends, four 3U sides)
% plus 8 faces for 4 double-sided solar panels.
bodyAreas  = [Area3U, Area3U, Area3U, Area3U, Area1U, Area1U];
panelAreas = repmat(panelArea, 1, 8);
d.area = [bodyAreas, panelAreas];

% Specify CubeSat geometry outward normals (d.nFace)
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
d.nFace = [bodyNormals, panelNormals];

% Face vectors with respect to the origin (dimensions in metre)
% Centroid of each face with respect to the centroid of the body
bodyCentroids = [
    0.05, -0.05,     0,     0,     0,      0;
       0,     0,  0.05, -0.05,     0,      0;
       0,     0,     0,     0,  0.15,  -0.15
];

% Panels are assumed to be deployed outside of the main body, approx at offsets.
% Example: 4 panels at x = +/- 0.1, y = +/- 0.1, with their 2 sides each
panelCentroids = [
    0.1,  0.1,   -0.1, -0.1,      0,      0,      0,      0;
      0,    0,      0,    0,    0.1,    0.1,   -0.1,   -0.1;
      0,    0,      0,    0,      0,      0,      0,      0
];
d.rFace = [bodyCentroids, panelCentroids];


% Specify some absorption and some reflection. The coefficients are
% expressed as [absorbed;specular;diffuse] with one column per face.
NoOfPanels = length(d.area);
d.sigma = [0.2*ones(1,NoOfPanels);0.8*ones(1,NoOfPanels);zeros(1,NoOfPanels)];

% Data structure for a second computation with planetary disturbances off
d2 = d;    % same CubeSat data
d2.planet = 0;    % flag planetary disturbances <-- planetary disturbances off

% Generate a environment data structure
p = CubeSatEnvironment;
sma_base = 6781.117;
inc_base_deg = 51.6392;

%% Parametric Study: Force Magnitude
figure('Position', [100, 100, 600, 800], 'Name', 'Force Magnitude'); 
set(gcf, 'DefaultAxesFontName', 'Times New Roman');
set(gcf, 'DefaultTextFontName', 'Times New Roman');
colors = lines(5);

% 1. Altitude Variation (SMA)
sma_list = sma_base + [-200, -100, 0, 100, 200];
subplot(2,1,1);
hold on;
labels_sma = cell(1,5);

for i = 1:5
    sma_i = sma_list(i);
    el_i = [sma_i inc_base_deg*pi/180 0 0 0 0];
    [r_i, v_i, t_i] = RVFromKepler(el_i);
    [p.uSun, rSun]  = SunV1(Date2JD(OrbitDateTime));
    
    force   = zeros(3, length(t_i));
    for k = 1:length(t_i)
        p.v = v_i(:,k);
        p.r = r_i(:,k);
        p.n = Eclipse( p.r, p.uSun*rSun);
        [force(:,k), ~] = CubeSatRadiationPressure( p, d ); % With planetary
    end
    
    f_mag = sqrt(sum(force.^2, 1)) * 1e6; % micro-Newtons
    plot(t_i / Period(sma_i), f_mag, 'Color', colors(i,:), 'LineWidth', 1.5);
    
    diff_sma = sma_i - sma_base;
    if abs(diff_sma) < 1e-3
        labels_sma{i} = sprintf('Baseline (%.1f km)', sma_i);
    else
        labels_sma{i} = sprintf('%+.0f km (%.1f km)', diff_sma, sma_i);
    end
end
hold off; grid on;
xlabel('Orbit'); ylabel('Force Magnitude (\muN)');
title('Radiation Pressure force with Varying Altitude');
legend(labels_sma, 'Location', 'best');

% 2. Inclination Variation
inc_list_deg = inc_base_deg + [-40, -20, 0, 20, 40];
subplot(2,1,2);
hold on;
labels_inc = cell(1,5);

for i = 1:5
    inc_deg = inc_list_deg(i);
    el_i = [sma_base inc_deg*pi/180 0 0 0 0];
    [r_i, v_i, t_i] = RVFromKepler(el_i);
    [p.uSun, rSun]  = SunV1(Date2JD(OrbitDateTime));
    
    force   = zeros(3, length(t_i));
    for k = 1:length(t_i)
        p.v = v_i(:,k);
        p.r = r_i(:,k);
        p.n = Eclipse( p.r, p.uSun*rSun);
        [force(:,k), ~] = CubeSatRadiationPressure( p, d );
    end
    f_mag = sqrt(sum(force.^2, 1)) * 1e6; % micro-Newtons
    plot(t_i / Period(sma_base), f_mag, 'Color', colors(i,:), 'LineWidth', 1.5);
    
    diff_inc = inc_deg - inc_base_deg;
    if abs(diff_inc) < 1e-3
        labels_inc{i} = sprintf('Baseline (%.1f deg)', inc_deg);
    else
        labels_inc{i} = sprintf('%+.0f deg (%.1f deg)', diff_inc, inc_deg);
    end
end
hold off; grid on;
xlabel('Orbit'); ylabel('Force Magnitude (\muN)');
title('Radiation Pressure Torque with Varying Inclination');
legend(labels_inc, 'Location', 'best');

%% Parametric Study: Torque Magnitude
figure('Position', [750, 100, 600, 800], 'Name', 'Torque Magnitude'); 
set(gcf, 'DefaultAxesFontName', 'Times New Roman');
set(gcf, 'DefaultTextFontName', 'Times New Roman');

% 1. Altitude Variation (SMA) for Torque
subplot(2,1,1);
hold on;
for i = 1:5
    sma_i = sma_list(i);
    el_i = [sma_i inc_base_deg*pi/180 0 0 0 0];
    [r_i, v_i, t_i] = RVFromKepler(el_i);
    [p.uSun, rSun]  = SunV1(Date2JD(OrbitDateTime));
    
    torque   = zeros(3, length(t_i));
    for k = 1:length(t_i)
        p.v = v_i(:,k);
        p.r = r_i(:,k);
        p.n = Eclipse( p.r, p.uSun*rSun);
        [~, torque(:,k)] = CubeSatRadiationPressure( p, d ); % With planetary
    end
    
    t_mag = sqrt(sum(torque.^2, 1)) * 1e6; % micro-Nm
    plot(t_i / Period(sma_i), t_mag, 'Color', colors(i,:), 'LineWidth', 1.5);
end
hold off; grid on;
xlabel('Orbit'); ylabel('Torque Magnitude (\muNm)');
title('Radiation Pressure Torque with Varying Altitude');
legend(labels_sma, 'Location', 'best');

% 2. Inclination Variation for Torque
subplot(2,1,2);
hold on;
for i = 1:5
    inc_deg = inc_list_deg(i);
    el_i = [sma_base inc_deg*pi/180 0 0 0 0];
    [r_i, v_i, t_i] = RVFromKepler(el_i);
    [p.uSun, rSun]  = SunV1(Date2JD(OrbitDateTime));
    
    torque   = zeros(3, length(t_i));
    for k = 1:length(t_i)
        p.v = v_i(:,k);
        p.r = r_i(:,k);
        p.n = Eclipse( p.r, p.uSun*rSun);
        [~, torque(:,k)] = CubeSatRadiationPressure( p, d );
    end
    t_mag = sqrt(sum(torque.^2, 1)) * 1e6; % micro-Nm
    plot(t_i / Period(sma_base), t_mag, 'Color', colors(i,:), 'LineWidth', 1.5);
end
hold off; grid on;
xlabel('Orbit'); ylabel('Torque Magnitude (\muNm)');
title('Torque Magnitude vs Orbit with Varying Inclination');
legend(labels_inc, 'Location', 'best');


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2016-06-17 14:25:16 -0400 (Fri, 17 Jun 2016) $
% $Revision: 42659 $