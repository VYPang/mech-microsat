function [a, b, c, d, dwdt] = RBModel( inr, w, t, invInr, dT )

%% Computes the angular acceleration of a rigid body. 
%   invInr and t are not used when computing the state-space model. invInr is
%   optional when computing the right-hand-side but will speed up the routine.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   wdot               = RBModel( inr, w, t, invInr )
%   [a, b, c, d, dwdt] = RBModel( inr, w, t, invInr, dT )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   inr          (3,3)     Inertia matrix
%   w            (3,1)     Body rate in the body frame
%   t            (3,1)     External torque on the body
%   invInr       (3,3)     Inverse inertia matrix (Optional)
%   dT                     Time step
%
%   -------
%   Outputs
%   -------
%   wdot         (3,1)     Angular acceleration
%
%   or
%
%   a            (3,3)     State matrix
%   b            (3,3)     Input matrix
%   c            (3,3)     Output matrix
%   d            (3,3)     Feedthrough matrix
%   dwdt         (3)       State acceleration
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Total angular momentum in the body frame
%-----------------------------------------
h = inr*w;

if( nargout < 2 )

  tT = t - Cross(w,h);
  if( nargin < 4 )
    a    =  inr\tT;
  else
    a    =  invInr*tT;
  end
  
else

  a    =  inr\(SkewSymm(h) - SkewSymm(w)*inr);
  b    =  inr\eye(3);
  c    =  eye(3);
  d    =  zeros(3,3);
  dwdt = -inr\Cross(w,h);
  
  if( nargin == 5 )
    [a,b] = C2DZOH(a,b,dT); 
  end
  
end

%-----------------------------------------------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:15:23 -0400 (Thu, 11 May 2017) $
% $Revision: 44565 $
