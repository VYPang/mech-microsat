function xDot = FRB( x, ~, inr, invInr, tExt )

%% Rigid body right-hand-side.
%   See also RBModel.
%
%--------------------------------------------------------------------------
%   Form:
%   xDot = FRB( x, t, inr, invInr, tExt )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x            (7,1)     The state vector [q;w]
%   t            (1,1)     Time
%   inr          (3,3)     Inertia
%   invInr       (3,3)     Inverse inertia
%   tExt         (3,1)     External torque
%
%   -------
%   Outputs
%   -------
%   xDot         (7,1)     The derivative of the state vector
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

xDot   = [QIToBDot(x(1:4),x(5:7));...
          RBModel(inr,x(5:7),tExt,invInr)];  


%--------------------------------------
% $Date: 2019-12-11 22:44:52 -0500 (Wed, 11 Dec 2019) $
% $Revision: 50558 $
