function [v, f, d] = StarCameraModel( type, uBoresight )

%% Get CAD vertices and faces for various star cameras.
% This also outputs mass and power data for the models.
%
% Type StarCameraModel for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f, d] = StarCameraModel( type, uBoresight )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type              Type, 'astro 5' (default), 'ct633', 'ons'
%   uBoresight        Unit vector for the boresight
%
%   -------
%   Outputs
%   -------
%   v                 Vertices
%   f                 Faces
%   d                 Data
%                     .mass
%                     .power
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  type = [];
end

if( nargin < 2 )
  uBoresight = [0;0;1];
end

if( isempty( type ) )
  type = 'astro 5';
end

d.power = GenericProperties( 'power' );

switch lower(type)
  case 'astro 5'
    zB1                       = 0.04;
    zB2                       = 0.06;
    [vX1, f1]                 = Frustrum( 0.055, 0.030, .230-zB1-zB2, 8, 0, 0 );
    [vX2, f2]                 = Box(  0.076,  0.076, zB1 );
    [vX3, f3]                 = Box(  0.076,  0.156, zB2 );
    vX1(:,2)                  = vX1(:,2) + 0.030;
    vX1(:,3)                  = vX1(:,3) + zB1+zB2;
    vX2(:,2)                  = vX2(:,2) + 0.030;
    vX2(:,3)                  = vX2(:,3) + zB2+zB1/2;
    vX3(:,3)                  = vX3(:,3) + zB2/2;
    vX                        = [vX1;vX2;vX3];
    f                         = [f1;size(vX1,1)+f2;size(vX1,1)+size(vX2,1)+f3];
    d.mass.mass               = 1.5;
    d.mass.inertia            = Inertias( d.mass.mass, [0.076 0.156 0.190], 'box', 1 );
    d.mass.cM                 = [0;0;0.072];
    d.power.powerOn           = 5;
    d.power.powerStandby      = 5;
    
	case 'ons'
    [vX, f]                   = Frustrum( 0.0125, 0.0125, 0.030, 8, 0, 0 );
    d.mass.mass               = 0.1;
    d.mass.inertia            = Inertias( d.mass.mass, [0.0125 0.03], 'cylinder', 1 );
    d.mass.cM                 = [0;0;0.072];
    d.power.powerOn           = 1;
    d.power.powerStandby      = 0.1;
	
  case 'ct633'
    lengthBase                = 5.6*0.0254;
    radiusBase                = 5.3*0.0254*0.5;
    radiusTrans               = (6/9)*radiusBase;
    lengthTrans               = 0.2*lengthBase;
    radiusShadeTop            = (13/9)*radiusBase;
    lengthShade               = 1.2*lengthBase;
    [vX1, f1]                 = Frustrum( radiusBase,     radiusBase,  lengthBase,  8, 0, 0 );
    [vX2, f2]                 = Frustrum( radiusTrans,    radiusTrans, lengthTrans, 8, 1, 1 );
    [vX3, f3]                 = Frustrum( radiusShadeTop, radiusTrans, lengthShade, 8, 0, 0 );
    vX2(:,3)                  = vX2(:,3)  + lengthBase;
    vX3(:,3)                  = vX3(:,3)  + lengthTrans + lengthBase;
    length                    = lengthShade + lengthTrans + lengthBase;
    vX                        = [vX1;vX2;vX3];
    f                         = [f1;size(vX1,1)+f2;size(vX1,1)+size(vX2,1)+f3];
    d.mass.mass               = 2.837;
    d.mass.inertia            = Inertias( d.mass.mass, [radiusBase length], 'cylinder', 1 );
    d.mass.cM                 = [0;0;lengthBase];
    d.power.powerOn           = 9;
    d.power.powerStandby      = 9;
	
  case 'info'
	  v = [sprintf('No further information is available.')];
	  return
end

% Transform the mass properties
%------------------------------
m              = Q2Mat( U2Q( [0;0;1], uBoresight  ) );
d.mass.inertia = m*d.mass.inertia*m';
d.mass.cM      = m*d.mass.cM;
v = (m*vX')';
f = fliplr(f);

% Draw the object
%----------------
if( nargout == 0 )
  DrawVertices(v,f,sprintf('Star Camera - %s',type))
  clear v
end


% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $
