function d = CADToSimParameters( fileName, batteryCapacity, powerConversionEff )

%% Convert CAD model to CubeSat arrays.
% The resulting data structure can be used by the dynamical model.
%--------------------------------------------------------------------------
%   Form:
%   d = CADToSimParameters( fileName, batteryCapacity, powerConversionEff )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   fileName            (1,:)   CAD mat file name
%   batteryCapacity     (1,1)   Battery capacity (J)
%   powerConversionEff	(1,1)   Power conversion efficiency
%
%   -------
%   Outputs
%   -------
%   d          (.)    Data structure including
%                       .mass       (1,1)  Total CubeSat Mass (kg)
%                       .inertia    (3,3)  Inertia tensor matrix
%                       .surfData    (.)   Surface properties
%                         .cM              (3,1)  Center of mass (m)
%                         .area            (1,n)  Area for each of n faces (m^2)
%                         .nFace           (3,n)  Unit normal for each face
%                         .r               (3,n)  Position of centroid of each
%                                               face (m) 
%                         .cD              (1)    Coefficient of drag
%                         .sigma           (3,n)  Optical coefficients
%                       .power      (.)    Power data structure
%                         .solarCellNormal (3,N) Normal vector of each solar cell
%                         .solarCellArea   (1,N) Area of each cell (m^2)
%                         .solarCellEff    (1,N) Efficiency of each cell
%                         .consumption     (1,1) Total power consumption (W)
%                         .batteryCapacity (1,1) Battery capacity (J)
%                         .effPowerConversion (1,1) Conversion efficiency
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2011 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 10.
% 2016.1 Update to use RHSCubeSat
%--------------------------------------------------------------------------

%%
% Demo
%-----
if( nargin == 0 )
  d = CADToSimParameters( 'CubeSatGG.mat', 100, 0.8 );
  if nargout == 0
    disp(d)
    clear d;
  end
  return;
end

d = RHSCubeSat;

% Extract data from the CAD model
%--------------------------------
g             = load(fileName);
d.mass        = g.mass.mass; % kg
d.inertia	    = g.mass.inertia;

n           = length(g.component);
sD          = CubeSatAero;
sD.cD       = [];
sD.area     = [];
sD.nFace    = [];
sD.rFace    = [];
sD.sigma    = [];
d.thermal   = [];
d.power.solarCellNormal = [];
d.power.solarCellArea = [];
d.power.consumption = 0;

% Assemble arrays
%----------------
for k = 1:n
  if (~g.component(k).inside)
    m    = length(g.component(k).a);
    sD.area   = [sD.area g.component(k).a'];
    sD.nFace  = [sD.nFace g.component(k).n'];
    sD.rFace  = [sD.rFace g.component(k).r'];
    sD.cD     = [sD.cD g.component(k).aero.cD*ones(1,m)];
    sD.sigma  = [sD.sigma AddOptical(g.component(k).optical,m)];
    d.thermal = [d.thermal AddThermal(g.component(k).thermal,m)];
  end
  if(  contains(lower(g.component(k).name), 'solar panel') )
      d.power.solarCellNormal	= [d.power.solarCellNormal g.component(k).n'];
      d.power.solarCellArea	= [d.power.solarCellArea g.component(k).a'];
      d.power.solarCellEff    = [d.power.solarCellEff g.component(k).power.electricalConversionEfficiency*ones(1,m)];
	end
  d.power.consumption = d.power.consumption + g.component(k).power.powerOn;
end
d.surfData = sD;
d.surfData.cM = g.mass.cM;

% Add battery capacity
%---------------------
d.power.batteryCapacity = batteryCapacity;
d.power.effPowerConversion = powerConversionEff;

%-------------------------------------------------------------------------------
%   Add optical data
%-------------------------------------------------------------------------------
function p = AddOptical( q, m )

p = DupVect([q.sigmaA;q.sigmaD;q.sigmaS],m);

%-------------------------------------------------------------------------------
%   Add thermal data
%-------------------------------------------------------------------------------
function p = AddThermal( q, m )

p = DupVect([q.absorptivity;q.emissivity],m);


%--------------------------------------
% $Date: 2019-09-07 14:57:11 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49731 $
