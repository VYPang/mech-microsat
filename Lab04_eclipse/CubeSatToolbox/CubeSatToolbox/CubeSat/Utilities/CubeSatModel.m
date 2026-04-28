function [v, f, dRHS] = CubeSatModel( type, d, frameOnly )

%% Generate vertices and faces for a CubeSat model.
% If there are no outputs it will generate a plot with surface normals, or
% you can draw the cubesat model using patch:
%
%   patch('vertices',v,'faces',f,'facecolor',[0.5 0.5 0.5]);
%
% type can be '3U' or [3 2 1] i.e. a different dimension for x, y and z.
%
% Type CubeSatModel for a demo of a 3U CubeSat. 
%
% This function will populate dRHS for use in RHSCubeSat. The surface
% data for the cube faces will be 6 surfaces that are the dimensions of
% the core spacecraft. Additional surfaces are added for the deployable  
% solar panels. Solar panels are grouped into wings that attached to the 
% edges of the CubeSat.
%
% The function computes the inertia matrix, center of mass and total 
% mass. The mass properties of the interior components are computed from
% total mass and center of mass. 
%
% If you set frameOnly to true (or 1), v and f will not contain the 
% walls. However, dRHS will contain all the wall properties.
%--------------------------------------------------------------------------
%   Form:
%   d            = CubeSatModel( 'struct' )
%   [v, f]       = CubeSatModel( type, t )
%   [v, f, dRHS] = CubeSatModel( type, d, frameOnly )
%   Demo:
%   CubeSatModel
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type        (1,:) 'nU' where n may be any number, or [x y z]
%   d            (.)  Data structure for the CubeSat
%           .thicknessWall          (1,1) Wall thickness (mm)
%           .thicknessRail          (1,1) Rail thickness (mm)
%           .densityWall            (1,1) Density of the wall material (kg/m3)
%           .massComponents         (1,1) Interior component mass (kg)
%           .cMComponents           (1,1) Interior components center of mass
%           .sigma                  (3,6) [absorbed; specular; diffuse]
%           .cD                     (1,6) Drag coefficient
%           .solarPanel.dim         (3,1) [side attached to cubesat, side perpendicular, thickness]
%           .solarPanel.nPanels     (1,1) Number of panels per wing
%           .solarPanel.rPanel      (3,w) Location of inner edge of panel
%           .solarPanel.sPanel      (3,w) Direction of wing spine
%           .solarPanel.cellNormal  (3,w) Wing cell normal
%           .solarPanel.sigmaCell   (3,1) [absorbed; specular; diffuse] coefficients
%           .solarPanel.sigmaBack   (3,1) [absorbed; specular; diffuse] 
%           .solarPanel.mass        (1,1) Panel mass
%      - OR -
%   t                               (1,1) Wall thickness (mm)
%   frameOnly   (1,1) If true just draw the frame, optional
%
%   -------
%   Outputs
%   -------
%   v    	(:,3) Vertices
%   f    	(:,3) Faces
%   dRHS	 (.)  Data structure for the function RHSCubeSat
%
%--------------------------------------------------------------------------
%   Reference: CubeSat Design Specification (CDS) Revision 9 
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2010, 2015 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8 (2009)
%   2015-07-29: add rotation matrix to correctly handle tilted solar
%   wings, and add corresponding demo.
%   2016-02-23: Remove default solar panels before constructing wings
%   2017.1: correct bug in cD for solar wings; leave constant
%   2017.2: change default optical properties to 100% diffuse
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  disp('Unusual Shaped CubeSat');
  d                       = CubeSatModel( 'struct' );
  d.thicknessWall         = 4;    % mm
  d.thicknessRail         = 8.5;  % mm
  d.densityWall           = 2700; % kg/m^2
  d.massComponents        = 1;
  d.cMComponents          = [0;0;0];
  d.sigma                 = [1 1 1 1 1 1;zeros(2,6)];
  d.cD                    = 2.7;
  d.solarPanel.nPanels    = 0;
  frameOnly               = true;
  
  CubeSatModel( [2 3 1], d, frameOnly );
  
	disp('3U CubeSat');
  d                       = CubeSatModel( 'struct' );
  d.massComponents        = 3;
  d.solarPanel.dim        = [100 100 10];	% [side attached to cubesat, side perpendicular, thickness]
  d.solarPanel.nPanels    = 3; % Number of panels per wing
  d.solarPanel.rPanel     = [50 -50 0 0;0 0 50 -50;150 150 150 150]; % Location of inner edge of panel
  d.solarPanel.sPanel     = [1 -1 0 0;0 0 1 -1;0 0 0 0];
  d.solarPanel.cellNormal = [0 0 0 0;0 0 0 0;1 1 1 1]; % Cell normal
  d.solarPanel.sigmaCell  = [1;0;0];    % [absorbed; specular; diffuse]
  d.solarPanel.sigmaBack  = [0;0;1];    % [absorbed; specular; diffuse]
  d.solarPanel.mass       = 0.1;
  
  [v, f, d] = CubeSatModel( '3U', d );
  DrawCubeSat( v, f, d );
  
  if( nargout == 0 )
    clear v
  end
  return;
end

% Return the default data structure
%----------------------------------
if( ischar(type) && strcmp(type,'struct') )
  v = DefaultStruct;
  return;
end
if( isnumeric(d) )
  thicknessWall = d;
  d = DefaultStruct;
  d.thicknessWall = thicknessWall;
end

if( nargin < 3 || ~frameOnly )
  drawWalls = true;
else
  drawWalls = false;
end

% CubeSat constants
%------------------
mmToM       = 0.001; % m/mm
baseOffset	= 1.5;  % mm
c           = 100;  % mm
zExtension  = 13.5;	% mm

% Determine the dimensions from the type
%---------------------------------------
if (ischar(type))
  j     = strfind( lower(type), 'u' );
  l(3)	= str2double( type(1:(j-1)) );
  l(1)  = 1;
  l(2)  = 1;
else
  if length(type)~=3
    error('Please provide the U along x, y, and z.')
  end
  l = type;
end

% Convert to meters
%------------------
w   = d.thicknessRail*mmToM; % Rail width
zW	= l(3)*c*mmToM;
xW 	= l(1)*c*mmToM;
yW	= l(2)*c*mmToM;
t   = d.thicknessWall*mmToM;

% Initialize the mass properties to zero
%---------------------------------------
m = AddMass;

% Rails
%------
zR        = zW + zExtension*mmToM;
xR        = w;
yR        = w;
[vR, fR]  = Box( xR, yR, zR ); 
massBox   = xR*yR*zR*d.densityWall;
inrBox    = Inertias( massBox, [xR, yR, zR], 'box', 1 );

xL        = [xW - w  xW - w -xW + w -xW + w]/2;
yL        = [yW - w -yW + w -yW + w  yW - w]/2;

v         = [];
f         = [];
n         = size(vR,1);
for kV = 1:4
	v           = [v;vR + DupVect([xL(1,kV) yL(1,kV) -baseOffset*mmToM],n)];
	f           = [f;fR+(kV-1)*n];
  mK.mass     = massBox;
  mK.inertia  = inrBox;
  mK.cM       = [xL(1,kV);yL(1,kV);-baseOffset*mmToM];
  m           = AddMass( mK, m );
end

% Draw the x rails
%-----------------
[vR, fR]	= Box( xW - 2*w, w, w );
massBox   = (xW - 2*w)*w*w*d.densityWall;
inrBox    = Inertias( massBox, [xW - 2*w, w, w], 'box', 1 );

z         = 0.5*zW;
y         = (yW - w)/2;
r         = [0 y z;0 -y z;0 y -z; 0 -y -z];
for kV = 1:4
	v           = [v;vR + DupVect(r(kV,:),n)]; %#ok<*AGROW>
	f           = [f;fR+(kV-1)*n+4*n];
  mK.mass     = massBox;
  mK.inertia  = inrBox;
  mK.cM       = r(kV,:)';
  m           = AddMass( mK, m );
end

% Draw the y rails
%-----------------
[vR, fR]	= Box( w, yW - 2*w, w );
massBox   = (yW - 2*w)*w*w*d.densityWall;
inrBox    = Inertias( massBox, [w, yW - 2, w], 'box', 1 );
x         = (xW - w)/2;
r         = [x 0 z;-x 0  z;x 0  -z; -x  0 -z];
for kV = 1:4
	f           = [f;fR + size(v,1)];
	v           = [v;vR + DupVect(r(kV,:),n)];
  mK.mass     = massBox;
  mK.inertia  = inrBox;
  mK.cM       = r(kV,:)';
  m           = AddMass( mK, m );
end

% Walls
%------
r = [   xW-t -xW+t  0     0     0   0;...
        0     0     yW-t -yW+t  0   0;...
        0     0     0     0     zW -zW]'*0.5;

xW = xW - 2*w;
yW = yW - 2*w;
    
s  = [  t  t  xW xW  xW xW;...
        yW yW  t  t  yW yW;...
        zW zW zW zW   t  t ];

% X and Y faces
%--------------
for kV = 1:4
  if( drawWalls )
    [vP, fP]    = Box( s(1,kV), s(2,kV), s(3,kV) ); 
    n           = size(vP,1);
    f           = [f;fP + size(v,1)];
    v           = [v;vP + DupVect(r(kV,:),n)];
  end
	massBox     = s(1,kV)*s(2,kV)*s(3,kV)*d.densityWall;
	inrBox      = Inertias( massBox, [s(1,kV), s(2,kV), s(3,kV)], 'box', 1 );
	mK.mass     = massBox;
	mK.inertia  = inrBox;
	mK.cM       = r(kV,:)';
	m           = AddMass( mK, m );
end

% Z faces
%--------
for kV = 5:6
  if( drawWalls )
    [vP, fP]    = Box( xW, yW, t );
    n           = size(vP,1);
    f           = [f;fP + size(v,1)];
    v           = [v;vP + DupVect(r(kV,:),n)];
  end
	massBox     = xW*yW*t*d.densityWall;
	inrBox      = Inertias( massBox, [xW, yW, t], 'box', 1 );
	mK.mass     = massBox;
	mK.inertia  = inrBox;
	mK.cM       = r(kV,:)';
	m           = AddMass( mK, m );
end

% Add the components properties
%------------------------------
mI.mass     = d.massComponents;
mI.inertia	= Inertias(mI.mass,[xW,yW,zW],'box',1);
mI.cM       = d.cMComponents;
m           = AddMass( mI, m );

% Prepare to enter the RHS data
%------------------------------
dRHS = RHSCubeSat;

% Add in surface properties data; surfaces are +X +Y +Z -X -Y -Z
%-------------------------------
[a,n,r] = CubeSatFaces( type, true );
dRHS.surfData.area  = a;  
dRHS.surfData.nFace = n;
dRHS.surfData.rFace = r;
dRHS.surfData.sigma = d.sigma;
dRHS.surfData.cD    = d.cD;

% Add the solar panels
%---------------------
if( d.solarPanel.nPanels>0 )
  % Remove the default panels
  dRHS.power.solarCellArea = [];
  dRHS.power.solarCellNormal = [];
  % Add the solar wings
  [v,f,dRHS,m] = AddSolarPanels(d,v,f,dRHS,m);
end

% Store the properties in the RHS
%--------------------------------
dRHS.inertia     = m.inertia;
dRHS.mass        = m.mass;
dRHS.surfData.cM = m.cM;

% Default output
%---------------
if( nargout == 0 )
  if ischar(type)
    s = sprintf('%s Cubesat', type );
  else
    s = sprintf('%d %d %d Cubesat', type );
  end
  DrawCubeSat(v,f,dRHS)
  TitleS(s)
end
 
%--------------------------------------------------------------------------
% Add solar panels
% [v,f,dRHS,m] = AddSolarPanels(d,v,f,dRHS,m)
%--------------------------------------------------------------------------
function [v,f,dRHS,m] = AddSolarPanels(d,v,f,dRHS,m)

dims = d.solarPanel.dim*mmToM;
area = dims(1)*dims(2);

% Outer loop for each wing. Inner loop for each panel
%----------------------------------------------------
for k = 1:size(d.solarPanel.rPanel,2)
  
  % Determine properties from the edge locations
  %--------------------------------------------
  nP  = d.solarPanel.cellNormal(:,k);
  sP  = d.solarPanel.sPanel(:,k);
  xP  = Unit(Cross( sP, nP ));
  b   = [xP sP nP];
  dR  = d.solarPanel.sPanel(:,k)*dims(1);
  
  rP  = d.solarPanel.rPanel(:,k)*mmToM + 0.5*dR;

  for jV = 1:d.solarPanel.nPanels
    
    mJ.inertia          = b*Inertias(d.solarPanel.mass,dims,'box',1)*b';
    mJ.mass             = d.solarPanel.mass;
    mJ.cM               = rP;   
    m                   = AddMass(m,mJ);
    
    % Add front and back of the panels
    %---------------------------------
    dRHS.surfData.rFace         = [dRHS.surfData.rFace rP  rP];
    dRHS.surfData.nFace         = [dRHS.surfData.nFace nP -nP];
    dRHS.surfData.sigma         = [dRHS.surfData.sigma d.solarPanel.sigmaCell d.solarPanel.sigmaBack];
    dRHS.surfData.area          = [dRHS.surfData.area area area];
    
    [vPl, fPl] = Box( dims(1), dims(2), dims(3) );
    p          = size(vPl,1);
    f          = [f;fPl + size(v,1)];
    vPl        = (b*vPl')';
    v          = [v;vPl + DupVect(rP',p)];
    rP         = rP + dR;
    
  end
    dRHS.power.solarCellArea    = [dRHS.power.solarCellArea d.solarPanel.nPanels*area];
    dRHS.power.solarCellNormal	= [dRHS.power.solarCellNormal nP];
end

end % AddSolarPanels

end % CubeSatModel

%--------------------------------------------------------------------------
% Default data structure
%--------------------------------------------------------------------------
function d = DefaultStruct

d.thicknessWall         = 4;  % mm
d.thicknessRail         = 8.5; % mm
d.densityWall           = 2700; % kg/m^2
d.massComponents        = 1;
d.cMComponents          = [0;0;0];
d.sigma                 = [zeros(2,6);1 1 1 1 1 1]; % 100% diffuse
d.cD                    = 2.7;
d.solarPanel.dim        = [];	% [side attached to cubesat, side perpendicular thickness]
d.solarPanel.nPanels    = 0; % Number of panels per wing
d.solarPanel.rPanel     = []; % Location of inner edge of panel
d.solarPanel.sPanel     = [];
d.solarPanel.cellNormal = [0 0 0 0;0 0 0 0;1 1 1 1]; % Cell normal
d.solarPanel.sigmaCell  = [];    % [absorbed; specular; diffuse]
d.solarPanel.sigmaBack  = [];
d.solarPanel.mass       = 0;

end

%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
