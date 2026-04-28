function s = JDToDateString( jD, ~ )

%% Convert Julian Date to the form '04/20/2000 00:00:00'
% If calForm is entered you will get Apr 20, 2000
%  
% Typing JDToDateString returns the current date.
%--------------------------------------------------------------------------
%   Form:
%    s = JDToDateString( jD, calForm)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD     	(1,1)   Julian Date   
%   calForm	(1,1) 	 'mm/dd/yyyy hh:mm:ss'
%
%   -------
%   Outputs
%   -------
%   s       (1,:)   String 'mm/dd/yyyy hh:mm:ss' or 'Jan dd, yyyy'
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2000-2004 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  jD = Date2JD;
end

d = JD2Date( jD );
if( nargin == 1 )
  s = sprintf( '%2.2i/%2.2i/%4i %2.2i:%2.2i:%05.2f', d(2), d(3), d(1), d(4:6) );
else
  m     = {'Jan' 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
  month = m{d(2)};
  s     = sprintf('%3s %2.2i, %4i %2.2i:%2.2i:%05.2f',month, d(3), d(1), d(4:6) );
end

%--------------------------------------
% $Date: 2019-12-27 11:53:18 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50722 $
