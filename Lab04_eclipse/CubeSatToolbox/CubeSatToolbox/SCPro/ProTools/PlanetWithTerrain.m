function [v, f] = PlanetWithTerrain( h, scale )

%% Generate vertices and faces for a planet with terrain.
%
% Adds a height map to a sphere to produce a 3D terrain map. 
% theta needs to include 0 and pi. lambda should include 0 but not 2*pi.
%
% scale exaggerates the surface variations from a sphere to make them
% easier to see. 
%
% Rendering the planet is done with patch.
%
% patch('vertices',v,'faces',f,'facecolor',[0.5 0.5 0.5],...
%           'facelighting','gouraud','linestyle','none');
% axis equal
% ambient = 0.2; diffuse = 1; specular = 0.0;
% material([ambient diffuse specular])
%
% Type PlanetWithTerrain for a model of the moon using Clementine data.
%--------------------------------------------------------------------------
%   Form:
%   [v, f] = PlanetWithTerrain( h, f )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   h   (.)     Height map data structure
%               .r       (theta,lambda)   Distance from center
%               .lambda	 (1,:)            Equatorial angle
%               .theta   (1,:)            Angle from pole
%               .rEq     (1,1)            Equatorial radius (m)
%               .name    (1,:)            Planet name
%   scale (1,1) Exaggerate the terrain by this factor
%
%   -------
%   Outputs
%   -------
%   v   (:,3) Vertices
%   f   (:,3) Faces
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2015 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
% Since 2016.1
%--------------------------------------------------------------------------

% Demo
if( nargin == 0 )
  [h.r, h.lambda, h.theta]	= RSHMoon; % Clementine model
  h.rEq                     = 1738000; % m
  h.name                    = 'Moon';
  PlanetWithTerrain( h, 10 );
  return
end

if( nargin < 2 )
  scale = 1;
end

% Sort by theta
[~,k]	= sort(h.theta);
h.r   = h.r(k,:);

n   = length(h.theta);
m   = length(h.lambda);

% Scale the terrain to make it visible
r   = scale*(h.r - h.rEq) + h.rEq;

% Vertices
v       = zeros(n*m,3);
i       = 1;
cL      = cos(h.lambda);
sL      = sin(h.lambda);
v(1,:)  = AngToV( r(1,1), h.theta(1), cL(1), sL(1) );
for j = 2:n-1
  for k = 1:m
    i       = i + 1;
    v(i,:)  = AngToV( r(j,k), h.theta(j), cL(k), sL(k) );
  end
end
v(i+1,:) = AngToV( r(n,1), h.theta(n), cL(1), sL(1) );

% Faces

% Top
i = 0;
for k = 1:m-1
  i      = i + 1;
  f(i,:) = [1 k+1 k+2];
end
i = i + 1;
f(i,:) = [1 m+1 2];

% Middle
for j = 1:n-2
  k0 = (j-1)*m + 1;
  for k = 1:m-1
    i       = i + 1;
    k1      = k0 + k;
    f(i,:)  = [k1 k1+m k1+m+1];
    i       = i + 1;
    f(i,:)	= [k1 k1+m+1 k1+1];
  end
  
  % Wrap
	k1      = k0+m;
  i       = i + 1;
  f(i,:)  = [k1 k1+m k0+m+1];
  i       = i + 1;
  f(i,:)  = [k1 k0+m+1 k0+1];
end

% Draw the planet
if( nargout == 0 )
  hFig = NewFig(h.name);
  s = sprintf('%s - Surface Exaggeration Factor: %4.2f',h.name,scale);
  TitleS(s);
  patch('vertices',v,'faces',f,'facecolor',[0.5 0.5 0.5],...
        'facelighting','gouraud','linestyle','none'); 
  axis equal
  ambient = 0.2; diffuse = 1; specular = 0.0;
  material([ambient diffuse specular])
  XLabelS('x (m)')
  YLabelS('y (m)')
  ZLabelS('z (m)')
  view(3)
  grid on
  rotate3d on
  light('position',1e6*[1 1 0]);
	Watermark('Princeton Satellite Systems',hFig);
end

%--------------------------------------------------------------------------
% Find the position vectors
%--------------------------------------------------------------------------
function v = AngToV( r, theta, cL, sL )

v = r*[sin(theta)*cL, sin(theta)*sL cos(theta)];


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2016-07-09 18:51:35 -0400 (Sat, 09 Jul 2016) $
% $Revision: 42793 $

