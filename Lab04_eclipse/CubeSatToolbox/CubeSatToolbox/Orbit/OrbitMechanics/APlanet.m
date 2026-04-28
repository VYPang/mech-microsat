function [a, aP] = APlanet( r, mu, rho )

%% Perturbing acceleration due to a planet on a spacecraft.
% The spacecraft is within the sphere of influence of another body. 
% The equations become
%  2 
% d r       mu r
%  --    +   ---- = a
% 	2          3
% dt        |r|
%
% This function is valid when r << rho. Multiple planets can be input at once.
%
%--------------------------------------------------------------------------
%   Form:
%   [a, aP] = APlanet( r, mu, rho )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r           (3,1)   Vector of the spacecraft from the central body
%   mu          (:)     Planet gravitational parameter(s)
%   rho         (3,:)   Vector of the perturbing planet(s) from the central body
%
%   -------
%   Outputs
%   -------
%   a           (3,1)   Total acceleration
%   aP          (3,:)   Accelerations of individual planets
%
%--------------------------------------------------------------------------
%   Reference: Bond, V.R., M.C. Allman, Modern Astrodynamics
%              Princeton University Press, 1996, pp. 203-204.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1996 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------


n = length(mu);

a = [0;0;0];
aP = zeros(3,n);

for k = 1:n
  d       = r - rho(:,k);
  q       = r'*(r - 2*rho(:,k))/(rho(:,k)'*rho(:,k));
  f       = q*( (3 + 3*q + q^2)/(1 + (1+q)^1.5) );
  aP(:,k) = mu(k)*(r + f*rho(:,k))/Mag(d)^3;
  a       = a - aP(:,k);
end


%--------------------------------------
% $Date: 2016-06-23 10:38:43 -0400 (Thu, 23 Jun 2016) $
% $Revision: 42689 $
