function h = AnimQ( q, speed, h, propName, propValue )

%% Animate the evolution of a quaternion over time.
%
% Type AnimQ for a demo.
%--------------------------------------------------------------------------
%   Form:
%   h = AnimQ( q, speed, h, propName, propValue )	
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   q              (4,:)  Time history of quaternion
%   speed           (1)   Speed factor (0 slow - 100 fast)
%   h               (1)   Handle of the figure to animate in (optional)
%   propName        {:}   Array of property names
%                          ie, {'linewidth','linestyle'}
%   propValue       {:}   Array of property values
%                          ie, {2,'--'}
%
%   -------
%   Outputs
%   -------
%   h              (1,1)  Figure handle
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 2002,2008, 2017 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since verion 5.5
%   2017.1 Add Animate menu to allow replay of the animation. 
%   Add watermark.
%--------------------------------------------------------------------------

global PSS_NO_INTERACTIVE_DEMOS

if( nargin < 1 )
   t = linspace(0,8*pi,2e3);
   q = Unit([-.5*exp(-t/10).*cos(t);.5+.25*exp(-t/10).*sin(2*t);-.5+.1*exp(-t/10).*cos(t/3+1);0-.5*exp(-t/10).*sin(t/2+2)]);
   AnimQ( q );
   return;
end

n = size(q,2);

if( nargin < 2 || isempty(speed) )
   speed = 100;
end;

if( nargin < 3 || isempty(h) )
   h = figure('render','opengl','tag','Plot2D','name','AnimQ');
   setupFig = 1;
else
   figure(h);
   setupFig = 0;
end

if( nargin < 5 )
   propName  = {};
   propValue = {};
end

if( length(propName) ~= length(propValue) )
   errordlg('The property name and property value inputs must have the same length.');
end

xColor = 'blue';
yColor = 'green';
zColor = 'red';

% Convert quaternion to matrix
%-----------------------------
m = Q2Mat( q(:,1) );

% Initialize the x, y, z components of the "body frame"
%------------------------------------------------------
% SJT erasemode (xor, background) no longer supported in R2014b
x = line( ...
   'color', xColor, ...
   'LineStyle', '-', ...
   'LineWidth',2, ...
   'xdata',[0 m(1,1)],'ydata',[0 m(1,2)],'zdata',[0 m(1,3)]);

y = line( ...
   'color', yColor, ...
   'LineStyle', '-', ...
   'LineWidth',2, ...
   'xdata',[0 m(2,1)],'ydata',[0 m(2,2)],'zdata',[0 m(2,3)]);

z = line( ...
   'color', zColor, ...
   'LineStyle', '-', ...
   'LineWidth',2, ...
   'xdata',[0 m(3,1)],'ydata',[0 m(3,2)],'zdata',[0 m(3,3)]);

% Add user-specified properities to x, y, z
%------------------------------------------
for i=1:length(propName)
   set(x,propName{i},propValue{i});
   set(y,propName{i},propValue{i});
   set(z,propName{i},propValue{i});
end

% Set up the figure
%------------------
if( setupFig )
   set(h,'color','black');
   set(gca,'color','black')
   set(gca,'ycolor','white','xcolor','white','zcolor','white')
   xlabel('x','fontsize',14,'color','white'), 
   ylabel('y','fontsize',14,'color','white'), 
   zlabel('z','fontsize',14,'color','white','rotation',eps)
   axis equal
   axis([-1 1 -1 1 -1 1]*1.5);
   view(-60,15)
   grid on
   hold on
end
rotate3d on

Watermark('Princeton Satellite Systems',h,[],[0 0 0]);

for i=1:n
  us{i} = Unit( Q2Mat(q(:,i)) );
end
s.speed = speed;
s.us = us;
s.handle = [x y z];
set(h,'userData',s);
ma=uimenu('parent',h,'label','Animate');
mp=uimenu('parent',ma,'label','Play','Accelerator','A','callback',@Callback);

if( n > 1 )
  waitTime = 60;
  if (PSS_NO_INTERACTIVE_DEMOS)
    waitTime = 1;
  end
  hM = msgbox('Click To Begin Animation','Animation','modal');
  uiwait(hM,waitTime)
  if ishandle(hM)
    close(hM);
  end
end


for i=2:n
   
   % Slow down the animation
   if( speed < 100 )
      pause(1/speed)
   end

   u = us{i};
   set(x,'xdata',[0 u(1,1)],'ydata',[0 u(1,2)],'zdata',[0 u(1,3)]);
   set(y,'xdata',[0 u(2,1)],'ydata',[0 u(2,2)],'zdata',[0 u(2,3)]);
   set(z,'xdata',[0 u(3,1)],'ydata',[0 u(3,2)],'zdata',[0 u(3,3)]);
   
   drawnow;

end

function Callback(src,event)

d = get(gcf,'userdata');
for i = 1:length(d.us)
  if( d.speed < 100 )
    pause(1/d.speed)
  end
   u = d.us{i};
   set(d.handle(1),'xdata',[0 u(1,1)],'ydata',[0 u(1,2)],'zdata',[0 u(1,3)]);
   set(d.handle(2),'xdata',[0 u(2,1)],'ydata',[0 u(2,2)],'zdata',[0 u(2,3)]);
   set(d.handle(3),'xdata',[0 u(3,1)],'ydata',[0 u(3,2)],'zdata',[0 u(3,3)]);
  drawnow;
end

%--------------------------------------
% $Date: 2019-12-27 11:53:18 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50722 $
