%% Demonstrate the playback of multiple orbits and moving sensor cones.
%
%  ------------------------------------------------------------------------
%  See also PackageOrbitDataForPlayback and PlaybackOrbitSim, Date2JD, 
%  OrbRate, Period, RVFromKepler
%  ----------------------------------------------------------------------
%%
%------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%------------------------------------------------------------------------
%   Since version 8.
%------------------------------------------------------------------------

%% Define epoch and simulate orbit
%--------------------------------
jD0         = Date2JD;
sma         = 6800;
el          = [sma, pi/4, 0, 0, 0, 0];
T           = Period(sma);
n           = OrbRate(sma);
time        = 0:20:T*2;
[r1,v1]     = RVFromKepler(el,time);

%% Define sensor attributes
%-------------------------
coneFOV     = pi/4;
conePitch   = pi/4*abs(cos(n*time));
coneAzimuth	= 0;
inputFrame  = 'ECI';

%% Package orbit data for satellite 1
%------------------------------------
object(1)   = PackageOrbitDataForPlayback( jD0, time, r1, v1,...
                             coneFOV, conePitch, coneAzimuth, inputFrame );

%% simulate second orbit
%----------------------
el          = [sma, pi/4 + .08, 0, .08, 0, .05];
[r2,v2]     = RVFromKepler(el,time);

%% Package orbit data for satellite 2
%------------------------------------
object(2)   = PackageOrbitDataForPlayback( jD0, time, r2, v2,...
                           coneFOV*0.2, conePitch, coneAzimuth, inputFrame );

%% Load data into AnimationGUI using PlaybackOrbitSim
%----------------------------------------------------
planet = 'EarthMR';
style  = '3D';
PlaybackOrbitSim( time, object, planet, style )



%--------------------------------------
% $Date: 2020-07-13 15:08:18 -0400 (Mon, 13 Jul 2020) $
% $Revision: 53043 $
