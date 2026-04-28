function [v, f, d] = CameraModel( type, uBoresight )

%% Get CAD vertices and faces for a star camera model.
%
% Type CameraModel for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f, d] = CameraModel( type, uBoresight )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type          (3,:) Type
%   uBoresight    (3,1) Unit vector for the boresight
%
%   -------
%   Outputs
%   -------
%   v             (:,3) Vertices
%   f             (:,3) Faces
%   d              (.)  Data
%                       .mass  (1,1) Mass
%                       .power (1,1) Power requirements
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001, 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  type = [];
end

if( nargin < 2 )
  uBoresight = [0;0;1];
end

if( isempty( type ) )
  type = 'generic';
end

switch lower(type)
  case 'generic'
    zB1                       = 0.04;
    [vX1, f1]                 = Frustrum( 0.030, 0.030, .120-zB1, 8, 0, 0 );
    [vX2, f2]                 = Box( 0.076, 0.076, zB1 );
    vX1(:,3)                  = vX1(:,3) + zB1;
    vX2(:,3)                  = vX2(:,3) + zB1/2;
    vX                        = [vX1;vX2];
    f                         = [f1;size(vX1,1)+f2];
    d.mass.mass               = 1.5;
    d.mass.inertia            = Inertias( d.mass.mass, [0.076 0.156 0.190], 'box', 1 );
    d.mass.cM                 = [0;0;0.072];
    d.power                   = struct( 'powerStandby', 1, 'powerOn', 5, 'electricalConversionEfficiency', 0, 'powerHeater', 0 );
	
  case 'info'
    v = sprintf('No further information is available.');
    return
    
  otherwise
    msgbox(sprintf('CameraModel: %s is not available',type));
    return
end

f = fliplr( f );

% Transform the mass properties
%------------------------------
m              = Q2Mat( U2Q( uBoresight, [0;0;1] ) )';
d.mass.inertia = m*d.mass.inertia*m';
d.mass.cM      = m*d.mass.cM;
vX = (m*vX')';

% Draw the object
%----------------
if( nargout == 0 )
  DrawVertices( vX, f, sprintf('Star Camera - %s',type) );
  DispWithTitle(d.mass, 'Camera Model Data')
else
  v = vX;
end

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $
