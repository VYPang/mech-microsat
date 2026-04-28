function [lat, lon] = R2LatLon( x, y, z )

%% Computes geocentric latitude and longitude from r 
%
%--------------------------------------------------------------------------
%   Form:
%   [lat, lon] = R2LatLon( x, y, z )
%   [lat, lon] = R2LatLon( r )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x            (1,:)     X or [x;y;z]
%   y            (1,:)     Y
%   z            (1,:)     Z
%
%   -------
%   Outputs
%   -------
%   lat          (1,:)     Latitude (rad)
%   lon          (1,:)     East longitude (0 in xz-plane, +right hand rule
%                          about +z)  (rad)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin == 3 )
  r = [x;y;z];
else
  r = x;
end

u    = Unit(r);
lon  = atan2( u(2,:), u(1,:) );
lat  = asin( u(3,:) );

if( nargout == 0 )
  Plot2D(lon*180/pi,lat*180/pi,'Longitude (deg)','Latitude (deg)','Latitude vs. Longitude');
  clear lat
end

% PSS internal file version information
%--------------------------------------
% $Date: 2020-04-27 15:36:14 -0400 (Mon, 27 Apr 2020) $
% $Revision: 51998 $
