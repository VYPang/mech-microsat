function tag = CameraControls(varargin) 

%% This function creates a GUI for manipulating the camera view.
%
% Initialize by supplying an axis handle. If no input is provided it will
% point to the current axis (gca).
%
% This GUI does not provide direct control over the camera target.
% Set the camera target of axes "h" to vector "v" with this command:
%   set(h,'cameratarget',v)
% 
% Move in/out changes the distance from the camera to the target.
% Zoom in/out changes the view angle of the camera.
% Adjust azimuth and elevation to change the orientation of the camera
%   while keeping the distance constant.
%
% The azimuth and elevation angles are defined in a local xyz coordinate
% frame. 
%
%   x: along the direction of the camera target vector. 
%   y: cross product of z and x, completes right-handed system
%   z: cross product of x and the supplied forward vector
%
% Note that the "forward" vector is not an axis property, and so it must 
% be supplied directly to the CameraControls GUI.
%--------------------------------------------------------------------------
%   USAGE:
%
%     % Initialize and use current axes (gca)
%     tag = CameraControls;
%
%     % Initialize with specified axes
%     tag = CameraControls( axisHandle );    
%
%     % Set the forward vector
%     CameraControls( 'set forward vector', tag, forwardVector );
%
%     % Update the view
%           CameraControls( 'update', tag );
%
%     % Update the view with a new forward vector
%     CameraControls( 'update', tag, forwardVector );    
%--------------------------------------------------------------------------
% 
%   ------ 
%   Inputs 
%   ------ 
%   axisHandle      (1,1)   Handle to the axes for controlling the camera
% 
%   ------- 
%   Outputs 
%   ------- 
%   tag             (1,:)   Tag to the GUI.
%  
%--------------------------------------------------------------------------
% See also:  AnimationGUI
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 2009 Princeton Satellite Systems, Inc.
%   All rights reserved. 
%   Since version 8.
%--------------------------------------------------------------------------


if( nargin < 1 )
   tag = Initialize(gca);
   return
elseif( ishandle(varargin{1}) )
   tag = Initialize( varargin{1} );
   return
end

action = varargin{1};
tag    = varargin{2};
if( nargin>2 )
   input  = varargin{3};
end

h = GetH(tag);

switch action 
   
case 'set target' 
   set(h.axes,'cameratarget',input);
   
   case 'set up vector'
      set(h.axes,'cameraupvector',input)
   
   case 'set forward vector'
      h.forward = input;
      PutH(h);
      
case 'zoom in' 
   camzoom(h.axes,6/5);

case 'zoom out' 
   camzoom(h.axes,5/6);

case 'move in' 
   pos = get(h.axes,'cameraposition');
   tgt = get(h.axes,'cameratarget');
   set(h.axes,'camerapos',tgt + (pos-tgt)*.9)
   
case 'move out' 
   pos = get(h.axes,'cameraposition');
   tgt = get(h.axes,'cameratarget');
   set(h.axes,'camerapos',tgt + (pos-tgt)*1.111111111)

case 'azimuth' 
   az = get(h.azimuth,'value');
   el = get(h.elevation,'value');
   UpdateCamera( h.axes, az, el, h.forward );

case 'elevation' 
   az = get(h.azimuth,'value');
   el = get(h.elevation,'value');
   UpdateCamera( h.axes, az, el, h.forward );
   
   case 'get azimuth'
      tag = get(h.azimuth,'value');
      
   case 'get elevation'
      tag = get(h.elevation,'value');
      
   case 'get up vector'
      tag = get(h.axes,'cameraupvector');
      
   case 'get forward vector'
      tag = h.forward;
      
   case 'update'
      az = get(h.azimuth,'value');
      el = get(h.elevation,'value');
      if( nargin==3 )
         h.forward = input;
         PutH(h);
      end
      UpdateCamera( h.axes, az, el, h.forward );
      
   case 'show'
      set(h.fig,'visible','on');
   case 'hide'
      set(h.fig,'visible','off');
      
      
end

   
%--------------------------------------------------------------------------
%   Initialize the GUI 
%-------------------------------------------------------------------------- 
function tag = Initialize( handle ) 

tag = GetNewTag('CameraControls');

% location and size
x        = 50; 
y        = 300;
width    = 130;
height   = 120;

% Color Definitions
bColor = [0.7 .8 .8];
black  = [0 0 0];
white  = [1 1 1];

bgc    = 'backgroundcolor';
fgc    = 'foregroundcolor';

% figure
h.fig = figure( 'units', 'pixels', 'position', [x y width height], ...
      'NumberTitle','off', 'name','Camera', 'Color',bColor,'menubar','none',... 
   'tag',tag, 'handlevisibility','on', 'resize','off' ); % SJT doublebuffer no longer supported in R2014b

% axes to control
h.axes = handle;


vc  = {'parent',h.fig, 'units','pixels', 'fontunits','pixels', 'fontSize',10, ...
   'fontName','Helvetica', 'backgroundColor',bColor, 'horizontalAlignment','center' };

vl  = vc;   vl{14} = 'left';
vr  = vc;   vr{14} = 'right';

vlt  = [vl,  {'style','text', fgc,black} ];
vrt  = [vr,  {'style','text', fgc,black} ];
vct  = [vc,  {'style','text', fgc,black} ];
vctb = [vct, {'fontweight','bold', 'fontsize',10} ];
vcg  = [vc,  {'style','togglebutton'}];
vcb  = [vc,  {'style','pushbutton'} ];
vcs  = [vc,  {'style','slider'} ];

x = 20; 
y = height-30; 
w = 40; 
dw = 2;

x  = 20;
x1 = 65;
x2 = x1 + w/2 + dw;
dy = 25;

uicontrol( vlt{:}, 'string','Move:', 'position',[x y-3 45 25]);  
h.movein    = uicontrol( vcb{:}, 'position',[x1 y w/2 20], fgc,black, 'callback',CreateCallback( 'move in',tag ),    'string','+' ); 
h.moveout   = uicontrol( vcb{:}, 'position',[x2 y w/2 20], fgc,black, 'callback',CreateCallback( 'move out',tag ),   'string','-'); y = y - dy;

uicontrol( vlt{:}, 'string','Zoom:', 'position',[x y-3 45 25]);  
h.zoomin    = uicontrol( vcb{:}, 'position',[x1 y w/2 20], fgc,black, 'callback',CreateCallback( 'zoom in',tag ),    'string','+' ); 
h.zoomout   = uicontrol( vcb{:}, 'position',[x2 y w/2 20], fgc,black, 'callback',CreateCallback( 'zoom out',tag ),   'string','-'); y = y - dy;

h.azimuth   = uicontrol( vcs{:}, 'position',[x+17 y 65 20], fgc,black, 'callback',CreateCallback( 'azimuth',tag ), 'min',-pi,'max',pi,'sliderstep',[1 5]*pi/180);
uicontrol( vlt{:}, 'string','Azimuth:', 'position',[x y-3 50 25]);  y = y - dy;

h.elevation = uicontrol( vcs{:}, 'position',[x+17 y 65 20], fgc,black, 'callback',CreateCallback( 'elevation',tag ),  'min',-pi/2,'max',pi/2,'sliderstep',[1 5]*pi/180);
uicontrol( vlt{:}, 'string','Elevation:', 'position',[x y-3 50 25]);  y = y - dy;


% initial values 
h.pitch = 0;
h.roll = 0;
h.yaw = 0;
h.forward = [1;0;0]; 
   
% by default, set the up vector to be parallel with the target
%set(h.axes,'cameraupvector',Unit(get(h.axes,'cameratarget')))

PutH( h ); 


%--------------------------------------------------------------------------
%   Update View 
%--------------------------------------------------------------------------
function UpdateCamera( ax, azim, elev, forward )


pos = get(ax,'cameraposition')';
tgt = get(ax,'cameratarget')';

cameraDistance = Mag(pos-tgt);

cAz       = cos( azim   );
sAz       = sin( azim   );
cEl       = cos( elev );
sEl       = sin( elev );

x = Unit(forward);
z = -Unit(tgt);
y = Cross(z,x);
x = Cross(y,z);
matLVLH = [x';y';z'];

mEl = RotMat(elev, 2 );
mAz = RotMat(azim, 3 );
mCamera   = mAz * mEl;

%mCamera   = [1 0 0;0 cEl -sEl;0 sEl cEl]*[cAz 0 sAz;0 1 0;-sAz 0 cAz];

rLVLH     = mCamera*[0;0;-1];
up        = mCamera*[1;0;0];
rCamera   = tgt + cameraDistance * Unit( matLVLH' * rLVLH );
up        = matLVLH' * up;


set(ax,'cameraposition',rCamera')
set(ax,'cameraupvector',up')




%--------------------------------------------------------------------------
%   Callback 
%--------------------------------------------------------------------------
function s = CreateCallback( action, modifier ) 
if( nargin > 1) 
   s = ['CameraControls( ''' action ''',''' modifier ''');']; 
else 
   s = ['CameraControls( ''' action ''');']; 
end 

%--------------------------------------------------------------------------
%   Get the data structure stored in the figure window 
%--------------------------------------------------------------------------
function d = GetH(tag)

figH = findobj( allchild(0), 'flat', 'tag', tag ); 
d    = get( figH, 'UserData' ); 

%--------------------------------------------------------------------------
%   Put the data structure into the user data 
%--------------------------------------------------------------------------
function PutH( h ) 

set( h.fig, 'UserData', h ); 



%-------------------------------------- 
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $ 
% $Revision: 50729 $ 
