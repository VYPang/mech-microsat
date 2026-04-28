function x = R2P5( y )

%% Rounds towards zero to the nearest 1/2.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   x = R2P5( y )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   y           Number
%
%   -------
%   Outputs
%   -------
%   x           Rounded number
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 1993, 2012 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    echo on
    y = 1.7;
    R2P5( y )
    y = -1.3;
    R2P5( y )
    echo off
    return;
end
    

k = find(y < 0);

y = abs(y);
	
x = fix(y); 

d = y - x;

i   = find( d >= 0.5 );
j   = find( d <  0.5 );
x(i) = x(i) + 0.5;
x(j) = x(j) - 0.5;

x(k) = -x(k);




% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
