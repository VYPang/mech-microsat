function [qEH,mEH] = QHills( rE, vE )

%% Generate the quaternion that transforms from the ECI to the Hills frame.
%   The coordinates of the Hills frame are defined as:
%        x: Radial
%        z: Orbit-normal, or cross-track
%        y: Completes RHS (Along-track for circular orbits)
%
%   The relative position vector in the Frenet frame can be computed as:
%
%   rF = QForm( qEF, drE );
%
%   where dr is the relative position vector in the ECI frame. Or you may obtain 
%   the transformation matrix, mEF, as the second output. In this case, use:
%
%   rF = mEF*drE;
%--------------------------------------------------------------------------
%   Usages:
%   qEH       = QHills( rE, vE );
%   [qEH,mEH] = QHills( rE, vE );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   rE          (3,n) Position vectors
%   vE          (3,n) Velocity vectors
%
%   -------
%   Outputs
%   -------
%   qEH        (4,n) Quaternions
%   qEH        (4,n) Quaternions
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 2002 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

[~,cR]  = size(rE); 

x       = Unit( rE );
z       = Unit( Cross( rE, vE ) );
y       = Unit( Cross( z, x ) );

qEH      = zeros(4,cR);
mEH      = zeros(3,3*cR);

for k = 1:cR
   cols        = 3*k-2:3*k;
   mEH(:,cols) = [x(:,k)'; y(:,k)'; z(:,k)'];
   qEH(:,k)    = Mat2Q( mEH(:,cols) );
end

if( nargout == 0 )
  Plot2D(1:cR,qEH,'Sample','Quaternion','Q ECI To Hills');
  clear qEH
end

%--------------------------------------
% $Date: 2020-04-27 15:36:14 -0400 (Mon, 27 Apr 2020) $
% $Revision: 51998 $
