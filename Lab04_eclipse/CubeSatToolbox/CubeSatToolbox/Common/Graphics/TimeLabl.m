function [t, c, u] = TimeLabl( t0, dT )

%% Generates a time label given the maximum value of t and rescales t.
% If two arguments are entered it computes the time series t as
%
%   t = (0:(nSim-1))*dT
%
% The available units are (years,months,weeks,days,hours,minutes,seconds)
% Years and months are mean.
%
%--------------------------------------------------------------------------
%   Form:
%   [t, c, u] = TimeLabl( t0 )
%   [t, c, u] = TimeLabl( nSim, dT )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   t0      (1,:)  Time (sec)
%
%   - or -
%
%   nSim    (1,1)  Number of time steps
%   dT      (1,1)  Time step (sec)
%
%   -------
%   Outputs
%   -------
%   t			 (1,:) Time (new units)
%   c			 (1,:) Label string, 'Time = (units)' 
%   u      (1,:) Units of time
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995, 2007, 2020 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2020.1 Added weeks and months as units.
%--------------------------------------------------------------------------

if( nargin > 1 )
  t0 = (0:(t0-1))*dT;
end

secInYear   = 365.25*86400;
secInMonth  = (365.25/12)*86400;
secInWeek   = 7*86400;
secInDay    = 86400;
secInHour   =  3600;
secInMinute	=  60;

tMax        = max(t0);

if( tMax > secInYear )
  c = 'Time (years)';
  t = t0/secInYear;
  u = 'year';
elseif( tMax > 3*secInMonth )
  c = 'Time (months)';
  t = t0/secInMonth;
  u = 'month';
elseif( tMax > 3*secInWeek )
  c = 'Time (weeks)';
  t = t0/secInWeek;
  u = 'week';
elseif( tMax > 3*secInDay )
  c = 'Time (days)';
  t = t0/secInDay;
  u = 'day';
elseif( tMax > 3*secInHour )
  c = 'Time (hours)';
  t = t0/secInHour;
  u = 'hour';
elseif( tMax > 3*secInMinute )
  c = 'Time (min)';
  t = t0/secInMinute;
  u = 'min';
else
  c = 'Time (sec)';
  t = t0;
  u ='sec';
end


%--------------------------------------
% $Date: 2020-05-27 10:11:29 -0400 (Wed, 27 May 2020) $
% $Revision: 52458 $
