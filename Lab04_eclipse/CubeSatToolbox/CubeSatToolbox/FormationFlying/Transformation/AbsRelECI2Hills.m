function [rH,vH] = AbsRelECI2Hills( r0, v0, dr, dv )

%% Compute a Hills state from a relative ECI state
% This function takes the absolute position and velocity in the ECI frame along
% with the relative position and velocity in the ECI frame, and computes the
% relative position and velocity in the curvilinear Hill's frame.
%--------------------------------------------------------------------------
%   Form:
%   [rH,vH] = AbsRelECI2Hills( r0, v0, dr, dv );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r0              (3,1) Reference position in ECI frame
%   r0              (3,1) Reference velocity in ECI frame
%   dr              (3,n) Relative position in ECI frame
%   dv              (3,n) Relative velocity in ECI frame
%
%   -------
%   Outputs
%   -------
%   rH              (3,n) Curvilinear Hills frame position [dR;    r1*dTheta;                   dZ   ]
%   vH              (3,n) Curvilinear Hills frame velocity [dRDot; r1*dThetaDot + r1Dot*dTheta; dZDot]
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%--------------------------------------------------------------------------

if( nargin < 1 )
   [rH,vH] = RunDemo;
   return;
end

% First Transform to a Cartesian Hills System
%--------------------------------------------
A         = GetHillsMats( r0, v0 );
r0        = A*r0;
v0        = A*v0;
dr        = A*dr;
dv        = A*dv;

% Now compute the cylindrical coordinates
%----------------------------------------
r0Mag     = Mag( r0 );
r1Mag     = sqrt( power(r0Mag + dr(1,:),2) + power(dr(2,:),2) ); 
dRMag     = r1Mag - r0Mag;
r0MagDot  = Dot(r0,v0) / r0Mag;
dRMagDot  = ( (r0Mag + dr(1,:)).*(r0MagDot + dv(1,:)) + dr(2,:).*(v0(2,:) + dv(2,:)) ) ./ r1Mag - r0MagDot;
phi       = atan2( dr(2,:), r0Mag + dr(1,:) );
phiDot    = ( (r0(1,:) + dr(1,:)).*(v0(2,:)+dv(2,:)) - dr(2,:).*(v0(1,:)+dv(1,:)) ) ./ power(r1Mag,2);

% Express the answer in the curvilinear Hills frame
%--------------------------------------------------
rH = [dRMag; ...
      r0Mag .* phi; ...
      dr(3,:)];

vH = [dRMagDot; ...
      r0MagDot .* phi  +  r0Mag .* phiDot - v0(2,:); ...
      dv(3,:) ];
   
%-------------------------------------------------------------------------------
% Run the Built-in Demo
%-------------------------------------------------------------------------------
function [rH, vH] = RunDemo

nav = DefaultNavigationData;
r0 = [nav.x;   nav.y;   nav.z];
v0 = [nav.vx;  nav.vy;  nav.vz];
dr = [nav.dx;  nav.dy;  nav.dz];
dv = [nav.dvx; nav.dvy; nav.dvz];

[rH, vH] = AbsRelECI2Hills( r0, v0, dr, dv );

disp('======================================');
fprintf('r0:  \t[%5.8f; %5.8f; %5.8f]\n\n',r0);
fprintf('v0:  \t[%5.8f; %5.8f; %5.8f]\n\n',v0);
fprintf('rH:  \t[%5.8f; %5.8f; %5.8f]\n\n',rH);
fprintf('vH:  \t[%5.8f; %5.8f; %5.8f]\n\n',vH);
disp('=======================================');

function nav = DefaultNavigationData

%--------------------------------------------------------------------------
%   Default Navigation Data
%--------------------------------------------------------------------------

% Reference ECI position and velocity
%------------------------------------
nav.x          = 6928.14;
nav.y          = 0.0;
nav.z          = 0.0;
nav.vx         = 0.0;
nav.vy         = 6.18;
nav.vz         = 4.39;

% Reference ECI position and velocity
%------------------------------------
nav.dx(1)      =  0.10;
nav.dy(1)      =  0.10;
nav.dz(1)      =  0.10;
nav.dvx(1)     =  0.01;
nav.dvy(1)     =  0.01;
nav.dvz(1)     =  0.01;
nav.dx(2)      = -0.10;
nav.dy(2)      = -0.10;
nav.dz(2)      = -0.10;
nav.dvx(2)     = -0.01;
nav.dvy(2)     = -0.01;
nav.dvz(2)     = -0.01;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2019-12-24 00:15:38 -0500 (Tue, 24 Dec 2019) $
% $Revision: 50694 $
