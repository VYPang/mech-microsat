function [force, torque] = CubeSatRadiationPressure( p, d )

%% Radiation pressure model for a CubeSat around the Earth. 
%
% Includes solar pressure, earth radiation pressure, and earth albedo.
% Has a built-in demo. Retrieve a default data structure
% by calling with no inputs, or append the additional fields to an
% existing structure. Set d.planet to 0 (false) to ignore planetary disturbances
% and calculate only solar pressure.
%--------------------------------------------------------------------------
%   Forms:
%   [force, torque] = CubeSatRadiationPressure( p, d )
%   d = CubeSatRadiationPressure       % default d
%   d = CubeSatRadiationPressure( d )  % add needed fields to d
%   CubeSatRadiationPressure           % 
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   p         (.)    Data structure from CubeSatEnvironment
%                    .r    (3,1) ECI position
%                    .v    (3,1) ECI velocity
%                    .q    (4,1) ECI to body quaternion
%                    .uSun (3,1) ECI sun unit vector
%                    .solarFlux (1,1) Solar flux at position (W/m2)
%                    .nEcl      (1,1) Normalized source intensity from Eclipse
%                    .radiation (1,1) Planet radiation 
%                    .albedo    (1,1) Planet albedo fraction
%                    .radiusPlanet (1,1) Planet radius (km)
%   d         (.)    Surface data structure
%                    .nFace      (3,:) Face outward unit normals
%                    .rFace      (3,:) Face vectors with respect to the origin
%                    .cM         (3,1) Center of mass with respect to the orgin
%                    .area       (1,:) Area of each face
%                    .sigma      (3,:) Radiation coefficients [absorbed;
%                                      specular; diffuse]
%                    .planet     (1,1) Flag for planetary contributions
%                    .att         (.)  Attitude data structure
%
%   -------
%   Outputs
%   -------
%   force    (3,1)   ECI force (N)
%   torque   (3,1)   Body fixed torque (Nm)
%
%--------------------------------------------------------------------------
% See also SolarF, CubeSatAttitude
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8 (2009). 
%   2016-02-23: Update to use CubeSatEnvironment. Input p now provides the
%   solar flux, eclipse fraction, and planet radius.
%   2017.2 Change default optical parameters to 100% diffuse
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  % The demo plots the disturbance calculated over one orbit. The
  % disturbances are calculated both with and without the planetary
  % components (albedo and radiation).
  d = DefaultStruct;
  if nargout == 1
    force = d;
    return;
  end
  disp('CubeSatRadiationPressure Demo')
  % Demo in LEO with LVLH pointing
  [r,v,t] = RVFromKepler([6500 0 0 0 0 0]);
  % Use a constant environment except eclipses
  p = CubeSatEnvironment;
  nEcl    = Eclipse(r,p.uSun*p.rSun);
  force   = zeros(3,100);
  for k = 1:100
    p.nEcl = nEcl(k);
    p.r    = r(:,k);
    p.v    = v(:,k);
    [force(:,k),torque] = CubeSatRadiationPressure( p, d );
  end
  [tPlot, cTime] = TimeLabl( t );
  h = Plot2D( tPlot, force*1e6, cTime, {'F_x (\mu N)' 'F_y(\mu N)' 'F_z(\mu N)'},...
    'Cubesat Radiation Force');
  AddFillToPlots(tPlot,nEcl,h,[1 1 1; 0.9 0.9 0.9],0.5);
  clear force
  return
elseif (nargin==1)
  d = p;
  d.sigma = [zeros(2,6);1 1 1 1 1 1];
  d.planet = true;
  force = d;
  return;
end

% Quaternion
%-----------
if isempty(p.q)
  qECIToBody = CubeSatAttitude( d.att, p.r, p.v );
else
  qECIToBody = p.q;
end

% Get the force in the body frame
%--------------------------------
% Solar radiation pressure
uSBody = QForm( qECIToBody, p.uSun );
cLight = 3e8; % speed of light in m/s2
pSolar = p.solarFlux/cLight; % solar pressure
solarF = p.nEcl*SolarF( pSolar, d.sigma, d.nFace, uSBody, d.area );

% Calculate planetary contributions only if requested
if d.planet
  rBody = QForm( qECIToBody, p.r );
  % source is at nadir
  uPR   = -Unit( rBody );
  % scale for the distance from the planet
  pScale = p.radiusPlanet^2/(rBody'*rBody);
  % infrared: diffuse is 1
  sigRad = [0;0;1];
  planetaryF = SolarF( p.radiation/cLight*pScale, sigRad, d.nFace, uPR, d.area );
  albedoF = p.nEcl*SolarF(p.albedo*pSolar*pScale, d.sigma, d.nFace, uPR, d.area );
else
  planetaryF = zeros(3,length(d.area));
  albedoF = zeros(3,length(d.area));
end

force = solarF + planetaryF + albedoF;

% Torque for each face
%---------------------
torques = Cross( d.rFace - repmat(d.cM,1,length(d.area)), force );
torque = sum(torques,2);

% Force is in the ECI frame
%--------------------------
force = QTForm( qECIToBody, sum(force,2) );

%--------------------------------------------------------------------------
% Defaults: an example for 2U
%--------------------------------------------------------------------------
function d = DefaultStruct

d.cM              = [0;0;0];
[a,n,r]           = CubeSatFaces( '2U',1 );
d.area            = a;
d.nFace           = n;
d.rFace           = r; 
d.sigma           = [zeros(2,6);1 1 1 1 1 1]; % diffuse
d.att             = CubeSatAttitude;
d.att.type        = 'lvlh';
d.planet          = true;


%--------------------------------------
% $Date: 2019-09-07 14:57:11 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49731 $
