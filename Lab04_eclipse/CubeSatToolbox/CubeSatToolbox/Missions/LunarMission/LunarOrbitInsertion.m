function [deltaV, uECI, tBurn] = LunarOrbitInsertion( hLunarOrbit, dR, dV, mI, uE, thrust )

%% Computes parameters for a lunar orbit insertion.
% Computes the total velocity change, the vector direction for the burn
% and the duration of the burn. This always burns in the direction of the
% velocity error. You should approach the moon in the right direction
% so that the resulting orbit is achieved.
%
% If your input is elements dR must be part of the orbit track otherwise
% it won't work. The moon relative position must be at the point in the
% orbit specified by the mean anomaly.
%
% Type LunarOrbitInsertion for a demo.
%
%--------------------------------------------------------------------------
%	Form:
%	[deltaV, uECI, tBurn] = LunarOrbitInsertion( hLunarOrbit, dR, dV, mI, uE, thrust )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   hLunarOrbit	(1,:)	Perigee altitude or lunar orbital elements
%   dR          (3,1)	Relative position vector at start (km)
%   dV          (3,1)	Relative velocity vector at start (km/s)
%   mI          (1,1)	Initial mass (kg)
%   uE          (1,1) Exhaust velocity (m/s)
%   thrust      (1,1) Thrust (N)
%
%   -------
%   Outputs
%   -------
%   deltaV  (1,1)   Velocity change (km/s)
%   uECI    (3,1)   Vector for burn
%   tBurn   (1,1)   Burn duration (sec)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%   2020.1 Fixed error in velocity change. Added elements input.
%--------------------------------------------------------------------------

% Constants
kmToM    = 1000;
muMoon   = Constant('mu moon');
rMoon    = Constant('equatorial radius moon');

% Demo
if( nargin < 1 )  
  Demo
  return
end

if( length(hLunarOrbit) > 1 )
  el        = hLunarOrbit;
  [~,v]     = El2RV(el,[],muMoon);
  deltaV    = v - dV;
  uECI      = Unit(deltaV);
  deltaV    = Mag(deltaV);
else
  % Find the insertion velocity
  rP        = rMoon + hLunarOrbit;
  rA        = Mag(dR);
  aM        = RARP2A( rA, rP );
  vA        = VOrbit( rA, aM, muMoon );
  deltaV    = abs(Mag(dV)-vA);
  uECI      = -Unit(dV);
end

gamma    = exp(deltaV*kmToM/uE);
mF       = mI*(gamma-1)/gamma;
mAve     = mI - 0.5*mF;
tBurn    = deltaV*kmToM*mAve/thrust;

function Demo

muMoon      = Constant('mu moon');
rMoon       = Constant('equatorial radius moon');
hLunarOrbit = 200;
dR          = [2000;0;0];
dV          = [0;3;0];
mI          = 6;
uE          = 9.806*285;
thrust      = 20;
[deltaV, uECI, tBurn] = LunarOrbitInsertion( hLunarOrbit, dR, dV, mI, uE, thrust );
el          = RV2El(dR,dV+uECI*deltaV,muMoon);
[rP,rA]     = AE2RPRA(el(1),el(5));

fprintf('\nPerigee altitude input\n\n');


fprintf('Desired lunar perigee atitude    %8.1f km\n', hLunarOrbit);
fprintf('Resulting lunar perigee altitude %8.1f km\n', rP-rMoon);
fprintf('Resulting lunar apogee altitude  %8.1f km\n', rA-rMoon);
fprintf('Engine exhaust velocity          %8.1f m/s\n', uE);
fprintf('Initial mass                     %8.1f kg\n', mI);
fprintf('Thrust                           %8.1f N\n', thrust);
fprintf('Delta V                          %8.1f km/s\n',     deltaV);
fprintf('Burn duration                    %8.1f sec\n',	tBurn);
fprintf('Position difference [%8.2f %8.2f %8.2f] km\n',	dR);
fprintf('Velocity difference [%8.2f %8.2f %8.2f] km/s\n',	dV);
fprintf('Burn vector ECI     [%8.2f %8.2f %8.2f]\n',	uECI);

[a,e]           = RPRA2AE(1800,2000);
el              = [a 0.01 0 0 e pi];
[deltaV, uECI]  = LunarOrbitInsertion( el, dR, dV, mI, uE, thrust );
elA             = RV2El(dR,dV+uECI*deltaV,muMoon);

fprintf('\nElements input\n\n');

fprintf('Desired Elements   %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f \n', el);
fprintf('Achieved elements  %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f \n', elA);
fprintf('Delta V        %8.1f km/s\n',     deltaV);
fprintf('Burn duration  %8.1f sec\n',	tBurn);
fprintf('Position difference [%8.2f %8.2f %8.2f] km\n',	dR);
fprintf('Velocity difference [%8.2f %8.2f %8.2f] km/s\n',	dV);
fprintf('Burn vector ECI     [%8.2f %8.2f %8.2f]\n',	uECI);

%--------------------------------------
% $Date: 2020-05-08 14:41:04 -0400 (Fri, 08 May 2020) $
% $Revision: 52176 $
