function [force, torque] = CubeSatAero( p, d )

%% Aerodynamic model for a CubeSat. 
% Contains a built-in demo for a 1U CubeSat in a 6500 km orbit.
% Also contains an option to retrieve the default data structure.
% Note that it is most efficient to combine the areas into one per face
% for simple CubeSat models - i.e. 6 areas.
%
% The attitude model in CubeSatAttitude will be used if p.q is empty.
%--------------------------------------------------------------------------
%   Form:
%   [force, torque] = CubeSatAero( p, d )
%   d = CubeSatAero     % data structure
%   CubeSatAero         % demo for LEO orbit with LVLH alignment
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   p         (.)    Profile data structure
%                    .r    (3,1) ECI position
%                    .v    (3,1) ECI velocity
%                    .q    (4,1) ECI to body quaternion
%                    .vRel (3,1) ECI velocity relative to the earth (km/s)
%                    .rho  (1,1) Atmospheric density (kg/m^3)
%   d         (.)    Aero data structure
%                    .cD         (1,1) Drag coefficient
%                    .nFace      (3,:) Face outward unit normals
%                    .rFace      (3,:) Face vectors with respect to the origin
%                    .cM         (3,1) Center of mass with respect to the orgin
%                    .area       (1,:) Area of each face (m^2)
%                    .att         (.)  Attitude data structure 
%
%   -------
%   Outputs
%   -------
%   force    (3,1)   ECI force (N)
%   torque   (3,1)   Body fixed torque (Nm)
%
%--------------------------------------------------------------------------
%   See also CubeSatFaces, CubeSatAttitude
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2014, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2014-04-21: Update demo to use RVFromKepler for the orbit.
%   2016.1: Fix x axis of demo plot; use attitude in p if available
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d = DefaultStruct;
  if nargout == 1
    force = d;
    return; 
  end
  % Demo in LEO with LVLH pointing (the default)
  [r,v,t] = RVFromKepler([6500 0 0 0 0 0]);
  % Set the atmospheric density (kg/m3)
  p.rho  = 1.6e-9;
  p.q    = [];
  
  force  = zeros(3,100);
  for k = 1:100
    p.v    = v(:,k);
    p.r    = r(:,k);
    p.vRel = p.v;
    force(:,k) = CubeSatAero( p, d );
  end

  [tPlot, cTime] = TimeLabl( t );
  Plot2D( tPlot, force*1e6, cTime, {'F_x (\mu N)' 'F_y(\mu N)' 'F_z(\mu N)'}, 'Cubesat Aero Force');
  clear force
  return
end

% The vector dynamic pressure in the ECI frame
%---------------------------------------------
vMag = Mag(p.vRel);
qAero = 0.5*p.rho*vMag*p.vRel*1e6;

if( isempty(p.q) )
	qECIToBody = CubeSatAttitude( d.att, p.r, p.v );
else
  qECIToBody = p.q;
end

qBody      = QForm( qECIToBody, qAero );
uBody      = QForm( qECIToBody, p.vRel/vMag);

force      = zeros(3,1);
torque     = zeros(3,1);

% For each face, compute in the body frame
% Only faces towards the velocity vector contribute.
%---------------------------------------------------
nDot = Dot(uBody,d.nFace);
kFace = find(nDot>0);
for k = kFace
  fFace  = - nDot(k)*qBody*d.area(k)*d.cD;
  force  = force  + fFace;
  torque = torque + Cross( d.rFace(:,k) - d.cM, fFace );
end

% Force is in the ECI frame
%--------------------------
force = QTForm( qECIToBody, force );

function d = DefaultStruct
% Default data for a 1U CubeSat

d.cD              = 2.7;
d.cM              = [0;0;0];
[a,n,r]           = CubeSatFaces( '1U',1 );
d.area            = a;
d.nFace           = n;
d.rFace           = r; 
d.att.type        = 'lvlh';
d.att.qLVLHToBody = [1;0;0;0];


%--------------------------------------
% $Date: 2019-09-07 14:57:11 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49731 $
