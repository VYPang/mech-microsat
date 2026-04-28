function lla = ECEFToLLA( rECEF, rP )

%% Compute latitude, longitude, altitude from ECEF position.
% Assumes spherical planet.
%--------------------------------------------------------------------------
%   Form:
%   lla = ECEFToLLA( rECEF, rP );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   rECEF       (3,:)   ECEF position vector [km]
%   rP          (1,1)   Radius of planet (for Earth: 6378.14) [km]
%                       
%
%   -------
%   Outputs
%   -------
%   lla         (3,:)   Latitude [rad], longitude [rad], altitude [km]
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2007 Princeton Satellite Systems, Inc. 
%   All rights reserved
%--------------------------------------------------------------------------

rMag = Mag(rECEF);
h = rMag-rP;
r = [rECEF(1,:)./rMag;rECEF(2,:)./rMag;rECEF(3,:)./rMag];
lat = asin(r(3,:));
lon = atan2(r(2,:),r(1,:));
lla = [lat;lon;h];

%--------------------------------------
% $Date: 2020-04-27 15:36:14 -0400 (Mon, 27 Apr 2020) $
% $Revision: 51998 $
