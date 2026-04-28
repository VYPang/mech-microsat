function h = Coordinates(m)

%% Creates a figure with x,y,z coordinates at the origin.
% The figure has a black background and white axes.
%--------------------------------------------------------------------------
%   Form:
%   h = Coordinates( m )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   m             (1)     Magnitude of each axis
%   
%
%   -------
%   Outputs
%   -------
%   h             (1)     Figure handle
%
%--------------------------------------------------------------------------

%------------------------------------------------------------------------
%   Copyright (c) 2003 Princeton Satellite Systems, Inc.
%   All rights reserved.
%-----------------------------------------------------------------------
%   Since version 7
%------------------------------------------------------------------------

if( nargin < 1 )
   m = 1;
end

h = NewFig('Coordinates');

plot3([0 m],[0 0],[0 0],'b-','linewidth',2), hold on
plot3([0 0],[0 m],[0 0],'g-','linewidth',2)
plot3([0 0],[0 0],[0 m],'r-','linewidth',2)

plot3(m,0,0,'b.','markersize',20)
plot3(0,m,0,'g.','markersize',20)
plot3(0,0,m,'r.','markersize',20)

set(h,'color','black');
set(gca,'color','black')
set(gca,'ycolor','white','xcolor','white','zcolor','white')
xlabel('x','fontsize',16,'color','blue')
ylabel('y','fontsize',16,'color','green')
zlabel('z','fontsize',16,'color','red','rotation',0)
axis equal
axis([-m m -m m -m m])
grid on
rotate3d on

Watermark('Princeton Satellite Systems',h,[],[0 0 0])

%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
