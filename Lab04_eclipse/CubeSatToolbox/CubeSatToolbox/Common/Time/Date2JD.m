function jd = Date2JD( datetime )

%% Compute the Julian Date from the date. 
% Uses the format from clock. If no inputs are given,
% it will compute the Julian date for the instant
% of the function call. Only works for dates after 1600. You may omit
% the last three numbers (hour minute seconds) in the array.
% The date is in Greenwich Mean Time
%
%--------------------------------------------------------------------------
%   Form:
%   jd = Date2JD( datetime )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   datetime      (1,6) [year month day hour minute seconds]
%                       or the datetime data structure.
%                               .year
%                               .month                             
%                               .day                             
%                               .hour                             
%                               .minute                             
%                               .second
%                       
%
%   -------
%   Outputs
%   -------
%   jd            (1,1) Julian date
%
%--------------------------------------------------------------------------
%   References: Montenbruck, O., T. Pfleger, Astronomy on the Personal
%               Computer, Springer-Verlag, Berlin, 1991, p. 12.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2004 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 1.1
%--------------------------------------------------------------------------

% Gives the current date if there are no inputs
%----------------------------------------------
if( nargin == 0 )
  datetime = clock;
else
  datetime = DTSToDTA( datetime );
end

if( datetime(2) == 0 )
  error('No zero month')
end

% Adjust for negative years
%--------------------------
if( datetime(1) <= 0 )
  datetime(1) = datetime(1) + 1;
end

% If time was not entered
%------------------------
dT = zeros(1,6);
dT(1:length(datetime)) = datetime;
datetime = dT;

% datetime = [year month day hour minute second]
%-----------------------------------------------
fracday = (datetime(4) + (datetime(5) + datetime(6)/60)/60)/24; 

a       = 1.e4*datetime(1) + 1.e2*datetime(2) + datetime(3) + fracday;

if( datetime(2) <= 2 )
  datetime(2) = datetime(2) + 12;
  datetime(1) = datetime(1) - 1;
end

if ( a <= 15821004.1 )
  b = -2 + fix((datetime(1) + 4716)/4) - 1179; 
else
  b = fix(datetime(1)/400) - fix(datetime(1)/100) + fix(datetime(1)/4); 
end

jd = 365*datetime(1) + b + fix(30.6001*(datetime(2) + 1))+datetime(3)+fracday+1720996.5;
	
%--------------------------------------
% $Date: 2017-06-13 17:14:09 -0400 (Tue, 13 Jun 2017) $
% $Revision: 44843 $
