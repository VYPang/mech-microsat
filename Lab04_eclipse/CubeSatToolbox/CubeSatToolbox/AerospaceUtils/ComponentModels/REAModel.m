function [v, f, d] = REAModel( type, uPlume )

%% Get CAD vertices and faces for General Dynamics REAs.
% These are reaction engine assemblies, i.e. thrusters. Units are meters.
% Available types:
%
%  mr-103c
%  mr-106e
%  mr-111c
%  lm
%
% Type REAModel for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f, d] = REAModel( type, uPlume )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type         (1,:) Type
%   uPlume       (3,1) Unit vector for plume
%
%   -------
%   Outputs
%   -------
%   v            (n,3) Vertices
%   f            (n,3) Faces
%   d            (1,1) Data
%                      .mass
%                      .power
%                      .propulsion
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  type = [];
end

if( nargin < 2 )
  uPlume = [0;0;1];
end

if( isempty( type ) )
  type = 'lm';
end

d.power      = GenericProperties( 'power' );
d.propulsion = GenericProperties( 'propulsion' );

switch lower(type)
  case 'mr-103c'
    [vXC, f1]                 = Frustrum( 0.015, 0.015, 0.089, 6, 0, 0 );
    [vXW, f2]                 = Frustrum( 0.012, 0.012, 0.022, 6, 0, 0 );
    [vXN, f3]                 = Frustrum( 0.007, 0.017, 0.035, 6, 0, 0 );
    [vXF, f4]                 = Frustrum( 0.030, 0.030, 0.005, 3, 0, 0 );
	  vXW(:,3)                  = vXN(:,3) + 0.089;
	  vXN(:,3)                  = vXN(:,3) + 0.111;
 	  vXF(:,3)                  = vXF(:,3) + 0.085;
	  v                         = [vXC;vXW;vXN;vXF];
	  f                         = [f1;size(vXC,1)+f2;size(vXC,1)+size(vXW,1)+f3];
	  f                         = [f1;size(vXC,1)+f2;size(vXC,1)+size(vXW,1)+f3;size(vXC,1)+size(vXW,1)+size(vXN,1)+f4];
	  d.mass.mass               = 0.33;
	  d.mass.inertia            = Inertias( d.mass.mass, [0.017 0.146], 'cylinder', 1 );
	  d.mass.cM                 = [0;0;0.072];
	  d.power.powerOn           = 8.25 + 1.54;
	  d.propulsion.thrust       = 1;
	  d.propulsion.iSP          = 209;
	  d.propulsion.feedPressure = 400*6895;
	
  case 'mr-111c'
    [vXC, f1]                 = Frustrum( 0.015, 0.015, 0.090, 6, 0, 0 );
    [vXW, f2]                 = Frustrum( 0.012, 0.012, 0.020, 6, 0, 0 );
    [vXN, f3]                 = Frustrum( 0.011, 0.019, 0.059, 6, 0, 0 );
    [vXF, f4]                 = Frustrum( 0.030, 0.030, 0.005, 3, 0, 0 );
	  vXW(:,3)                  = vXN(:,3) + 0.090;
	  vXN(:,3)                  = vXN(:,3) + 0.110;
 	  vXF(:,3)                  = vXF(:,3) + 0.090;
	  v                         = [vXC;vXW;vXN;vXF];
	  f                         = [f1;size(vXC,1)+f2;size(vXC,1)+size(vXW,1)+f3];
	  f                         = [f1;size(vXC,1)+f2;size(vXC,1)+size(vXW,1)+f3;size(vXC,1)+size(vXW,1)+size(vXN,1)+f4];
	  d.mass.mass               = 0.33;
	  d.mass.inertia            = Inertias( d.mass.mass, [0.017 0.146], 'cylinder', 1 );
	  d.mass.cM                 = [0;0;0.072];
	  d.power.powerOn           = 8.25 + 1.54;
	  d.propulsion.thrust       = 1;
	  d.propulsion.iSP          = 209;
	  d.propulsion.feedPressure = 400*6895;
	
  case 'mr-106e'
    [vXC, f1]                 = Frustrum( 0.017, 0.017, 0.142, 24, 0, 0 );
    [vXN, f2]                 = Frustrum( 0.017, 0.003, 0.040, 24, 0, 0 );
    [vXF, f3]                 = Frustrum( 0.030, 0.030, 0.005, 24, 0, 0 );
	  vXN(:,3)                  = vXN(:,3) + 0.142;
	  vXF(:,3)                  = vXF(:,3) + 0.080;
	  v                         = [vXC;vXN;vXF];
	  f                         = [f1;size(vXC,1)+f2;size(vXC,1)+size(vXN,1)+f3];
	  d.mass.mass               = 0.52;
	  d.mass.inertia            = Inertias( d.mass.mass, [0.017 0.182], 'cylinder', 1 );
	  d.mass.cM                 = [0;0;0.091];
	  d.power.powerOn           = 25.3 + 3.27;
	  d.propulsion.thrust       = 22;
	  d.propulsion.iSP          = 229;
	  d.propulsion.feedPressure = 350*6895;
	
  case 'lm'
    scale                     = (10 + 7/12)*12*0.0254/38;
    [vXC, f1]                 = Frustrum(     scale, scale, 2*scale, 6, 0, 0 );
    [vXN, f2]                 = Frustrum( 1.5*scale, scale, 2*scale, 6, 0, 0 );
	  vXN(:,3)                  = vXN(:,3) + 2*scale;
	  v                         = [vXC;vXN];
	  f                         = [f1;size(vXC,1)+f2];
	  d.mass.mass               = 0.52;
	  d.mass.inertia            = Inertias( d.mass.mass, [0.017 0.182], 'cylinder', 1 );
	  d.mass.cM                 = [0;0;0.091];
	  d.power.powerOn           = 25.3 + 3.27;
	  d.propulsion.thrust       = 22;
	  d.propulsion.iSP          = 229;
	  d.propulsion.feedPressure = 350*6895;
	
  otherwise
    [vXC, f1]                 = Frustrum( 0.015, 0.015, 0.089, 6, 0, 0 );
    [vXW, f2]                 = Frustrum( 0.012, 0.012, 0.022, 6, 0, 0 );
    [vXN, f3]                 = Frustrum( 0.007, 0.017, 0.035, 6, 0, 0 );
    [vXF, f4]                 = Frustrum( 0.030, 0.030, 0.005, 3, 0, 0 );
	  vXW(:,3)                  = vXN(:,3) + 0.089;
	  vXN(:,3)                  = vXN(:,3) + 0.111;
   	vXF(:,3)                  = vXF(:,3) + 0.085;
	  v                         = [vXC;vXW;vXN;vXF];
	  f                         = [f1;size(vXC,1)+f2;size(vXC,1)+size(vXW,1)+f3];
	  f                         = [f1;size(vXC,1)+f2;size(vXC,1)+size(vXW,1)+f3;size(vXC,1)+size(vXW,1)+size(vXN,1)+f4];
	  d.mass.mass               = 0.33;
	  d.mass.inertia            = Inertias( d.mass.mass, [0.017 0.146], 'cylinder', 1 );
	  d.mass.cM                 = [0;0;0.072];
	  d.power.powerOn           = 8.25 + 1.54;
	  d.propulsion.thrust       = 1;
	  d.propulsion.iSP          = 209;
	  d.propulsion.feedPressure = 400*6895;
    d.propulsion.riseTime     = 0.016;
    d.propulsion.fallTime     = 0.016;
    d.propulsion.type         = 'liquid';
    d.propulsion.systemID     = 1;
end

f = fliplr(f);

% Transform the mass properties
%------------------------------
m              = Q2Mat( U2Q( uPlume, [0;0;1] ) )';
d.mass.inertia = m*d.mass.inertia*m';
d.mass.cM      = m*d.mass.cM;
v = (m*v')';

% Draw the object
%----------------
if( nargout == 0 )
  DrawVertices(v,f,sprintf('REA - %s',type))
  clear v
end

% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $
