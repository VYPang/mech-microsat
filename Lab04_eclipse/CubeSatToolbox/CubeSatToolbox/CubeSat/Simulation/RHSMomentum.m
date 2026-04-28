function hDot = RHSMomentum( ~, ~, torque )

%% RHS for momentum in the inertial frame.
% dh/dt = torque
%
%--------------------------------------------------------------------------
%   Form:
%   hDot = RHSMomentum( h, t, torque )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   h            (3,1)     Angular momentum
%   t            (1,1)     Time (unused)
%   torque       (3,1)     Torque vector
%
%   -------
%   Outputs
%   -------
%   hDot         (4,1)     Momentum derivative
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 9.
%--------------------------------------------------------------------------

hDot = torque;


%--------------------------------------
% $Date: 2019-11-25 23:27:02 -0500 (Mon, 25 Nov 2019) $
% $Revision: 50395 $
