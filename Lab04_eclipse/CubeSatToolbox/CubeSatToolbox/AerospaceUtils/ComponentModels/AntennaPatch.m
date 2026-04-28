function [v, f] = AntennaPatch( x, y, d, theta, u, t, n )

%% Get vertices and faces for an antenna CAD component.
% The vertices are defined as x width, y width, d depth,
% u boresight and t is the unit vector along x.
% Patch means graphical object.
%
% Type AntennaPatch for a demo.
%
% Since version 2.
%--------------------------------------------------------------------------
%   Form:
%   [v, f] = AntennaPatch( x, y, d, theta, u, t, n )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x           (1,1) X width
%   y           (1,1) Y width
%   d           (1,1) Depth
%   theta       (1,1) Angle that represents the part of a sphere (rad)
%   u           (3,1) Boresight unit vector
%   t           (3,1) X axis unit vector
%   n           (1,1) Number of divisions
%
%   -------
%   Outputs
%   -------
%   v           (:,3) Vertices
%   f           (:,3) Faces
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Input processing
%-----------------
if( nargin < 1 )
  x = [];
end

if( nargin < 2 )
  y = [];
end

if( nargin < 3 )
  d = [];
end

if( nargin < 4 )
  theta = [];
end

if( nargin < 5 )
  u = [];
end

if( nargin < 6 )
  t = [];
end

if( nargin < 7 )
  n = [];
end

% Defaults
%---------
if( isempty( x ) )
  x = 1;
end

if( isempty( y ) )
  y = 1;
end

if( isempty( d ) )
  d = 1;
end

if( isempty( theta ) )
  theta = pi/2;
end

if( isempty( u ) )
  u = [0;0;1];
end

if( isempty( t ) )
  t = [1;0;0];
end

if( isempty( n ) )
  n = 20;
end

% Find the transformation matrix
%-------------------------------
m  = [t Unit(Cross( t, -u )) -u];

% Find the dimensions
%--------------------
a  = 0.5*x/sin(theta);
b  = 0.5*y/sin(theta);
c  = d/(1 - cos(theta));

% Create the data structure
%--------------------------
d   = struct;
d.a = a;
d.b = b;
d.c = c;
d.n = n;
d.thetaUpper = theta;

[v, f] = GeomPatch( d );
v(:,3) = v(:,3) - c;

v      = (m*v')';

% Add back faces
%---------------
f      = [f;fliplr(f)];

% Draw the antenna
%-----------------
if( nargout == 0 )
  DrawVertices( v, f, 'Antenna')
  clear v;
end


% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $
