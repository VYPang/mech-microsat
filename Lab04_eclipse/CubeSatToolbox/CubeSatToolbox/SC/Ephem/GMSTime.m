function gmst = GMSTime( jd )

%% Compute Greenwich mean sidereal time from Julian date.
%   This is the angle between the Greenwich Meridian and the Vernal Equinox.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   gmst = GMSTime( jd )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jd              (1,1)   Julian date UT (day)
%
%   -------
%   Outputs
%   -------
%   gmst            (1,1)   Greenwich mean sidereal time (deg)
%
%--------------------------------------------------------------------------
%   References: The Astronomical Almanac for the Year 1993, U.S. Government
%               Printing Office, 1993, p. B6. 
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2000 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin == 0 )
  jd = Date2JD;
end

% Julian days at 0h UT
%---------------------
jd0h = JDToMidnight( jd );
	
tu   = (jd0h - 2451545) / 36525;
	
% This organization maximizes the precision
%------------------------------------------
gmst = (((0.093104 - 6.2e-6*tu).*tu + 8640184.812866).*tu + 24110.54841);

% Account for earth rotation
%---------------------------
gmst = gmst/86400  + (jd-jd0h)./MSidDay(jd);

% Limit to the range 0 to 360 deg
%--------------------------------
gmst = rem( gmst, 1 )*360;

if( gmst < 0 )
  gmst = gmst + 360;
end

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
