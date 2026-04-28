function dn = Date2DN( datetime )

%% Compute the day number from the date. Uses the format from clock. 
% If no inputs are given it will compute the day number for the instant
% of the function call.
%
%--------------------------------------------------------------------------
%   Form:
%   dn = Date2DN( datetime )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   datetime     (1,6) [year month day hour minute seconds]
%
%   -------
%   Outputs
%   -------
%   dn           (1,1) Day number
%
%--------------------------------------------------------------------------
%   References: Montenbruck, O., T.Pfleger, Astronomy on the Personal
%               Computer, Springer-Verlag, Berlin, 1991, p. 12.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2004 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin == 0 )
  datetime = clock;
else
  datetime = DTSToDTA( datetime );
end

if ( datetime(2) == 0 )
  error('No zero month')
end
if ( datetime(3) == 0 )
  error('No zero day')
end

dn = Date2JD(datetime)-Date2JD([datetime(1),1,1,0,0,0])+1;

%--------------------------------------
% $Date: 2019-12-27 11:09:25 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50719 $
