function t = GravityGradientFromR( q, inr, r, mu )

%%   Computes a gravity gradient torque from r and mu.
%   q transforms from the frame in which r is defined to the body frame.
%
%   Since version 10.
%--------------------------------------------------------------------------
%   Form:
%   t = GravityGradientFromR( q, inr, r, mu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   q                  (4,1) Quaternion from the r frame to Body
%   inr                (3,3) Inertia matrix
%   r                  (3,:) Orbit from the earth to the spacecraft
%                            in the spacecraft body frame (the same frame as
%                            the inertia matrix.)
%   mu                 (1,1) Gravitational Parameter
%
%   -------
%   Outputs
%   -------
%   t                  (3,:) Torque (units will be consistent with inertia)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2011 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin == 0 )
  mu  = Constant('mu earth');
  inr = diag([100;20;300]);
  n   = 1000;
  a   = linspace(0,6*pi,n);
  r   = 7000*[cos(a);sin(a);zeros(1,n)];
  q   = [ones(1,n);zeros(3,n)];
  GravityGradientFromR( q, inr, r, mu );
  return;
end

n = size(r,2);
t = zeros(3,n);

for k = 1:n
    rK     = QForm( q(:,k), r(:,k) );
    t(:,k) = 3*mu*Cross(rK,inr*rK)/Mag(rK)^5;
end

% Default output
%---------------
if( nargout == 0 )
  Plot2D( 1:n, t, 'Step', {'T_x' 'T_y' 'T_z'}, 'Gravity Gradient' );
  clear t
end
 

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:19:59 -0400 (Thu, 11 May 2017) $
% $Revision: 44571 $
