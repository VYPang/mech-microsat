function [v, f] = HallThrusterModel( s )

%% Get CAD vertices and faces for a Hall thruster.
%
% Type HallThrusterModel for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f] = HallThrusterModel( s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s           (1,2)	Scale [Diameter, length]
%
%   -------
%   Outputs
%   -------
%   v           (:,3)   Vertices
%   f           (:,3)   Faces
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2003 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    s = [1 1]; 
    HallThrusterModel( s );
    return;
end

% Inner poles
%------------
j = 0;
v = [];
f = [];

[vIP, fIP] = Frustrum( .1, .1, 1, 20, 0, 0 );
for k = 1:1
  vT(:,1) = vIP(:,1);
  vT(:,2) = vIP(:,2);
  vT(:,3) = vIP(:,3);
  v       = [v;vT];
  f       = [f;fIP + j];
  j       = j + size(vIP,1);
end

[vIP, fIP] = Frustrum( .2, .2, 1, 20, 1, 1 );
for k = 1:1
  vT(:,1) = vIP(:,1);
  vT(:,2) = vIP(:,2);
  vT(:,3) = vIP(:,3);
  v       = [v;vT];
  f       = [f;fIP + j];
  j       = j + size(vIP,1);
end

% Back wall
%----------
[vB, fB]   = Frustrum( 0.5, 0.5, .1 );
vB(:,3)    = vB(:,3) - 0.05;

vT         = vB;
vT(:,3)    = vT(:,3) - 0.05;
v          = [v;vT];
f          = [f;fB + j];
j          = j + size(vT,1);

vT         = vB;
vT(:,3)    = vT(:,3) + .95;
v          = [v;vT];
f          = [f;fB + j];
j          = j + size(vT,1);

% Cathode
%--------
[vC, fC]   = Frustrum( .1, .1, .25, 20, 0, 0 );
vT         = vC;
vT(:,2)    = vT(:,2) + 0.4;
vT(:,3)    = vT(:,3) + 0.75;
v          = [v;vT];
f          = [f;fC + j];
j          = j + size(vT,1);

[vE, fE] = Frustrum( .05, .05, .25, 20, 0, 0 );
[vS, fS] = Frustrum( .02, .02,    1, 20, 0, 0 );
r = [-1 -1 1  1;...
     -1  1 1 -1]*.2;
for k = 1:4
  vT(:,1) = vE(:,1) + r(1,k);
  vT(:,2) = vE(:,2) + r(2,k);
  vT(:,3) = vE(:,3) + 0.25;
  v       = [v;vT];
  f       = [f;fE + j];
  j       = j + size(vIP,1);
  vT(:,1) = vS(:,1) + r(1,k);
  vT(:,2) = vS(:,2) + r(2,k);
  vT(:,3) = vS(:,3);
  v       = [v;vT];
  f       = [f;fS + j];
  j       = j + size(vIP,1);
end

v(:,3) = v(:,3)*s(2);
v(:,1:2) = v(:,1:2)*s(1);

if( nargout == 0 )
  DrawVertices(v,f,'Hall Thruster Array')
  clear v
end

% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $

