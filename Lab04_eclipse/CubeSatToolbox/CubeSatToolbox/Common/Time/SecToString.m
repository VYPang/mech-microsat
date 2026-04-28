function dS = SecToString( s )

%% Convert seconds to days hours/min/seconds and produces a string.
%--------------------------------------------------------------------------
%   Form:
%   dateString = SecToString( s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s     (1,1)  Seconds
%
%   -------
%   Outputs
%   -------
%   dS    (1,:)  Date string
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%--------------------------------------------------------------------------

if( nargin < 1 )
  SecToString(100000)
  return
end

days  = floor(s/86400);
s     = s - days*86400;
hours	= floor(s/3600);
s     = s - hours*3600;
min   = floor(s/60);
s     = s - min*60;

if( days == 1 )
  d = 'Day';
else
  d = 'Days';
end

dS    = sprintf('%d %s %02d:%02d:%04.1f',days,d,hours,min,s);


%--------------------------------------
% $Date: 2019-12-27 11:09:25 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50719 $

