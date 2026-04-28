function [a,n,r] = TubeSatFaces( l, ~ )

%% Returns the faces along each axis of a cylindrical TubeSat. 
% The z axis is always the long axis.
%--------------------------------------------------------------------------
%   Form:
%   [a,n,r] = TubeSatFaces( l, rear )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   l        (1,1)   Either (1,2,3,4) for single, double, triple or quad
%   rear     (1,1)   Flag to include the rear faces
%
%   -------
%   Outputs
%   -------
%   a    (1,9) or (1,18)   Areas [aXY ... aZ]
%   n    (3,9) or (3,18)   Outward normals
%   r    (3,9) or (3,18)   Location from geometric center of spacecraft
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2013, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 11.
%   2016.1: Update to use DrawCubeSat for visualization.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    [a,n,r] = TubeSatFaces( 1 );
    disp(a);
    disp(n);
    disp(r);
    if nargout == 0
      clear a
    end
    TubeSatFaces( 2, true )
    return;
end

if isnumeric(l)
  if length(l)~=1
    error('Please provide a single factor.')
  end
else
  error('Input must be a scalar factor');
end

L = 0.127*l;   % Standard length
OD = 0.0894*l; % Outer diameter
R = OD/2;
 
% 16 sides
% offset the x/y so it lines up with Frustrum
dTheta = 2*pi/16;
S = OD*sin(dTheta/2);
theta = (0:7)*dTheta + dTheta/2;
h = R*cos(dTheta/2);
x = h*sin(theta);
y = h*cos(theta);
a(1,1:8) = L*S;
a(1,9) = (S*h)/2*16; % 16 triangles
r      = [[x;y;zeros(1,8)] [0; 0; L/2]];
n      = Unit(r);

if nargin > 1
  % add rear faces
  a = [a a];
  n = [n -n];
  r = [r -r];
end

if( nargout < 1 )
  fprintf(1,'Face areas for a "%d" TubeSat are [%5.4f %5.4f] m^2\n',l,[a(1) a(9)]);
  [v, f] = TubeSatModel(l);
  h = DrawCubeSat(v,f,struct('nFace',n,'rFace',r));
  set(h,'name','TubeSat Model');
  TitleS('TubeSatFaces Output')
  clear a
end

%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
