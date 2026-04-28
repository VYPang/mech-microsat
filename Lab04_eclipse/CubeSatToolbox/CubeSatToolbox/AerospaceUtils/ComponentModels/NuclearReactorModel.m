function [v, f, d] = NuclearReactorModel( powerThermal, conversionEfficiency, unitVector )

%% Get CAD vertices and faces for an SP-100 based space nuclear reactor.
% This model assumes:
%
% * 1600 kWThermal reactor
% * 33% efficient Stirling engine conversion
% * 591 deg-K radiator temperature
%
% Type NuclearReactorModel for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f, d] = NuclearReactorModel( powerThermal, powerElectric, unitVector )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   powerThermal         (1,1)    Output power
%   conversionEfficiency (1,1)    Electrical power
%   unitVector           (3,1)    Unit vector
%
%   -------
%   Outputs
%   -------
%   v                    (:,3)    Vertices
%   f                    (:,3)    Faces
%   d                    (1,1)    Data
%                                 .mass
%                                 .power
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  powerThermal = 1600;
  NuclearReactorModel( powerThermal );
  return;
end

if( nargin < 2 )
  powerConversionEfficiency = 0.32;
end

if( nargin < 3 )
  unitVector = [0;0;1];
end

d.power = GenericProperties( 'power' );

% Reference Masses at 1600 kWt
%-----------------------------
massReactor  =  450*powerThermal/1600;  
massShield   = 2500*powerThermal/1600;
massRadiator = 0.5*1.5*200*powerThermal/1600;
massBoom     = 200*powerThermal/1600;
areaRadiator = 200*powerThermal/1600;

l1 =  0.5;
l2 =  0.28;
l3 =  areaRadiator/10;
w  =  areaRadiator/40;

[v{1}, f{1}]                 = Frustrum( 0.125,  0.125, l1, 6, 0, 0 );
[v{2}, f{2}]                 = Frustrum( 1.3/2, 1.15/2, l2, 6, 0, 0 );
[v{3}, f{3}]                 = Box( 0.125, 0.125, 20 );
[v{4}, f{4}]                 = Box( 0.02, w, 20 );
[v{5}, f{5}]                 = Box( 0.02, w, 20 );
v{2}(:,3)                    = v{2}(:,3) + l1;
v{3}(:,3)                    = v{3}(:,3) + l1 + l2 + l3/2;
v{4}(:,3)                    = v{4}(:,3) + l1 + l2 + l3/2;
v{4}(:,2)                    = v{4}(:,2) + w/2 + 0.0625;
v{5}(:,3)                    = v{5}(:,3) + l1 + l2 + l3/2;
v{5}(:,2)                    = v{5}(:,2) - w/2 - 0.0625;

vX = v{1};
fX = f{1};
for j = 2:length(v)
  fX = [fX;f{j} + size(vX,1)];
  vX = [vX;v{j}];
end

m(1) = struct('mass',massReactor, 'cM',[0;          0;        0.5*l1],'inertia',Inertias(massReactor, [0.125 l1],       'cylinder', 1) );
m(2) = struct('mass',massShield,  'cM',[0;          0;l1+     0.5*l2],'inertia',Inertias(massShield,  [0.65  l2],       'cylinder', 1) );
m(3) = struct('mass',massBoom,    'cM',[0;          0;l1+l2 + 0.5*l3],'inertia',Inertias(massBoom,    [0.125 0.125 l3], 'box', 1)      );
m(4) = struct('mass',massRadiator,'cM',[0;-w/2-0.0625;l1+l2 + 0.5*l3],'inertia',Inertias(massReactor, [0.02 w l3],      'box', 1)      );
m(5) = struct('mass',massRadiator,'cM',[0; w/2+0.0625;l1+l2 + 0.5*l3],'inertia',Inertias(massReactor, [0.02 w l3],      'box', 1)      );

d.mass                    = AddMass( m );

% Transform the mass properties
%------------------------------
m              = Q2Mat( U2Q( unitVector, [0;0;1] ) )';
d.mass.inertia = m*d.mass.inertia*m';
d.mass.cM      = m*d.mass.cM;
vX = (m*vX')';
fX = fliplr(fX);

% Draw the object
%----------------
if( nargout == 0 )
  DrawVertices(vX,fX,'Nuclear Reactor')
  clear v f
else
  v = vX;
  f = fX;
end

% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $
