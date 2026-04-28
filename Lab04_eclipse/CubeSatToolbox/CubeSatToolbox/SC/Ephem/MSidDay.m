function d = MSidDay( jD )

%% Computes a mean sidereal day
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   d = MSidDay( jD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD              (1,:) Julian date (day)
%
%   -------
%   Outputs
%   -------
%   d               (1,:) Mean sidereal day (solar days)
%
%--------------------------------------------------------------------------
%   References: The Astronomical Almanac for the Year 1993, U.S. Government
%               Printing Office,1993, p. B6. 
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1994 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  jD = Date2JD;
end
	
% Julian days at 0h UT
%---------------------
jD0h  = R2P5 ( jD );
	
tu    = (jD0h - 2451545) / 36525;
gmst1 = ((0.093104 - 6.2e-6*tu).*tu + 8640184.812866).*tu;

tu    = (jD0h - 2451544) / 36525;
gmst2 = ((0.093104 - 6.2e-6*tu).*tu + 8640184.812866).*tu;

dg    = gmst2 - gmst1;

d     = 86400./(86400+dg);
  
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
