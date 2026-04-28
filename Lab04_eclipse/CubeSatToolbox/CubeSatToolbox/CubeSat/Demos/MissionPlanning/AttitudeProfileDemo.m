%% Demonstrate the AttitudeProfile function.
% Plots the resulting quaternion and the separation angle from the
% secondary target.
%
%  Mode 1:      Body y to Sun     (Body x to Nadir secondary)
%  Mode 2:      Body x to Lat/Lon (Body y to Sun secondary)
%  Mode 3:      Different Lat/Lon 
%
% See also AttitudeProfile, ObservationTimeWindows, PlotOrbit, Q2Eul, Plot2D,
% Date2JD, ObservationTimeWindowsPlot, Period, RVFromKepler
%%

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

clear a; clear b; clear c; clear d;

%% Orbit and time information
%---------------------------
d.jD0 = Date2JD;
d.t = 0:15:86400;
d.el = [6800,pi/6,pi/3,0,0,0];
[d.r,d.v] = RVFromKepler( d.el, d.t );
PlotOrbit(d.r,d.t,d.jD0);
   
%% Mode 1:   Body y to Sun     (Body x to Nadir secondary)
%---------------------------
a.type1  = 'nadir';
a.body1   = [1;0;0];
a.target1 = [];
a.type2  = 'orbitnormal';
a.body2   = [0;1;0];
a.target2 = [];

%% Mode 2:   Body x to Lat/Lon (Body y to Sun secondary)
%---------------------------
b.type1  = 'latlon';
b.body1   = [1;0;0];
b.target1 = [0;90];
b.type2  = 'orbitnormal';
b.body2   = [0;1;0];
b.target2 = [];

%% Mode 3:   Body x to Lat/Lon (Body y to Sun secondary)
%---------------------------
c.type1  = 'latlon';
c.body1   = [1;0;0];
c.target1 = [35;-90];
c.type2  = 'orbitnormal';
c.body2   = [0;1;0];
c.target2 = [];

%% Compute observation windows for this target
%--------------------------------------------
fov = pi;
[track,obs] = ObservationTimeWindows( d.el, [b.target1,c.target1], d.jD0, d.t(end), fov );
b.window    = obs(1).window;
c.window    = obs(2).window;

ObservationTimeWindowsPlot(track,obs);

%% Compute the attitude profile
%-----------------------------
d = AttitudeProfile( d, a, b, c );

%% Plot quaternion and separation angle over time
%-----------------------------------------------
Plot2D(d.t/3600,d.q,'Time (hrs)','Quaternion')
Plot2D(d.t/3600,d.sep*180/pi,'Time (hrs)','Separation Angle (deg)')

eul = zeros(3,length(d.t));
for k = 1:length(d.t)
  eul(:,k) = Q2Eul( d.q(:,k) );
end
Plot2D(d.t/Period(6800),eul*180/pi,'Time (orbits)',{'Roll','Pitch','Yaw'},'Euler Angles (deg)')


%--------------------------------------
% $Date: 2019-09-07 17:12:12 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49734 $
