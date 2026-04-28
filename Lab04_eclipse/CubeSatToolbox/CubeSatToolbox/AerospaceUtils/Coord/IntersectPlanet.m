function h = IntersectPlanet( r1, r2, a )

%% Altitude of the nearest point to a sphere.
%
% Type IntersectPlanet for a demo.
%--------------------------------------------------------------------------
%   Form:
%   h = IntersectPlanet( r1, r2, a )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r1             (3,n)  Position vector 1
%   r2             (3,m)  Position vector 2
%   a              (1,1)  Radius of the planet
%
%   -------
%   Outputs
%   -------
%   h              (n,m)  Minimum altitude of vector
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
	a  = 6378;
	r1 = [7000;-1000;0];
	r2 = [7000; 1000;0];
	IntersectPlanet( r1, r2, a )
	return;
end

if( nargin < 3 )
	a = 6378.165;
end

nR1 = size(r1,2);
nR2 = size(r2,2);

h   = zeros(nR1,nR2);

for j = 1:nR1
	r1J  = r1(:,j);
	r1Sq = r1J'*r1J;
	for k = 1:nR2
    v        = r2(:,k) - r1J;
    r1V      = r1J'*v;
    vSq      = v'*v;
    t        = -r1V/vSq;
    h(j,k)   = sqrt( r1Sq + (2*r1V + t*vSq)*t ) - a;
	end
end
	
if( nargout == 0 && ( (nR2 == nR1) || (nR2 == 1) || (nR1 == 1) ) )
  NewFig('Intersect')
	if( nR2 == 1 )
		o = ones(1,nR1);
	  plot3( [r1(1,:);r2(1)*o], [r1(2,:);r2(2)*o], [r1(3,:),r2(3)*o] );
	elseif( nR1 == 1 )
		o = ones(1,nR2);
	  plot3( [r1(1)*o;r2(1,:)], [r1(2)*o;r2(2,:)], [r1(3)*o,r2(3,:)] );
	else
	  plot3( [r1(1,:);r2(1,:)], [r1(2,:);r2(2,:)], [r1(3,:),r2(3,:)] );
	end
	grid;
	view(3);
	XLabelS('x (km)')
	YLabelS('y (km)')
	ZLabelS('z (km)')
	rotate3d on
	hold on
  [x,y,z] = sphere(48);
  x       = x*a;
  y       = y*a;
  z       = z*a;
	surface(x,y,z);
	axis image
	title( sprintf('Minimum altitude = %12.4f',h));
end
	

%--------------------------------------
% $Date: 2017-04-11 12:25:04 -0400 (Tue, 11 Apr 2017) $
% $Revision: 44323 $
