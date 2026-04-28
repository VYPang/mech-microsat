function [tMM, m, angle] = MomentumUnloading( b, gain, h )

%% Compute the torque from a magnetic momentum unloading system.
% Uses a pseudo-inverse control law. If the magnetic field is
% aligned the the momentum no control is possible and you will
% see a spike in the response. This only works with 3 orthogonal
% torquers. This system works in the inertial frame. m needs to be
% transformed into the body frame.
%
% The dipole commands can be implemented by a linear control of the
% dipole current or by pulsewidth modulation.
%
%--------------------------------------------------------------------------
%   Form:
%   [tMM, m, angle] = MomentumUnloading( b, gain, h )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   b            (3,1)     B-Field (T)
%   gain         (3,1)     Proportional gain (N/Nms)
%   h            (3,1)     Momentum (Nms)
%
%   -------
%   Outputs
%   -------
%   tMM          (3,1)     Total torque
%   m            (:,1)     Dipole commands
%   angle        (1,1)     b dot h
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2019.1 Added demo
%   2020.1 Simplified to least sequare
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  u   = eye(3);
  r   = [7000;0;7000];
  b   = BDipole( r, JD2000 );
  tMM = MomentumUnloading( u, b, 0.01, [1;0;0]);
  DispWithTitle(tMM,'Total Torque');
  clear tMM
  return
end

sB    = Skew(b);
tMM   = gain*h;
m     = pinv(sB*sB)*sB*tMM;
angle = acos(Dot(b,h));

%--------------------------------------
% $Date: 2020-07-02 11:51:05 -0400 (Thu, 02 Jul 2020) $
% $Revision: 52955 $
