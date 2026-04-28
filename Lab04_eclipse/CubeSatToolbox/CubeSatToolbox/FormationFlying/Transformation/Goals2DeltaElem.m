function dEl = Goals2DeltaElem( el0, goals, J2 )

%% Computes the desired orbital element differences, given the formation flying 
%   "goals" and the measured orbital elements.
%
%   Since version 7.
%--------------------------------------------------------------------------
%   Form:
%   dEl = Goals2DeltaElem( el0, goals, J2 );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el0             (1,6)     Measured orbital elements (Alfriend format) [a,theta,i,q1,q2,W]
%   goals            (.)      Geometric goals data structure with following fields:
%     - y0          (1,:)        along-track offset                             [km]
%     - aE          (1,:)        semi-major axis of relative ellipse            [km]
%     - beta0       (1,:)        angle on ellipse at perigee                   [rad]
%     - zInc        (1,:)        cross-track amplitude due to inclination diff  [km]
%     - zLan        (1,:)        cross-track amplitude due to right ascen diff  [km]
%   J2               (1)      Size of the J2 perturbation (default 0)
%
%   -------
%   Outputs
%   -------
%   dEl   (:,6)     desired orbital element differences
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%    Copyright (c) 2002 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 3 )
   J2 = 0;
end

xH  = Goals2Hills( el0, goals );
dEl = Hills2DeltaElem( el0, xH, J2 );

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 15:16:37 -0400 (Tue, 09 May 2017) $
% $Revision: 44523 $
