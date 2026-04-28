function object = PackageOrbitDataForPlayback( jD0, t, r, v, coneFOV, conePitch, coneAzimuth, inputFrame )

%% Package orbit data into a structure for use in PlaybackOrbitSim.
%
% For the sensor cone FOV, pitch and azimuth angles: you may supply any
% one of them as either a scalar or a vector with the same number of
% points as the time vector.
%
% Since version 8.
%--------------------------------------------------------------------------
%   Form:
%   object = PackageOrbitDataForPlayback( jD0, t, r, v, coneFOV, conePitch,
%                                            coneAzimuth, inputFrame )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD0           (1,1)    Julian date epoch.
%   t             (1,N)    Time vector. Seconds from epoch.
%   r             (3,N)    Position history of orbit.
%   v             (3,N)    Velocity history of orbit.
%   coneFOV       (1,:)    Cone field of view (rad)
%   conePitch     (1,:)    Cone pitch from nadir (rad)
%   coneAzimuth   (1,:)    Cone azimuth from north (rad)
%   inputFrame     (:)     Frame of r,v inputs. 'ECI' or 'EF'
%
%   -------
%   Outputs
%   -------
%   object         (:)     Data structure array of simulated objects in orbit
%                          See PackageOrbitDataForPlayback.m. Fields are:
%                             rEF: [3xN double] Earth fixed position (km)
%                             vEF: [3xN double] Earth fixed velocity (km/s)
%                             lat: [1xN double] Latitude (rad)
%                             lon: [1xN double] Longitude (rad)
%                               h: [1xN double] Altitude (km)
%                         coneFOV: [1xN double] Cone field of view (rad)
%                       conePitch: [1xN double] Cone pitch from nadir (rad)
%                     coneAzimuth: [Nx1 double] Cone azimuth from north (rad)
%                        coneAxis: [3xN double] Cone axis in Earth-fixed frame
%                          swathX: [NxP double] Swath curve, Earth-fixed x-coord.
%                          swathY: [NxP double] Swath curve, Earth-fixed y-coord.
%                          swathZ: [NxP double] Swath curve, Earth-fixed z-coord.
%                        swathLat: [NxP double] Swath curve, latitude
%                        swathLon: [NxP double] Swath curve, longitude
%
%   See also:  PlaybackOrbitSim.m
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 2009 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------

% uses AnimationGUI with Earth image in the background

% DEFAULT INPUTS
if( nargin<8 )
   inputFrame = 'ECI';
end
if( nargin<7 || isempty(coneAzimuth) )
   coneAzimuth = 0;
end
if( nargin<6 || isempty(conePitch) )
   conePitch = 0;
end
if( nargin<5 || isempty(coneFOV) )
   coneFOV = 0;
end

% built-in demo
if( nargin < 1 )
   
   jD0         = Date2JD;
   sma         = 6800;
   el          = [sma, pi/4, 0, 0, 0, 0];
   T           = Period(sma);
   n           = OrbRate(sma);
   t           = linspace(0,T*2,300);
   [r,v]       = RVFromKepler(el,t);
   coneFOV     = pi/4;
   conePitch   = pi/8;
   coneAzimuth = n*t;
   
   inputFrame  = 'ECI';
   
end

if(~ischar(inputFrame))
   error('Input frame must be a string. Either "ECI" or "EF".');
end

% equatorial radius of Earth
Re = 6378.14;

% check dimensions
nSim = length(t);
[nPos,nSimPos] = size(r);
[nVel,nSimVel] = size(v);

if( nPos~=3 || nVel~=3 )
   error('Position and velocity inputs must have 3 rows and N columns for N time points.')
end
if( nSimPos~=nSimVel )
   error('Position and velocity inputs must have the same length as the time vector.')
end

coneFOV = coneFOV(:);
conePitch = conePitch(:);
coneAzimuth = coneAzimuth(:);

if( size(coneFOV,2)>1 || size(conePitch,2)>1 || size(coneAzimuth,2)>1 )
   error('The cone angle vectors must be one-dimsional, either Nx1 or 1xN.');
end

if( length(coneFOV)==1 )
   coneFOV = coneFOV*ones(1,nSim);
end
if( length(conePitch)==1 )
   conePitch = conePitch*ones(1,nSim);
end
if( length(coneAzimuth)==1 )
   coneAzimuth = coneAzimuth*ones(1,nSim);
end

% create object data structure and initialize fields
object.rEF = zeros(3,nSim);
object.vEF = zeros(3,nSim);
object.lat = zeros(1,nSim);
object.lon = zeros(1,nSim);
object.h   = zeros(1,nSim);

object.coneFOV       = coneFOV;
object.conePitch     = conePitch;
object.coneAzimuth   = coneAzimuth;
object.coneAxis      = zeros(3,nSim);

object.swathX     = [];
object.swathY     = [];
object.swathZ     = [];
object.swathLat   = [];
object.swathLon   = [];


% compute Earth Fixed position and velocity
switch lower(inputFrame)
   case 'eci'
      el = RV2El(r(:,1),v(:,1));
      n = OrbRate(el(1));
      for i=1:length(t)
         m = ECIToEF( JD2T(jD0+t(i)/86400) );   % ECI to EF rotation matrix
         object.rEF(:,i) = m*r(:,i);
         object.vEF(:,i) = m*v(:,i)-Cross(object.rEF(:,i),[0;0;n]);
      end
   case 'ef'
      object.rEF = r;
      object.vEF = v;
   otherwise
      error('Input frame "%s" not recognized.',inputFrame);
end
      
% only compute cone data if the field of view exists
if( max(coneFOV)>eps )
   computeCone = 1;
else
   computeCone = 0;
end

% compute latitude and longitude, and cone geometry
for i=1:length(t)
   
   lla = ECEFToLLA( object.rEF(:,i), Re );
   lat = lla(1);
   lon = lla(2);
   h   = lla(3);
   
   object.lat(i) = lat; 
   object.lon(i) = lon;
   object.h(i)   = h;
   
   if( computeCone )
      % compute the cone geometry
      rCone = (Re+h)*[cos(lat)*cos(lon);cos(lat)*sin(lon);sin(lat)];
      qPitch = AU2Q( conePitch(i), Unit(Cross(rCone,[0;0;1])) );
      qRoll  = AU2Q( coneAzimuth(i), -Unit(rCone) );
      object.coneAxis(:,i) = QForm(QMult(qPitch,qRoll),Unit(-rCone));
      
      % compute the swath curve
      d = RapidSwath( lat, lon, h, coneFOV(i)/2, conePitch(i), coneAzimuth(i) );
      if( isstruct(d) )
        object.swathX(i,:) = d.r(1,:);
        object.swathY(i,:) = d.r(2,:);
        object.swathZ(i,:) = d.r(3,:);
        object.swathLat(i,:) = d.lat;
        object.swathLon(i,:) = d.lon;
      end
   end
   
end
   
%--------------------------------------
% $Date: 2019-09-07 15:22:51 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49733 $
