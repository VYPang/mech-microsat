function [qD, b, c, d, dqdt] = QIToBDot( q, w, dT )
	
%% Computes the time derivative of a quaternion. 
% The quaternion transforms from the inertial frame to the body frame. 
% Requires the angular velocity measured in the body frame.
%--------------------------------------------------------------------------
%   Form:
%   qD                 = QIToBDot( q, w )	
%   [a, b, c, d, dqdt] = QIToBDot( q, w )
%   [a, b, c, d, dqdt] = QIToBDot( q, w, dT )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   q              (4,1)  Quaternion from a to b
%   w              (3,1)  Rate of b with respect to a measured in b
%   dT             (1,1)  Time step
%
%   -------
%   Outputs
%   -------
%   qD             (4,1)  Derivative of Q
%
%   or
%
%   a              (4,4)  Plant matrix
%   b              (4,3)  Input matrix
%   c              (4,4)  Measurement matrix
%   d              (4,3)  Feedthrough matrix
%   dqdt           (4,1)  Constant quaternion derivative
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   sSince version 1.
%--------------------------------------------------------------------------

qD   = 0.5*[0, w';-w,-SkewSymm(w)];

if( nargout == 1 )

  qD =  qD*q;

else
  s    = q(1);
  v    = q(2:4);

  b    = 0.5*[v';SkewSymm(v)-s*eye(3)]; 
  dqdt = qD*q;
  c    = eye(4);
  d    = zeros(4,3);
  
  if( nargin == 3 )
    [qD,b] = C2DZOH(qD,b,dT); 
  end
  
end

%--------------------------------------
% $Date: 2020-04-27 15:36:14 -0400 (Mon, 27 Apr 2020) $
% $Revision: 51998 $
