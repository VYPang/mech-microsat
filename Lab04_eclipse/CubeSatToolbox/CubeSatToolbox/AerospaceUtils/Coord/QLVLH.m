function q = QLVLH( r, v )

%% Generate the quaternions that transform from ECI to LVLH coordinates.
% For LVLH coordinates;
% z is in the -r direction
% y is in the - rxv direction
% x completes the set; along v in a circular orbit
%
%--------------------------------------------------------------------------
%   Form:
%   q = QLVLH( r, v )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r          (3,n) Position vectors
%   v          (3,n) Velocity vectors
%
%   -------
%   Outputs
%   -------
%   q          (4,n) Quaternions
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 1.
%--------------------------------------------------------------------------

cR = size(r,2); 

y       = Unit( Cross( v, r ) );
z       = Unit( -r );
x       = Unit( Cross( y, z ) ); 

q       = zeros(4,cR);

for k = 1:cR
  m       = [ x(:,k)';...
              y(:,k)';...
              z(:,k)'];
  q(:,k)  = Mat2Q( m );
end

if( nargout == 0 )
  Plot2D(1:cR,q,'Sample','Quaternion','Q ECI To LVLH');
  clear q
end

%--------------------------------------
% $Date: 2020-02-17 16:09:20 -0500 (Mon, 17 Feb 2020) $
% $Revision: 51289 $
