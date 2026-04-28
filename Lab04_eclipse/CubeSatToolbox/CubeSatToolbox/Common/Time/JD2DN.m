function [dayNumber, year] = JD2DN( jD )

%% Compute the day number from Julian date.
%
% Typing JD2DN returns the current day number.
%--------------------------------------------------------------------------
%   Form:
%   dayNumber = JD2DN( jD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jd            (1,1) Julian date
%
%   -------
%   Outputs
%   -------
%   dayNumber     (1,1) Day number
%   year          (1,1) Year
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	 Copyright (c) 2000 Princeton Satellite Systems, Inc. 
%    All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  jD = Date2JD;
end

dateTime  = JD2Date( jD );

dayNumber = Date2DN( dateTime );
year      = dateTime(1);

%--------------------------------------
% $Date: 2019-12-27 11:53:18 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50722 $
