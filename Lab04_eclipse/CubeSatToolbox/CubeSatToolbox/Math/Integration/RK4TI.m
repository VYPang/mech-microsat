function x = RK4TI( rhs, x, h, a )

%% Fourth order Runge-Kutta integration. RHS is time-independent (TI).
%
%   The right-hand-side function "rhs" computes the state derivative. 
%   "rhs" is a function handle with 2 inputs, evaluated as:
%
%   rhs(x,a)
% 
%--------------------------------------------------------------------------
%   Form:
%   x = RK4TI( rhs, x, h, a )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   rhs        (:)     Right-hand side function handle
%   x         (N,1)    State (column vector)
%   h          (1)     Independent variable step
%   a          (:)     Input provided to rhs function
%
%   -------
%   Outputs
%   -------
%   x         (N,1)    Updated state
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2007 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

ho2 = 0.5*h;
k1  = rhs( x,          a );
k2  = rhs( x + ho2*k1, a );
k3  = rhs( x + ho2*k2, a );
k4  = rhs( x + h*k3,   a );
x   = x + h*(k1 + 2*(k2+k3) + k4)/6;

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $

