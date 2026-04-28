function [track,obs] = ObservationTimeWindows( orbit, targets, jD, horizon, fOV, minEl, doPlot )

%% Generate a set of observation time windows for each lat/lon target
%--------------------------------------------------------------------------
%   Usage:
%   [track,obs] = ObservationTimeWindows( orbit, targets, jD, horizon, ...
%                    fOV, minEl, doPlot )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   orbit      (1,6)    Orbital elements vector, OR
%               (.)     Data structure w/ time (.t) and ECI pos (.r)
%   targets    (2,N)    List of N targets [lat;lon] in deg
%   jD         (1,1)    Julian date start epoch
%   horizon    (1,1)    Duration 
%   fOV        (1,1)    Field of view (deg)
%   minEl      (1,1)    Minimum elevation (deg)
%   doPlot     (1,1)    Flag to generate plot (1) or not (0). Default 0.
%
%   -------
%   Outputs
%   -------
%   track       (.)  Data structure with time, lat. and long. of satellite, 
%                    azimuth, elevation and range of satellite with respect 
%                    to targets.
%   obs         (.)  Data structure array with fields:
%                    .target:    (2,1)    Lat and lon coordinates of target
%                    .boundary:  (2,:)    Lat/lon boundary around target
%                    .nObs:      (1,1)    Number of observations of this target
%                    .window: 	(nObs,2) Each row is start/stop time of window    
%                    .time:      {1,nObs} Each entry is a (1,T) time vector
%                    .path:      {1,nObs} Each entry is a (2,T) lat/lon vector
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------
% Since version 8.
%--------------------------------------------------------------------------

if( nargin<7 )
   doPlot = 0;
end

if( nargin<6 )
  minEl = 0;
end

% Default inputs
if( nargin<1 )
   orbit    = [6950, pi/4, -pi/2, 0, 0, 0];
%   targets  = [46 -10;2.5 -50];
   targets  = [10 -20; 155 -120];
   fOV      = pi;
   jD       = JD2000;
   horizon  = 86400;
   ObservationTimeWindows( orbit, targets, jD, horizon, fOV );
   return;
end

% latitude and longitude in radians
lat = targets(1,:)*pi/180;
lon = targets(2,:)*pi/180;

% Constants
Re = 6378.137;

% Compute Earth Fixed coordinates for targets
nTargets = size(targets,2);
rTargetEF = zeros(3,nTargets);
for i=1:nTargets,
   rTargetEF(:,i) = LLAToECEF( [lat(i);lon(i);0], Re );
end

% compute the orbit if only elements are provided
if( ~isstruct(orbit) )

   % at least two time steps across field of view
   sma = orbit(1);   % semi major axis
   n = OrbRate(sma); % mean orbit rate
   dT = min(fOV/(2*n),2*pi/n/180);
   
   dT = 20;
   
   % time vector
   t = 0:dT:horizon;
   
   % propagate orbit
   r = RVFromKepler(orbit,t);

else
   t = orbit.t;
   r = orbit.r;
   v = orbit.v;
   el = RV2El(r(:,1),v(:,1));
   sma = el(1);
end

h = sma - Re;

% transform ECI to EF
nt  = length(t);
rEF = zeros(3,nt);
for j=1:nt
   m  = ECIToEF( JD2T(jD+t(j)/86400.0) );
   rEF(:,j) = m*r(:,j);
end
[latx,lonx] = R2LatLon(rEF);

% track output
track.jDate = jD;
track.time  = t;
track.lat   = latx*180/pi;
track.lon   = lonx*180/pi;

% compute critical field of view
fovCrit = 2*asin(Re/(Re+h));

% compute minimum elevation angle
if( fOV>=fovCrit )
   elMin = 0;
else
   elMin = acos((Re+h)/Re*sin(fOV/2));
end

for i=1:nTargets
   
   % ECEF to ENU rotation matrix
   T = ENUToECEF( lat(i), lon(i) );
   T = T';

   % vector from target to satellite in ENU coordinates
   drEFx = rEF(1,:) - rTargetEF(1,i);
   drEFy = rEF(2,:) - rTargetEF(2,i);
   drEFz = rEF(3,:) - rTargetEF(3,i);
   de = T(1,1)*drEFx+T(1,2)*drEFy+T(1,3)*drEFz;
   dn = T(2,1)*drEFx+T(2,2)*drEFy+T(2,3)*drEFz;
   du = T(3,1)*drEFx+T(3,2)*drEFy+T(3,3)*drEFz;
   
   % compute azimuth, elevation and range from target to satellite
   dh = sqrt(de.^2+dn.^2);
   track.dr(:,i) = sqrt(de.^2+dn.^2+du.^2)';
   track.el(:,i) = atan2( du, dh )';
   track.az(:,i) = atan2( dn, de )';

   % compute range from target so that, if the satellite is within this
   % horizontal range and the sensor is pointing towards the Earth, the target
   % would be within the field of view of the sensor
   e = elMin;   % minimum elevation angle
   theta = asin( (Re/(Re+h))*cos(e)*( sqrt(((Re+h)/Re)^2-cos(e)^2)-sin(e) ) );
   range = (Re+h)*theta;

   obs(i).target = targets(:,i);
   [latb,lonb] = RAzToLatLon( range, 0:pi/180:2*pi, lat(i), lon(i), sma );
   obs(i).boundary = [latb;lonb]*180/pi;
   obs(i).nObs = 0;
   
   % find times when elevation is within field of view
   wintmp = FindTimeWindows( t, track.el(:,i), [minEl,inf] );
   obs(i).nObs = wintmp.nObs;
   obs(i).window = wintmp.window; %#ok<*AGROW>
   
   % find entry and exit lat/lons
   for j=1:obs(i).nObs
     ind1 = wintmp.indexStart(j);
     ind2 = wintmp.indexEnd(j);
     latPath = latx(ind1:ind2)*180/pi;
     lonPath = lonx(ind1:ind2)*180/pi;
     obs(i).path{j} = [latPath;lonPath];
   end   
   
end



% Create a a 2D Earth Map Plot if no outputs requested
if( nargout==0 || doPlot )
   ObservationTimeWindowsPlot(track,obs);
end



%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
