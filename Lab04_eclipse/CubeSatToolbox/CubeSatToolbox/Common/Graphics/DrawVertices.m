function DrawVertices( v, f, name, blend )

%% Draw and object from vertices in a figure window using patch.
% The object will be a uniform color. Type DrawVertices for a demo.
%--------------------------------------------------------------------------
%   Form:
%   DrawVertices( v, f, name, blend )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   v       (:,3) Vertices
%   f       (:,3) Faces
%   name    (1,:) Figure name
%   blend   (1,1) If true blend the vertex lines
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2017.1
%   2018.1 Added blended mode
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  [v,f] = Box(2,3,4);
  DrawVertices( v, f, 'box', true )
  return
end

if( nargin < 3 )
  name = 'Vertices';
end

if( nargin < 4 )
  blend = false;
end

h = NewFig(name);
c = [0.4 0.4 0.4];
if( blend )
  shading flat
  lighting gouraud
  patch('vertices',v,'faces',f,'facecolor',c,'edgecolor',c,'ambient',1,'edgealpha',0);
else
  patch('vertices',v,'faces',f,'facecolor',c,'ambient',0.7);
end
axis image
XLabelS('x')
YLabelS('y')
ZLabelS('z')
view(3)
grid on
rotate3d on
s = 10*max(Mag(v'));
light('position',s*[1 1 1])

Watermark('Spacecraft Control Toolbox',h)


%--------------------------------------
% $Date: 2020-04-21 09:32:32 -0400 (Tue, 21 Apr 2020) $
% $Revision: 51888 $
