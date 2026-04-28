function [A, Adot] = GetHillsMats( r0, v0 )

%% Get Hills transformation matrices
% This function takes the position and velocity of a satellite in the ECI
% frame, and returns the A and Adot matrices used for transformation to the
% Hills frame. They are used in the following equations:
%
%   rH = A*(r1-r0);
%   vH = A*(v1-v0) + Adot*(r1-r0);
%
%--------------------------------------------------------------------------
%   Form:
%   [A, Adot] = GetHillsMats( r0, v0 )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r0      (3,1)   Position ECI frame
%   v0      (3,1)   Velocity ECI frame
%
%   -------
%   Outputs
%   -------
%   A       (3,3)   Rotation matrix (position)
%   Adot	(3,3)   Rotation matrix (velocity)
%                   Equal to -Cross( OrbRate(Mag(r0), A )
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%   2019.1 Update default value of mu
%--------------------------------------------------------------------------

x = r0/Mag( r0 ); % x is radial
h = Cross( r0, v0 ); % h is + orbit normal
z = h/Mag(h);
y = Cross( z, x ); % y completes RHS

A = [x'; y'; z'];

% Find the velocity rotation matrix
%----------------------------------
if( nargout > 1 )
   [el,E,nu]	= RV2El(r0,v0);
   a            = el(1);
   e            = el(5);
   mu           = 3.98600436e5;
   n            = sqrt(mu*a^-3);
   thetaDot     = n*power(1+e*cos(nu),2)*power(1-e*e,-3/2);
   w            = -[0; 0; thetaDot ];
   Adot         = Cross( w, A );
end


%--------------------------------------
% $Date: 2020-05-12 17:03:28 -0400 (Tue, 12 May 2020) $
% $Revision: 52245 $
