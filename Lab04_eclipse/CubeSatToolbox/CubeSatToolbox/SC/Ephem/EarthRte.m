function w = EarthRte( jD )

%% Computes the mean earth rate.
%   See also MSidDay.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   w = EarthRte( jD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD              (1,1)   Julian date (day)
%
%   -------
%   Outputs
%   -------
%   w               (1,1)    Mean earth rate (rad/sec)
%
%--------------------------------------------------------------------------
%	References:	The Astronomical Almanac for the Year 1993, U.S. Government
%               Printing Office, 1993, p. B6. 
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin == 0 )
  jD = Date2JD;
end

w = 2*pi/(86400*MSidDay(jD));

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:11:01 -0400 (Thu, 11 May 2017) $
% $Revision: 44563 $
