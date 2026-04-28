function [m, tErr] = MagneticControl( b, tDemand, u, c )

%% Implement instantaneous magnetic control with torquers.
% Magnetic torquers only produce 2-axis torque. This function generates
% a least squares fit that matches the torque the torquers can produce
% to the torque demand. The output is the dipole demand in ATM^2 
% (amp-turn-meter-squared). The scalar cost is any number >= 0. It 
% assumes that the cost of using any dipole is the same. The output will
% need to be pulsewidth modulated if the torquers do not have linear
% actuation.
%
% For example, the torque is T = [m1 m2 m3] x b, or
% 
%  T = -b x [m1 m2 m3]
%
% m1, m2 and m3 are dipoles.  [b x] cannot be inverted hence the least 
% squares. Has a built-in demo.
%--------------------------------------------------------------------------
%   Form:
%   [m, tErr] = MagneticControl( b, tDemand, u, c )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   b          (3,1)  Magnetic Field (T)
%   tDemand    (3,1)  Torque Demand (Nm)
%   u          (3,n)  Unit dipole vectors for n dipoles
%   c          (1,1)  Scalar cost of using a dipole
%
%   -------
%   Outputs
%   -------
%   m          (n,1)  Dipole values (ATM^2)
%   tErr       (3,1)  Torque error (Nm)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2011 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 10.
%--------------------------------------------------------------------------


% Demo
%-----
if( nargin < 1 )
  el     = [6378+350,0.9*pi/2,0,0,0,0];
  [r, v] = El2RV( el );
  q      = QLVLH( r, v );
  jD     = Date2JD([2014 6 1 0 0 0]);
  b      = QForm( q, BDipole( r, jD ) );
  u      = eye(3);
  disp('Check a random torque demand');
  tDemand = 5e-6*randn(3,1);
  [m, tErr] = MagneticControl( b, tDemand, u, 1 );
  disp(m);
  disp(tErr);

  disp('Check for a case in which m = [1;1]');
  u         = u(:,1:2);
  tDemand   = sum(Cross(u,b),2);
  [m, tErr] = MagneticControl( b, tDemand, u, 0 );
  disp(m);
  disp(tErr);

  clear m;
  return
end

% Torque unit vectors transposed
%-------------------------------
gamma   = Cross(u,b);

% Least squares fit
%------------------
m       = (gamma'*gamma + c)\(gamma'*tDemand);

% Compute the torque error
%-------------------------
if( nargout > 1 )
    
	% Compute the achieved torque
  %----------------------------
	t       = sum(gamma*m,2);
	tErr	= t - tDemand;
end


%--------------------------------------
% $Date: 2020-07-02 11:51:05 -0400 (Thu, 02 Jul 2020) $
% $Revision: 52955 $
