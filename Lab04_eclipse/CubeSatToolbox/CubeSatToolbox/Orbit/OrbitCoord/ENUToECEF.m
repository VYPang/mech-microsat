function T = ENUToECEF( lat, lon )

%% Compute the transformation matrix that rotates ENU to ECEF coordinates.
%   ENU is East-North-Up. Assumes spherical Earth.
%
%   Since version 8.
%--------------------------------------------------------------------------
%   Form:
%   T = ENUToECEF( lat, lon )
%   T = ENUToECEF( r )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   lat         (1,1)   Latitude (rad)
%   lon         (1,1)   Longitude (rad)
%         OR
%   r           (3,1)   Earth fixed position  
%
%   -------
%   Outputs
%   -------
%   T           (3,3)   ENU to ECEF rotation matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 2009 Princeton Satellite Systems, Inc. All rights reserved
%--------------------------------------------------------------------------

if nargin > 1
  slat = sin(lat);
  clat = cos(lat);
  slon = sin(lon);
  clon = cos(lon);
else
  r = lat;
  rXY = sqrt(r(2)^2 + r(1)^2);
  if (rXY < eps)
    % polar position
    slat = 1;
    clat = 0;
    clon = 1;
    slon = 0;
  else
    tlat = r(3)/rXY;
    mu   = atan(tlat);
    slat = sin(mu);
    clat = cos(mu);
    clon = r(1)/rXY;
    slon = r(2)/rXY;
  end    
end

T = [...
   -slon, -clon*slat, clon*clat; ...
   clon, -slon*slat, slon*clat; ...
   0,  clat,      slat      ];

%--------------------------------------------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 11:41:04 -0400 (Tue, 09 May 2017) $
% $Revision: 44510 $
