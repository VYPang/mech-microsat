function [termLat,long,sunLatLon] = TerminatorLine( jD, n )

%% Compute the terminator line on the Earth that defines day/night. 
%
%   Since version 8.
%--------------------------------------------------------------------------
%   Form:
%   [termLat,long] = Terminator( jD );
%   [termLat,long] = Terminator( jD, n );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD          (1,1) Julian date
%   n           (1,1) Number of points to use for the line. Optional.
%
%   -------
%   Outputs
%   -------
%   termLat     (1,n) Terminal latitudes (deg)
%   long        (1,n) Longitude from -180 to 180 (deg)
%   sunLatLon   (2,1) Latitude and longitude of normal vector to sun (deg)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% pick the current Julian date if none provided
if( nargin < 1 )   
   jD = Date2JD+5/24;
   TerminatorLine( jD );
   return
end

% number of points
if( nargin < 2 )
   n = 360;
end

% compute day of year (1-365)
date = JD2Date(jD);
day  = jD - Date2JD([date(1) 1 1 0 0 0]) + 1;

% compute the declination angle
dec = -23.45*cos(360/365*(day+10)*pi/180)*pi/180;

% define array of longitudes from -180 to 180
long = linspace(-180,180,n);

% compute local hour angle
gHA = (jD-floor(jD)-.5)*360;  % Greenwich hour angle (-180 to 180, 0 at noon)
lHA = gHA + long;             % Local hour angle 
lHA = lHA*pi/180;             % convert to radians

% compute terminator latitude using approximate analytic solution
termLat = atan2(cos(lHA),tan(dec));

% order in ascending longitude and convert to deg
[long,ord] = sort(long);
termLat = termLat(ord)*180/pi;

% wrap into correct quadrants
k1 = find(termLat>90); 
k2 = find(termLat<-90);
termLat(k1) = termLat(k1)-180;
termLat(k2) = termLat(k2)+180; 

if( nargout>2 || nargout==0 )
	% compute lat. and long. on Earth where normal vector points to sun
    Re = 6378.14;     % Earth radius
    uS = SunV1( jD ); % compute sun vector
    lla  = CoordinateTransform('eci','llr',uS*Re,jD);
    sunLatLon = lla(1:2)*180/pi;
end

% show 2D Earth map plot with shading if no outputs required
if( nargout == 0 )
   Map('EarthHR','2D')
   hold on
   
   % if latitude was initially outside 90 deg bound, must be winter
   if( ~isempty(k1) )
      ylim = 90;
   else
      ylim = -90;
   end
   p = patch([-180 long 180],[ylim termLat ylim],'k');
   set(p,'facealpha',.5,'linestyle','none')
   
   % lat. and long. on Earth where normal vector points to sun
   lat0 = sunLatLon(1);
   lon0 = sunLatLon(2);
   
   if( lon0<0 )
      eastWest = 'W';
   else
      eastWest = 'E';
   end
   if( lat0<0 )
      northSouth = 'S';
   else
      northSouth = 'N';
   end
   title(sprintf('Day/Night Across Earth at %s GMT \nSun at lon %s %2.1f / lat %s %2.1f  ',...
      JDToDateString(jD),eastWest,abs(lon0),northSouth,abs(lat0)))
   
   plot(lon0,lat0,'y*','markersize',12)
   plot(lon0,lat0,'y.','markersize',12)
   
end

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
