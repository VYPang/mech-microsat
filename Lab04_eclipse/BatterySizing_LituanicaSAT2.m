%% "BatterySizing_LituanciaSAT2.m"
% modified by Pokwang Kwan, MAE, HKUST
% 14aug17

%% Compute the power storage requirements for a CubeSat.
% Compares the requirements versus a commercial Li-Ion battery
% <http://www.batteryspace.com/polymerli-ionbattery74v830mah614wh10-12cdischargerate.aspx>
%
%   Since version 10.
%  ------------------------------------------------------------------------
%  See also RVFromKepler, Date2JD, JD2T, julianCent, SunV1, Eclipse,
%  SolarCellPower
%  ------------------------------------------------------------------------
%%
%--------------------------------------------------------------------------
%   Copyright (c) 2011 Princeton Satellite Systems.
%   All Rights Reserved.
%--------------------------------------------------------------------------

%% Constants
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

%-----------

% Solar constant
solarFlux   = 1367;             % W        % <--- Average solar flux near Earth

% Orbit parameters
inc         = 51.6392*pi/180;     % deg      % <--- Launched from Satish Dhawan FLP

% Orbit date and time: [year month day hour minute seconds]
OrbitDateTime = [2017 05 17 08 38 36];

% Battery design parameter
dOD         = 0.35;              % Depth of discharge % <--- Desired averaged operating condition, time average
%capacity    = 7.4*0.830;        % W-hr    % <--- Do not see the necessity of this line


%% Semi-major axis
%-----------------
sma         = 6781.117;

%% Input is orbital elements
%---------------------------
[r,v,t]     = RVFromKepler( [sma inc 0 0 0 0] );    % <--- Calculate orbit for Eclipse calculation
m           = length(t);    % <--- Number of steps in time in each orbit.

%% We need the date in Julian Centuries for the sun model
%--------------------------------------------------------
jD0         = Date2JD(OrbitDateTime);
julianCent  = JD2T( jD0 + t/86400 );


%% Data structure defining the solar panels
%------------------------------------------

% Solar cell generation
d.effPowerConversion    = 0.8;
d.solarCellEff          = 0.0841;    % <--- Solar cell manufacturer: EMCORE; model: ZTJM

% Solar panel area
d.solarCellArea = 0.00592 * [6, 6, 0, 0, 2];    % <--- Geometry: (6U facing forward, 6U facing backward, and 2U at top and bottom surface.)

% Solar panel surface normal
d.solarCellNormal = Unit([
    1, -1,  0,  0,  0;  
    0,  0,  1, -1,  0;  
    0,  0,  0,  0,  1]);

                            
%% Initialize the array to save time
%-----------------------------------
p                       = zeros(1,m);
dT                      = t(2) - t(1);
tE                      = 0;
   
for k = 1:m
	[uSun, rSun]	= SunV1( julianCent(k) );
	n             = Eclipse( r(:,k), rSun*uSun );             % <--- Normalized solar intensity
	p(k)          = SolarCellPower( d, solarFlux*n*uSun );    % <--- Solar cell power output
	tE            = (1-n)*dT + tE;                            % <--- Total blackout time
end

Plot2D(t,[r;p],'Time (sec)', {'x (km)' 'y (km)', 'z (km)' 'Power (W)'}, 'One Orbit' );

%% Size the battery
%------------------              
pTotal          = sum(p)*dT;          % <--- Solar energy generated over one orbit (the value of the first 'dT' is used here).
pAve            = pTotal/t(end);      % <--- Time average solar power output over one orbit.
pStored         = pAve*tE/3600;       % <--- Energy usage (in W-h) during the period of Eclipse (blackout due to Eclipse).
batteryCapacity = pStored/(1-dOD);    % <--- Battery capacity required for the given average depth of discharge and blackout time.

fprintf(1,'Eclipse Time       %8.1f s\n',tE);
fprintf(1,'Orbit period       %8.1f s\n',t(end));
fprintf(1,'Total power input  %8.1f Wh\n',pTotal/3600);
fprintf(1,'Depth of discharge %8.1f%%\n',dOD*100);
fprintf(1,'Battery Storage    %8.1f Wh\n',pStored);
fprintf(1,'Battery Capacity   %8.1f Wh\n',batteryCapacity);
%fprintf(1,'Li-Ion Polymer     %8.1f Wh\n',capacity);

%% 1. Power vs time of varying altitude (SMA)
%--------------------------------------------
sma_base = 6781.117;
sma_list = sma_base + [-200, -100, 0, 100, 200];

figure('Position', [100, 100, 600, 800]); % Tall figure for two subplots
set(gcf, 'DefaultAxesFontName', 'Times New Roman');
set(gcf, 'DefaultTextFontName', 'Times New Roman');

subplot(2,1,1);
hold on;
colors = lines(5);
labels_sma = cell(1,5);

fprintf('\n-------------------------------------------------------------------------------------------------\n');
fprintf('--- Power Requirements: Varying Altitude (SMA) ---\n');
fprintf('%-15s | %-12s | %-12s | %-15s | %-15s | %-15s\n', 'SMA Offset', 'Eclipse(s)', 'Period(s)', 'Total P.In(Wh)', 'Bat. Store(Wh)', 'Bat. Cap(Wh)');
fprintf('-------------------------------------------------------------------------------------------------\n');

for i = 1:5
    sma_i = sma_list(i);
    [r_i, ~, t_i] = RVFromKepler( [sma_i inc 0 0 0 0] );
    m_i = length(t_i);
    p_i = zeros(1,m_i);
    julianCent_i = JD2T( jD0 + t_i/86400 );
    
    dT_i = t_i(2) - t_i(1);
    tE_i = 0;
    for k = 1:m_i
        [uSun, rSun] = SunV1( julianCent_i(k) );
        n_i = Eclipse( r_i(:,k), rSun*uSun );
        p_i(k) = SolarCellPower( d, solarFlux*n_i*uSun );
        tE_i = (1-n_i)*dT_i + tE_i;
    end
    
    pTotal_i = sum(p_i)*dT_i;
    pAve_i = pTotal_i/t_i(end);
    pStored_i = pAve_i*tE_i/3600;
    batCap_i = pStored_i/(1-dOD);
    
    plot(t_i, p_i, 'Color', colors(i,:), 'LineWidth', 1.5);
        diff_sma = sma_i - sma_base;
        if abs(diff_sma) < 1e-3
            labels_sma{i} = sprintf('Baseline (%.1f km)', sma_i);
            fprintf('%-15s | %12.1f | %12.1f | %15.2f | %15.2f | %15.2f\n', 'Baseline', tE_i, t_i(end), pTotal_i/3600, pStored_i, batCap_i);
        else
            labels_sma{i} = sprintf('%+.0f km (%.1f km)', diff_sma, sma_i);
            fprintf('%-15.0f | %12.1f | %12.1f | %15.2f | %15.2f | %15.2f\n', diff_sma, tE_i, t_i(end), pTotal_i/3600, pStored_i, batCap_i);
        end
end

hold off;
grid on;
xlabel('Time (sec)');
ylabel('Power (W)');
title('Power generation over time with varying altitude');
legend(labels_sma, 'Location', 'best');

%% 2. Power vs time of varying inclination
subplot(2,1,2);
inc_base_deg = 51.6392;
inc_list_deg = inc_base_deg + [-40, -20, 0, 20, 40];

hold on;
labels_inc = cell(1,5);

fprintf('\n-------------------------------------------------------------------------------------------------\n');
fprintf('--- Power Requirements: Varying Inclination ---\n');
fprintf('%-15s | %-12s | %-12s | %-15s | %-15s | %-15s\n', 'Inc Offset', 'Eclipse(s)', 'Period(s)', 'Total P.In(Wh)', 'Bat. Store(Wh)', 'Bat. Cap(Wh)');
fprintf('-------------------------------------------------------------------------------------------------\n');

for i = 1:5
    inc_deg = inc_list_deg(i);
    inc_i = inc_deg * pi/180;
    [r_i, ~, t_i] = RVFromKepler( [sma_base inc_i 0 0 0 0] );
    m_i = length(t_i);
    p_i = zeros(1,m_i);
    julianCent_i = JD2T( jD0 + t_i/86400 );
    dT_i = t_i(2) - t_i(1);
    tE_i = 0;
    for k = 1:m_i
        [uSun, rSun] = SunV1( julianCent_i(k) );
        n_i = Eclipse( r_i(:,k), rSun*uSun );
        p_i(k) = SolarCellPower( d, solarFlux*n_i*uSun );
        tE_i = (1-n_i)*dT_i + tE_i;
    end
    
    pTotal_i = sum(p_i)*dT_i;
    pAve_i = pTotal_i/t_i(end);
    pStored_i = pAve_i*tE_i/3600;
    batCap_i = pStored_i/(1-dOD);
    
    plot(t_i, p_i, 'Color', colors(i,:), 'LineWidth', 1.5);
        diff_inc = inc_deg - inc_base_deg;
        if abs(diff_inc) < 1e-3
            labels_inc{i} = sprintf('Baseline (%.1f deg)', inc_deg);
            fprintf('%-15s | %12.1f | %12.1f | %15.2f | %15.2f | %15.2f\n', 'Baseline', tE_i, t_i(end), pTotal_i/3600, pStored_i, batCap_i);
        else
            labels_inc{i} = sprintf('%+.0f deg (%.1f deg)', diff_inc, inc_deg);
            fprintf('%-15.0f | %12.1f | %12.1f | %15.2f | %15.2f | %15.2f\n', diff_inc, tE_i, t_i(end), pTotal_i/3600, pStored_i, batCap_i);
        end
end

hold off;
grid on;
xlabel('Time (sec)');
ylabel('Power (W)');
title('Power generation over time with varying inclination');
legend(labels_inc, 'Location', 'best');

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2015-03-12 11:19:43 -0400 (Thu, 12 Mar 2015) $
% $Revision: 39864 $
