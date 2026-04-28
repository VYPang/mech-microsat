function y = IC623X3( x )

%% Convert an inertia matrix from a 1x6 to a 3x3 format.
% The original form  is 
%
% [Ixx Iyy Izz Ixy Ixz Iyz]
%
% to 
%
% [Ixx Ixy Ixz
% Ixy Iyy Iyz
% Ixz Iyz Izz]
%
%--------------------------------------------------------------------------
%   Form:
%   y = IC623X3( x )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x           (1,6)     [Ixx Iyy Izz Ixy Ixz Iyz]
%
%   -------
%   Outputs
%   -------
%   y           (3,3)     Inertia matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if (size(x,1) == 3 && size(x,2) == 3 )
  % already a 3x3 matrix
  y = x;
  return;
end

y = [ x(1) x(4) x(5);...
      x(4) x(2) x(6);...
      x(5) x(6) x(3)];
 

%--------------------------------------
% $Date: 2020-04-22 14:36:52 -0400 (Wed, 22 Apr 2020) $
% $Revision: 51915 $
