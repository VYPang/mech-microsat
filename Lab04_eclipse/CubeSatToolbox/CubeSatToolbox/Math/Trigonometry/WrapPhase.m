function angle = WrapPhase( angle )

%% Wrap a phase angle (or vector of angles) to keep it between -pi and +pi
%--------------------------------------------------------------------------
%   Form:
%   angle = WrapPhase( angle )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   angle            (1,:)    Phase angle [rad]
%
%   -------
%   Outputs
%   -------
%   angle            (1,:)    Wrapped phase angle between -pi and +pi [rad]
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2003 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

kp = find(angle>pi);
kn = find(angle<-pi);

angle(kp) = angle(kp) - ceil((angle(kp)-pi)/(2*pi))*2*pi;
angle(kn) = angle(kn) + abs(floor((angle(kn)+pi)/(2*pi)))*2*pi;

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
