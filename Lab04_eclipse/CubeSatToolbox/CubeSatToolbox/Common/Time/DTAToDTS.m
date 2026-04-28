function dateTime = DTAToDTS( t )

%% Converts the date time array to the date time structure
%
% Typing DSTToDTA returns the clock time.
%
%--------------------------------------------------------------------------
%   Form:
%   dateTime = DTSToDTA( t )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   t           (1,6)   [year month day hour minute seconds 
%
%   -------
%   Outputs
%   -------
%   dateTime    (1,1)   Date/time structure
%                       .year
%                       .month                             
%                       .day                             
%                       .hour                             
%                       .minute                             
%                       .second
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998-2004 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%--------------------------------------------------------------------------

if( nargin == 0 ) 
  t = clock;
end

if( isstruct(t) )
  dateTime = t;
else
  if( length(t) == 1 )
    dateTime.year   = t;
    dateTime.month  = 1;
    dateTime.day    = 1;
    dateTime.hour   = 0;
    dateTime.minute = 0;
    dateTime.second = 0;
  else
    dateTime.year   = t(1);
    dateTime.month  = t(2);
    dateTime.day    = t(3);
    dateTime.hour   = t(4);
    dateTime.minute = t(5);
    dateTime.second = t(6);
  end
end

%--------------------------------------
% $Date: 2019-12-27 11:53:18 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50722 $
