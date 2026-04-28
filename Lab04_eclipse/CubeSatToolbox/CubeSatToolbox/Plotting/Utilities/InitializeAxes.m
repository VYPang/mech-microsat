function d = InitializeAxes( handle, scData, tgtData, time, keepView, point, cameraTarget, axisType )

%% Initialize the axes for an animation with AnimationGUI.
%--------------------------------------------------------------------------
%   Form:
%   InitializeAxes( handle, scData, tgtData, time, keepView, point, cameraTarget, axisType  )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   handle                 Handle to the axes
%   scData                 Data structure with position & time for each spacecraft
%   tgtData                Data structure with position & time for each target
%   time                   Time data
%   keepView               Flag indicating whether to keep the current view or not
%   point*
%   cameraTarget*
%   axisType               Specify the type of axes to use.
%                             'default'   x, y, z
%                             'Hills'     x-Radial, y-Along-track, z-Cross-track 
%                             'LVLH'      x-Along-track, y-Cross-track, z-Radial
%                             'PLANET'    The planet will be drawn in the background
%
%   -------
%   Outputs
%   -------
%   d                      Data structure for AnimationGUI.
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

axes(handle);
cla;
nSC = length(scData);
ns  = length(time);

% Default axis type
%------------------
if( nargin<8 )
   axisType = 'default';
end

% Camera target default
%----------------------
if( nargin < 7 )
   cameraTarget = 1;
end
if( nargin < 6 )
   point = 0;
end

% Keep view?
%-----------
if( nargin < 5 )
   keepView = 0;
end

% Set target flag
%----------------
if( nargin < 3 )
   tgtData = [];
end
if( isempty( tgtData ) )
   tgt = 0;
else
   tgt = 1;
end

% Default tail length
%--------------------
tailLength = 30;

% Coordinate labels (may want to make these user configurable)
%-------------------------------------------------------------
planets = {'Mercury','Venus','Earth','EarthMR','EarthHR','Mars','Jupiter','Saturn','Uranus','Neptune','Pluto'};
axisLimits = [];
switch axisType
   case 'default'
      title('3D Trajectory Animation','fontsize',14,'fontname','Arial')
      xlabel('x',            'fontsize',14,'fontname','Arial')
      ylabel('y',            'fontsize',14,'fontname','Arial')
      zlabel('z',            'fontsize',14,'fontname','Arial')
      
   case 'Hills'
      title('Trajectory in Local Reference Frame','fontsize',14,'fontname','Arial')
      xlabel('x_H - radial (km)',                 'fontsize',14,'fontname','Arial')
      ylabel('y_H - along-track (km)',            'fontsize',14,'fontname','Arial')
      zlabel('z_H - cross-track (km)',            'fontsize',14,'fontname','Arial')
      
   case 'LVLH'
      title('Trajectory in Local Reference Frame','fontsize',14,'fontname','Arial')
      xlabel('x_L - radial (km)',                 'fontsize',14,'fontname','Arial')
      ylabel('y_L - along-track (km)',            'fontsize',14,'fontname','Arial')
      zlabel('z_L - cross-track (km)',            'fontsize',14,'fontname','Arial')
      
   case planets
      
      Map(axisType,'3D',1)
      axisLimits = axis;
      
   otherwise
      error('Unrecognized axis type: "%s"',axisType)
      
end

% Graphics objects:  head, tail, target
%--------------------------------------
for i=1:nSC
  % SJT erasemode no longer supported in R2014b
   d.head(i) = line('color', scData(i).c(:,1), 'LineStyle','none', 'Marker','.', 'MarkerSize',30); % , 'erase','xor'
   d.tail(i) = line('color', scData(i).c(:,1), 'LineStyle','-',    'Linewidth',2,  'xdata',[],'ydata',[],'zdata',[]); % 'erase','xor',  
   d.cone(i) = patch('facecolor','y','edgecolor','none','vertices',[],'faces',[],'facealpha',.5); %,'EraseMode','normal'
end

% default cone data
%------------------
for i=1:nSC
   if( ~isfield(scData(i),'axis') || isempty(scData(i).axis) )
      scData(i).axis = zeros(3,ns);
   end
end

if( ~isempty(scData) )
   
   xx = zeros(nSC,ns);
   yy = xx;
   zz = xx;
   for i=1:nSC
      xx(i,:) = scData(i).r(1,:)+scData(i).axis(1,:);
      yy(i,:) = scData(i).r(2,:)+scData(i).axis(2,:);
      zz(i,:) = scData(i).r(3,:)+scData(i).axis(3,:);
   end
   
   % Find the axis limits from the min and max trajectory points, 
   % and extend by 10% in each direction
   %-------------------------------------------------------------
   if( ~keepView )   
      
      xMin = min(min(xx));
      xMax = max(max(xx));
      yMin = min(min(yy));
      yMax = max(max(yy));
      zMin = min(min(zz));
      zMax = max(max(zz));
      
      if ~isempty(axisLimits)
        % compare trajectory limits against planet limits
        xMin = min(xMin,axisLimits(1));
        xMax = max(xMax,axisLimits(2));
        yMin = min(yMin,axisLimits(3));
        yMax = max(yMax,axisLimits(4));
        zMin = min(zMin,axisLimits(5));
        zMax = max(zMax,axisLimits(6));
      end
      if( abs(xMin-xMax) <= abs(yMin-yMax)/10 || abs(xMin-xMax) <= abs(zMin-zMax)/10 )
         xMin = xMin - 0.1*max(abs(yMin),abs(zMin));
         xMax = xMax + 0.1*max(abs(yMax),abs(zMax));
      end
      if( abs(yMin-yMax) <= abs(xMin-xMax)/10 || abs(yMin-yMax) <= abs(zMin-zMax)/10 )
         yMin = yMin - 0.1*max(abs(xMin),abs(zMin));
         yMax = yMax + 0.1*max(abs(zMax),abs(zMax));
      end
      if( abs(zMin-zMax) <= abs(xMin-xMax)/10 || abs(zMin-zMax) <= abs(yMin-yMax)/10 )
         zMin = zMin - 0.1*max(abs(xMin),abs(yMin));
         zMax = zMax + 0.1*max(abs(xMax),abs(yMax));
      end
   
      if( xMin==xMax ), xMin=xMin-.5; xMax=xMax+.5; end
      if( yMin==yMax ), yMin=yMin-.5; yMax=yMax+.5; end
      if( zMin==zMax ), zMin=zMin-.5; zMax=zMax+.5; end
      axisLimits = [xMin xMax yMin yMax zMin zMax];
      axisLimits(1:2:5) = axisLimits(1:2:5) - 0.10 * abs(axisLimits(1:2:5));
      axisLimits(2:2:6) = axisLimits(2:2:6) + 0.10 * abs(axisLimits(2:2:6));
      
      axis(axisLimits)
   end

   % Tail length
   %------------
   d.lt = tailLength;
   
   % Camera target
   %--------------
   if( point )
      set(gca,'cameraTarget',scData(1).r(:,cameraTarget)');
   else
      set(gca,'cameraTargetMode','auto');
   end
   d.pointAt = cameraTarget;
   
   % Set the positions
   %------------------   
   for i=1:nSC
      set( d.head(i), 'xdata',scData(i).r(1,1), 'ydata',scData(i).r(2,1), 'zdata',scData(i).r(3,1), 'color',scData(i).c(:,1) );
      set( d.tail(i), 'xdata',scData(i).r(1,1), 'ydata',scData(i).r(2,1), 'zdata',scData(i).r(3,1), 'color',scData(i).c(:,1) );
   end

   % If target included...
   %----------------------
   if( tgt )
      for i=1:nSC
        % SJT erasemode normal not supported in R2014b
         d.headTgt(i) = line('color', tgtData(i).c(:,1), 'LineStyle', 'none', 'Marker','+', 'MarkerSize',20); % , 'EraseMode','normal'
         set(d.headTgt(i), 'xdata',tgtData(i).r(1,1), 'ydata',tgtData(i).r(2,1), 'zdata',tgtData(i).r(3,1) );
      end
   end

   
   
else
   d.lt = tailLength;
   d.posAnim    = zeros(3*nSC,d.lt);
   d.posAnimTgt = zeros(3*nSC,d.lt);
end

if( ~keepView )
   axis vis3d
   %cameratoolbar('setmode','orbit')
   grid on;
   view(-65,15)
end
cameratoolbar('setmode','orbit')

d.nSC = nSC;
d.ns  = ns;

set(gca,'fontsize',12,'fontname','Arial');

drawnow;


%--------------------------------------
% $Date: 2020-07-13 15:06:12 -0400 (Mon, 13 Jul 2020) $
% $Revision: 53040 $
