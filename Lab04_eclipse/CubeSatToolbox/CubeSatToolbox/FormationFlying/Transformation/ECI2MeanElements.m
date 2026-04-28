function [elRefMean, dElMean] = ECI2MeanElements(xRefECI, xRelECI, J2)

%% Computes mean orbital elements from reference ECI position and velocity
%
%   Since version 7.
%--------------------------------------------------------------------------
%   Form:
%   [elRefMean, dElMean] = ECI2MeanElements(xRefECI, xRelECI, J2);
%--------------------------------------------------------------------------
%   Note: it is assumed that all inputs have the same time-tag.
%
%   ------
%   Inputs
%   ------
%   xRefECI          (6,1)    reference position & velocity in ECI frame
%   xRelECI          (6,:)    relative positions & velocities in ECI frame
%   J2                (1)     size of J2 perturbation
%
%   -------
%   Outputs
%   -------
%   elRefMean        (1,6)    mean orbital elements of the reference orbit
%   dElMean          (:,6)    mean orbital element differences
%
%     NOTE: Both element sets are in Alfriend format [a,theta,i,q1,q2,W]
%
%--------------------------------------------------------------------------
%  References:  Terry Alfriend, Texas A&M University
%               Joe Mueller, Princeton Satellite Systems
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
   [elRefMean, dElMean] = RunDemo;
   return;
end

nSC     = size(xRelECI,2);
dElMean = zeros(nSC,6);

% Reference position and velocity
%--------------------------------
rRef = xRefECI(1:3,1);
vRef = xRefECI(4:6,1);

% Osculating elements of reference
%---------------------------------
[elRefOsc,~,nu] = RV2El( rRef, vRef );          % Standard elements
elRefOsc        = El2Alfriend( elRefOsc, nu );  % Alfriend elements

% Mean elements of reference
%---------------------------
elRefMean = Osc2Mean( elRefOsc, J2 );

for i=1:nSC
   
   % Position and velocity
   %----------------------
   r     = rRef + xRelECI(1:3,i);
   v     = vRef + xRelECI(4:6,i);

   % Osculating elements
   %--------------------
   [elOsc,~,nu] = RV2El( r, v );             % Standard elements
   elOsc        = El2Alfriend( elOsc, nu );  % Alfriend elements
   
   % Mean elements
   %--------------
   elMean = Osc2Mean( elOsc, J2 );
   
   % Mean element differences
   %-------------------------
   dElMean(i,:) = OrbElemDiff( elRefMean, elMean, 1 );
   
end

%--------------------------------------------------------------------------
% Run the Built-in Demo
%--------------------------------------------------------------------------
function [elRefMean, dElMean] = RunDemo

nav     = DefaultNavigationData;
xRefECI = [nav.x;   nav.y;   nav.z; nav.vx; nav.vy; nav.vz];
xRelECI = [nav.dx;  nav.dy;  nav.dz; nav.dvx; nav.dvy; nav.dvz];
J2      = 0.001082;

[elRefMean, dElMean] = ECI2MeanElements(xRefECI, xRelECI, J2);

disp('======================================');
fprintf('elRefMean:\t[%5.8f, %5.8f, %5.8f, %5.8f, %5.8f, %5.8f]\n\n',elRefMean);
fprintf('dElMean:  \t[%5.8f, %5.8f, %5.8f, %5.8f, %5.8f, %5.8f]\n\n',dElMean');
disp('=======================================');

%--------------------------------------------------------------------------
%   Default Navigation Data
%--------------------------------------------------------------------------
function nav = DefaultNavigationData

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
% $Date: 2019-09-13 11:11:21 -0400 (Fri, 13 Sep 2019) $
% $Revision: 49790 $
