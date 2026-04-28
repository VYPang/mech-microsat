function PlotLunarOrbit( rECI, jD, uSun, thrust, magF )

%% Plot a 3D orbit around the moon.
%
% The terrain magnification factor increases the height of the terrain
% making it easier to see. 
%
% Type PlotLunarOrbit for a demo.
%--------------------------------------------------------------------------
%   Form:
%   PlotLunarOrbit( rECI, jD, uSun, magF )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   rECI    (3,:)  ECI frame orbit (km)
%   jD      (1,:)  Julian date (day)
%   uSun    (3,:)  Sun vector
%   thrust  (3,:)  Thrust Vectors
%   magF    (1,1)  Terrain magnification factor
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
%   Since 2016.1
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  mu            = Constant('mu moon');
  el            = [3000 0.2 0 0 0.3 0];
  [rECI, ~, t]  = RVFromKepler(el,[],mu);  
  jD            = Date2JD + t/86400;
  thrust        = zeros(3,length(t));
  thrust(:,40:50)  = ones(3,11);
  PlotLunarOrbit( rECI, jD, [1;1;0], thrust, 10 );
  return
end

if( nargin < 3 )
  magF = 1;
end


n = size(rECI,2);

rLF = zeros(3,n);
thrustLF = zeros(3,n);

kMToM = 1000;


for k = 1:n
  b             = MoonRot( jD(k) );
	rLF(:,k)      = b*rECI(:,k)*kMToM;
  thrustLF(:,k)	= b*thrust(:,k);
end

hF = NewFig('Lunar Orbit');
plot3(rLF(1,:),rLF(2,:),rLF(3,:),'r');
hold on
grid on
XLabelS('x (m)');
YLabelS('y (m)');
ZLabelS('z (m)');

% Add text
t  = (jD - jD(1))*86400;

n  = length(t);
j  = ceil(linspace(1,n,5));


[t, ~, tU] = TimeLabl(t);

for k = 1:length(j)
  jK  = j(k);
  s   = sprintf('t = %3.1f %s',t(jK),tU);
  text( rLF(1,jK), rLF(2,jK), rLF(3,jK), s );
end


% Add thrust vectors
mT = Mag(thrustLF);
j  = find(mT > 0);
length(j)
l  = 0.4*min(Mag(rLF));
dK = floor(length(j)/4);
for k = 1:dK:length(j)
  i = j(k);
  u = l*Unit(thrustLF(:,i));
  quiver3(rLF(1,i),rLF(2,i),rLF(3,i),u(1),u(2),u(3),0,'color',[0 1 0]);
end

[h.r, h.lambda, h.theta]	= RSHMoon; % Clementine model
h.rEq                     = 1738000; % m
h.name                    = 'Moon';
[v,f]                     = PlanetWithTerrain( h, magF );

s = sprintf('%s - Surface Exaggeration Factor: %4.2f',h.name,magF);
TitleS(s);
patch('vertices',v,'faces',f,'facecolor',[0.5 0.5 0.5],...
        'facelighting','gouraud','linestyle','none'); 
axis equal
ambient = 0.2; diffuse = 1; specular = 0.0;
material([ambient diffuse specular])
view(3)
rotate3d on
light('position',1e6*MoonRot(jD(1))*uSun);
Watermark('Spacecraft Control Toolbox',hF)

%--------------------------------------
% $Date: 2020-05-08 14:41:04 -0400 (Fri, 08 May 2020) $
% $Revision: 52176 $

