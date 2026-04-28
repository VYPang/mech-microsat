function xDot = FOrbCart( x, t, a, mu )

%% Computes the right-hand-side of the orbit equations about a mass point.
%   Only the first input is required.
%--------------------------------------------------------------------------
%   Form:
%   xDot = FOrbCart( x, t, a, mu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x            (6,1)     The state vector [r;v]
%   t            (1,1)     Time (unused)
%   a            (3,1)     External acceleration (default is zero)
%   mu           (1,1)     Gravitational parameter (default is Earth)
%
%   -------
%   Outputs
%   -------
%   xDot         (6,1)     The derivative of the state vector
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 3 )
  a = [0;0;0];
end

if( nargin < 4 )
  mu = 3.98600436e5;
end

% Switch inputs for ode113
%-------------------------
if length(x) == 1
  s = x;
  x = t;
  t = s;
end

r    = x(1:3);
v    = x(4:6);

xDot = [v; a - mu*r/Mag(r)^3];


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:08:09 -0400 (Thu, 11 May 2017) $
% $Revision: 44568 $
