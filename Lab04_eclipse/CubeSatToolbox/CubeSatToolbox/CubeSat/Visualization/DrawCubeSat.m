function h = DrawCubeSat( v, f, d )

%% Draw a CubeSat with surface normals.
% The vertices and faces can be obtained from CubeSatModel. If d or d.surfData
% is input after the faces, it will draw surface normals.
%--------------------------------------------------------------------------
%   Form:
%   h = DrawCubeSat( v, f, d )
%   DrawCubeSat;               % Demo
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   v    	(:,3)   Vertices
%   f    	(:,3)   Faces
%   d   	 (.)    Data structure from the function RHSCubeSat
%                  .surfData  (.)  Surface data
%                  .nFace    (3,n) Face normals
%                  .rFace    (3,n) Face locations (m)
%
%   -------
%   Outputs
%   -------
%   h     (1,1)   Figure handle
%
%--------------------------------------------------------------------------
%   See also CubeSatModel, RHSCubeSat
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%   2017.2 Add darker lines for faces with high absorption coefficients
%--------------------------------------------------------------------------
%%

if nargin == 0
  d = CubeSatModel( 'struct' );
  [v, f, d] = CubeSatModel( [1 2 3], d );
  DrawCubeSat( v, f, d );
  return;
end

rF = [];
nF = [];
kDark = [];
if nargin > 2
  if isfield(d,'surfData')
    rF = d.surfData.rFace;
    nF = d.surfData.nFace;
    sG = d.surfData.sigma;
    kDark = sG(1,:)>sG(3,:); % absorption greatest coefficient
    kLight = sG(1,:)<=sG(3,:);
  elseif isfield(d,'rFace')
    rF = d.rFace;
    nF = d.nFace;
    kLight = 1:size(rF,2);
  end
end

h = NewFig('CubeSat Model');
patch('vertices',v,'faces',f,'facecolor',[0.8 0.8 0.8]);
XLabelS('x')
YLabelS('y')
ZLabelS('z')
view(3)
grid on
rotate3d on
if ~isempty(rF)
  hold on
  if ~isempty(kDark)
    dark  = [0.2 0 0.4];
    ql = quiver3(rF(1,kLight),rF(2,kLight),rF(3,kLight),nF(1,kLight),nF(2,kLight),nF(3,kLight));
    qd = quiver3(rF(1,kDark),rF(2,kDark),rF(3,kDark),nF(1,kDark),nF(2,kDark),nF(3,kDark));
    set(qd,'color',dark);
  else
    qh = quiver3(rF(1,:),rF(2,:),rF(3,:),nF(1,:),nF(2,:),nF(3,:));
  end
  TitleS('CubeSat with Surface Normals')
else
  TitleS('CubeSat Patches')
end
axis equal
rotate3d on


%--------------------------------------
% $Date: 2019-09-07 15:00:52 -0400 (Sat, 07 Sep 2019) $
% $Revision: 49732 $

