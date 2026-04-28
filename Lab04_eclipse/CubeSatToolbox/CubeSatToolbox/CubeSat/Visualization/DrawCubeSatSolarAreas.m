function h = DrawCubeSatSolarAreas( d )

%% Visualize the solar cell area for the CubeSat.
% Plots the solar cell areas and normals from the power substructure.
% You may pass in the full RHS data structure or the power substructure.
%--------------------------------------------------------------------------
%   Form:
%   h = DrawCubeSatSolarAreas( d )
%   DrawCubeSatSolarAreas;          % Demo
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d      (.)     Model data structure from RHSCubeSat
%                  .power  (.)  Power data, see also SolarCellPower 
%                      .solarCellArea    (1,:) Total cell area (m^2)
%                      .solarCellNormal  (3,:) Unit normal vector to the cell face
%
%   -------
%   Outputs
%   -------
%   h     (1,1)   Figure handle
%
%--------------------------------------------------------------------------
%   See also SolarCellPower, RHSCubeSat
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%--------------------------------------------------------------------------
%%

if nargin < 1
  % Demo
  d.power = SolarCellPower;
  DrawCubeSatSolarAreas( d );
  return;
end

if isfield(d,'power')
  d = d.power;
end

% size of elemental area in cm
r = sqrt(d.solarCellArea*10000);
rMax = max(r); % cm

h = NewFig('DrawCubeSatSolarAreas');
axes;
hold on;

for k = 1:length(d.solarCellArea)
  n1 = d.solarCellNormal(:,k);
  n2 = cross(n1,[1;0;0]);
  if Mag(n2)>1e-2
    n2 = Unit(n2);
  else
     n2 = cross(n1,[0;1;0]);
     if Mag(n2)>1e-2
        n2 = Unit(n2);
     else
       % last chance, try z
      n2 = cross(n1,[0;0;1]);
      if Mag(n2)>1e-2
        n2 = Unit(n2);
      else
        error('Could not find a perpendicular vector.')
      end
     end
  end

  n3 = Unit(cross(n1,n2));

  B = [n1 n2 n3];

  v = B*r(k)*[0 0.5 0.5; 0 -0.5 0.5; 0 -0.5 -0.5; 0 0.5 -0.5]';
  rK = n1*rMax;
  v = v + repmat(rK,1,4);
  patch(v(1,:),v(2,:),v(3,:),'b')
  nS = 1.5*rMax*n1;
  quiver3(rK(1),rK(2),rK(3),nS(1),nS(2),nS(3),0,'r')
  
end

grid on;
view(3)
XLabelS('x')
YLabelS('y')
ZLabelS('z')
TitleS('Cell Area (cm^2) and Normals')
axis equal
      

%--------------------------------------
% $Date: 2019-09-07 15:00:52 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49732 $