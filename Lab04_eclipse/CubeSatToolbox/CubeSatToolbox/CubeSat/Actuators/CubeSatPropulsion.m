function [force, torque, mDot] = CubeSatPropulsion( mass, p, d )

%% Returns the force, torque and mass flow for a cold gas system.
% Will call CubeSatAttitude for the attitude model if p.q is empty.
%--------------------------------------------------------------------------
%   Form:
%   [force, torque, mDot] = CubeSatPropulsion( mass, p, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   mass     (1,1)   Total system mass
%   p         (.)    Data structure
%                    .r    (3,1) ECI position
%                    .v    (3,1) ECI velocity
%                    .q    (4,1) ECI to body quaternion
%   d         (.)    Data structure
%                    .gas            (1,:) Gas name
%                    .throatArea     (1,1) Area of throat (m^2)
%                    .volumeTank     (1,1) Tank volume (m^3)
%                    .temperature    (1,1) Tank temperature (deg-K)
%                    .expansionRatio (1,1) Expansion ratio of nozzle
%                    .rNozzle        (3,n) Position of thruster (m)
%                    .uNozzle        (3,n) Thrust unit vector
%                    .cM             (3,1) Center-of-mass (m)
%                    .pulsewidthFraction (1,n)
%                    .pRegulator     (1,1) Regulator pressure (N/m^2)
%                    .att             (.)  Attitude data structure
%
%   -------
%   Outputs
%   -------
%   force    (3,1)   ECI Force vector (N)
%   torque   (3,1)   Torque vector (N)
%   mDot     (1,1)   Mass flow rate (kg/s)
%
%--------------------------------------------------------------------------
%   See also GasProperties, CubeSatAttitude
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2012, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 8.
% 2016.1: Correct sign of mDot. Remove IdealRkt in favor of a simple thrust
% coefficient. Update attitude handling to allow for p.q
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  d = DefaultStruct;
  if nargout == 1
    force = d;
    return;
  end
  d.cM  = [0.01;0;0];
  p     = struct('r',[],'v',[],'q',[]);
  mass  = 1.0;
  [force, torque, mDot] = CubeSatPropulsion( mass, p, d );
  disp(force);
  disp(torque);
  disp(mDot);
  clear force
  return
end

force  = zeros(3,1);
torque = zeros(3,1);

mFuel  = mass - d.massDry;

if mFuel <= 0
  mDot = 0;
  return;
end

% Pressure using linear scaling for gaseous propellant
R       = 8.314472;
molWt   = GasProperties( d.gas );
p0      = (mFuel/molWt)*R*d.temperature/d.volumeTank;
if( p0 > d.pRegulator)
    p0 = d.pRegulator;
end
% IdealRkt: these terms (throat area, expansion ratio) are hard to come by so
% it's better to use a thrust coefficient based on published thruster specs.
%[thrust,uE]     = IdealRkt( gamma, d.throatArea, p0, 0, d.temperature,...
%                            d.expansionRatio, molWt );
thrust          = p0*d.thrustCoeff;
uE              = d.Isp*9.80665; % m/s
thrustEffective = d.pulsewidthFraction.*thrust;

if( isempty(p.q) )
  qECIToBody = CubeSatAttitude( d.att, p.r, p.v );
else
  qECIToBody = p.q;
end

% For each face
%--------------
for k = 1:size(d.rNozzle,2)
  f      = d.uNozzle(:,k)*thrustEffective(k);
  force  = force  + f;
  torque = torque + Cross( d.rNozzle(:,k) - d.cM, f );
end

% Force is in the ECI frame
%--------------------------
force = QTForm( qECIToBody, force );

% Fuel consumption
%-----------------
thrustTotal = sum(thrustEffective);
mDot        = -thrustTotal/uE;
  
   
function d = DefaultStruct

% thruster properties
d.thrustCoeff         = 0.05/(6895*100); % N/Pa (m2)
d.Isp                 = 68;              % s
d.rNozzle             = [0.05;0;0];
d.uNozzle             = [0;1;0];
% tank properties
d.gas                 = 'nitrogen';
d.temperature         = 280;
d.volumeTank          = (4/3)*pi*0.02^3;
d.pRegulator          = 6895*100;
d.massDry             = 0.99;
d.pulsewidthFraction  = 1.0;
d.cM                  = [0;0;0];
d.att                 = CubeSatAttitude;
d.att.type            = 'eci';
d.att.qECIToBody      = [1;0;0;0];

 
%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
