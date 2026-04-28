function x = AnimationGUI(action, varargin) 

%% This function creates a GUI for doing animations. 
%--------------------------------------------------------------------------
%   Callback Usage:
%   x = AnimationGUI( action, a, b, c  ) 
% 
%   Command Line Usage:
%   AnimationGUI( 'initialize', scData, tgtData, time, options ) 
%--------------------------------------------------------------------------
% 
%   ------ 
%   Inputs 
%   ------ 
%   action          (1,:)   Action to take. Use 'initialize' to create GUI.
%   scData           (.)    Spacecraft data strcture. Fields: 
%                             .r    (3,n)    Position
%                             .t    (1,n)    Time
%                             .c    (3,1)    Constant color, OR:
%                             .c    (3,n)    Time-varying color
%                             .name (:)      Name for labeling
%                             .axis (3,n)    Axis vector for pointing cone
%                             .angle(1,n)    Field of view of cone
%   tgtData          (.)    Target data strcture.     Fields: r, t, c
%   time            (1,N)   Time vector with N points.
%   options          (.)    Data structure with display options.
%     .axisType     (1,:)   Specifies how to draw axis background 
%                           and labels. Choices: 'Hills', 'LVLH', 'Earth', 
%                           'EarthHR' or any other planet name. If a planet 
%                           is chosen it will be drawn in the background. 
%                           In this case it is best to supply planet-fixed 
%                           coordinates so that the trajectory is drawn 
%                           properly with respect to the planet image.
%     .docked       (1,1)   Flag. Specify whether the axes are docked with
%                           the UI controls (1) or in a separated window (0)
%     .view         (1,:)   String. '2D' or '3D'. If 2D, 3rd row is set to 0.
%     .date         (1,1)   Initial Julian date, for lighting of planet axis type 
%                           only. In this case the time units must be seconds
%                           for accurate lighting effects.
% 
%   ------- 
%   Outputs 
%   ------- 
%   x                (:)    Outputs only supplied when called as a callback
%                           function from the GUI.
% 
%--------------------------------------------------------------------------
%   See also: InitializeAxes
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 2000 Princeton Satellite Systems, Inc. All rights reserved. 
%--------------------------------------------------------------------------

if( nargin < 1 ) 
	action = 'initialize'; 
end 
if( nargin < 2 ) 
   a = []; 
else
   a = varargin{1};
end
if( nargin < 3 ) 
   b = []; 
else
   b = varargin{2};
end
if( nargin < 4 ) 
   c = []; 
else
   c = varargin{3};
end
if( nargin < 5 )
   options = [];
else
   options = varargin{4};
end

% check options and fill in missing fields with default choices.
if( isempty(options) )
   options = struct('axisType','default','docked',1,'view','3D','date',[]);
else
   if(~isfield(options,'axisType'))
      options.axisType = 'default';
   end
   if(~isfield(options,'docked'))
      options.docked = 1;
   end
   if(~isfield(options,'view'))
      options.view = '3D';
   end
   if(~isfield(options,'date'))
      options.date = [];
   end
end

global pointAtSat resetAnimGUI pauseAnimGUI recordAnimGUI nameHandleAnimGUI; 

switch action
    
    case {'initialize','init'}
        pauseAnimGUI = 0;
        if( isempty(a) )
            a.r = zeros(3,1);
            a.name = 'blank';
            a.t = 0;
        elseif( ~isfield(a,'name') )
            for i=1:length(a)
                a(i).name = ['obj_',num2str(i)]; %#ok<*AGROW>
            end
        end
        z.sc    = a;
        z.tgt   = b;
        z.time  = c;
        Initialize( z, options );
        
        for i=1:length(a), a(i).t = c; end
        assignin('base','sc',a);
        
    case 'reset'
        AnimationGUI('pause',1);
        h = GetH;
        if( ~isempty(h) )
            h.display = InitializeAxes( h.axes, h.scData, h.tgtData, h.time, 1, h.point, h.display.pointAt, h.axisType );
            resetAnimGUI = 1;
        end
        h.indexNow = 1;
        set( h.timeDisplay, 'string', {num2str(h.time(h.indexNow),2)} );
        set( h.percDisplay, 'string', {sprintf('%1.1f %s',(h.indexNow-1)/(length(h.time)-1)*100,'%')} );
        set(h.pause,      'enable','off');
        set(h.play,       'enable','on');
        set(h.reverse,    'enable','on');
        set(h.stepForward,'enable','on');
        set(h.stepBack,   'enable','on');
        set(h.record,     'value',0);
        set(h.nameObj,    'value',0);
        
        recordAnimGUI = 0;
        assignin('base','movieFrames',[]);
        assignin('base','mI',1);
        
        k = find( ishandle( nameHandleAnimGUI ) );
        delete(nameHandleAnimGUI(k)); %#ok<*FNDSB>
        
        PutH( h );
        
    case 'pause'
        if( ~isempty(a) )
            paused = a;
        else
            paused = ~pauseAnimGUI;
        end
        pauseAnimGUI = paused;
        if( ~paused )
            k = find( ishandle( nameHandleAnimGUI ) );
            delete(nameHandleAnimGUI(k));
            Play;
        else
            h = GetH;
            set(h.play,       'enable','on');
            set(h.reverse,    'enable','on');
            set(h.stepForward,'enable','on');
            set(h.stepBack,   'enable','on');
        end
        
    case 'paused'
        x = pauseAnimGUI;
        
    case 'set sample rate'
        h = GetH;
        set(h.sampleRate,'string',{num2str(round(get(h.sampleBar,'value')))});
        
    case 'add'
        AddData( a, b );
        
    case 'update'
        h = GetH;
        AddData( a, b );
        Update( h.indexNow+1 );
        
    case 'step back'
        StepBack;
        
    case 'step forward'
        StepForward;
        
    case 'play'
        if( pauseAnimGUI )
            pauseAnimGUI = 0;
        end
        k = find( ishandle( nameHandleAnimGUI ) );
        delete(nameHandleAnimGUI(k));
        Play;
        
    case 'reverse'
        if( pauseAnimGUI )
            pauseAnimGUI = 0;
        end
        Play(1);
        
    case 'record'
        h = GetH;
        recordAnimGUI = get(h.record,'value');
        
    case 'camera controls'
        h = GetH;
        status = get(h.cameraControls,'checked');
        switch status
            case 'off'
                set(h.cameraControls,'checked','on');
                if( isempty(h.cameraControlsTag) || isempty(findobj('tag',h.cameraControlsTag)) )
                    h.cameraControlsTag = CameraControls(h.axes);
                    PutH(h);
                end
                CameraControls('show',h.cameraControlsTag);
            case 'on'
                set(h.cameraControls,'checked','off');
                if( ~isempty(findobj('tag',h.cameraControlsTag)) )
                    CameraControls('hide',h.cameraControlsTag);
                end
        end
        
    case 'pointing status'
        h = GetH;
        oldStatus = get(h.pointAtObject,'checked');
        if( strcmp(oldStatus,'off') )
            newStatus = 'on';
            set(h.axes,'cameraTargetMode','manual');
            h.point = 1;
            if( h.display.pointAt < 1 )
                set(h.pointAtSat(1),'checked','on');
                h.display.pointAt = 1;
            end
            cameratoolbar('setmode','orbit')
            set(h.axes,'cameraTarget',h.scData(h.display.pointAt).r(:,h.indexNow)');
            
            set(h.axes,'cameraUpVector',h.scData(h.display.pointAt).r(:,h.indexNow))
            
        else
            newStatus = 'off';
            set(h.axes,'cameraTargetMode','auto');
            h.point = 0;
        end
        set(h.pointAtObject,'checked',newStatus);
        PutH( h );
        drawnow;
        
        
    case 'switch camera target'
        h = GetH;
        newCameraTarget = str2double(a);
        oldCameraTarget = pointAtSat;
        if( newCameraTarget ~= oldCameraTarget )
            set(h.pointAtSat(newCameraTarget),'checked','on');
            if( oldCameraTarget )
                set(h.pointAtSat(oldCameraTarget),'checked','off');
            end
            pointAtSat = newCameraTarget;
            PutH( h );
            cameratoolbar('setmode','orbit')
            drawnow;
        end
        
    case 'toggle axis'
        h = GetH;
        axes(h.axes);
        if( get(h.equalBtn,'value') )
            [az,el]=view;
            axis equal;
            axis(h.axisOrig);
            set(h.axes,'view',[az,el]);
        else
            [az,el]=view;
            axis normal;
            axis(h.axisOrig);
            set(h.axes,'view',[az,el]);
        end
        
    case 'disable'
        h = GetH;
        set(h.play,       'enable','off');
        set(h.reverse,    'enable','off');
        set(h.stepBack,   'enable','off');
        set(h.stepForward,'enable','off');
        set(h.reset,      'enable','off');
        
    case 'enable'
        h = GetH;
        set(h.play,       'enable','on');
        set(h.reverse,    'enable','on');
        set(h.stepBack,   'enable','on');
        set(h.stepForward,'enable','on');
        set(h.reset,      'enable','on');
        
    case 'vanish'
        h = GetH;
        set( h.fig, 'visible','off' );
        
    case 'quit'
        h = GetH;
        if( ~isempty(h) && isfield(h,'fig') )
            CloseFigure(h.fig);
            return;
        end
        closereq
        
    case 'resize'
        ResizeGUI;
        
    case 'get data'
        h = GetH;
        x = h.scData;
        for i=1:length(x)
            x(i).t = h.time;
        end
        
    case 'zoom'
        h=GetH;
        axes(h.axes)
        switch a
            case 'in'
                camzoom(6/5)
            case 'out'
                camzoom(5/6)
        end
        
    case 'set background color'
        h = GetH;
        d = get(h.axes,'Title');
        set([h.axes,h.plotFig],'color',a);
        switch a
            case 'white'
                c = 'black';
                set(h.backgroundWhite,'checked','on');
                set(h.backgroundBlack,'checked','off');
            case 'black'
                c = [0;.75;0];
                set(h.backgroundWhite,'checked','off');
                set(h.backgroundBlack,'checked','on');
        end
        set(d,'color',c);
        set(h.axes,'xcolor',c,'ycolor',c,'zcolor',c);
        
    case 'set view'
        h = GetH;
        set(h.viewMenuXY,'checked','off');
        set(h.viewMenuYX,'checked','off');
        set(h.viewMenuXZ,'checked','off');
        set(h.viewMenuYZ,'checked','off');
        switch a
            case 'xy'
                set(h.axes,'view',[ 0, 90]);
                set(h.viewMenuXY,'checked','on');
            case 'yx'
                set(h.axes,'view',[90,-90]);
                set(h.viewMenuYX,'checked','on');
            case 'xz'
                set(h.axes,'view',[ 0,  0]);
                set(h.viewMenuXZ,'checked','on');
            case 'yz'
                set(h.axes,'view',[90,  0]);
                set(h.viewMenuYZ,'checked','on');
        end
        
    case 'name obj'
        h = GetH;
        showNames = get(h.nameObj,'value');
        axes(h.axes)
        if( showNames )
            AnimationGUI('pause',1);
            if( strcmp(get(h.backgroundWhite,'checked'),'on') )
                color = 'black';
            else
                color = 'white';
            end
            for i=1:h.nSC
                x = h.scData(i).r(1,h.indexNow);
                y = h.scData(i).r(2,h.indexNow);
                z = h.scData(i).r(3,h.indexNow);
                name = h.scData(i).name;
                nameHandleAnimGUI(i) = text(x,y,z,name,'fontsize',14,'fontweight','bold','color',color,'VerticalAlignment','bottom');
            end
            set(h.play,       'enable','off');
            set(h.reverse,    'enable','off');
            set(h.stepForward,'enable','off');
            set(h.stepBack,   'enable','off');
            set(h.pause,      'enable','off');
        else
            k = find( ishandle( nameHandleAnimGUI ) );
            delete(nameHandleAnimGUI(k));
            set(h.play,       'enable','on');
            set(h.reverse,    'enable','on');
            set(h.stepForward,'enable','on');
            set(h.stepBack,   'enable','on');
        end
        
    case 'export'
        f=figure;
        DisplayTrajectory(f);
        
    case 'time control'
        
        h=GetH;
        figH = findobj('name','Time Control');
        if( ~isempty(figH) )
            figure(figH(1));
        else
            SliderBar(1,h.ns,1,@(x) Update(round(x)),'Time Control');
        end
        
    case 'help'
        HelpSystem( 'initialize', 'OnlineHelp', 'AnimationGUI' );
        
    otherwise
        warning('action not understood.');
end

%--------------------------------------------------------------------------
%   Initialize the GUI 
%--------------------------------------------------------------------------
function Initialize( data, options ) 

global pointAtSat resetAnimGUI pauseAnimGUI recordAnimGUI; 

% Data to store in the handle 
%---------------------------- 
h = CompleteData( data ); 

h.indexNow = 1; 
h.done     = 0; 
if( ~isempty(h.tgtData ) )
   h.doTarget = 1; 
else 
   h.doTarget = 0; 
end 

% Only one AnimationGUI may be open 
%---------------------------------- 
g = GetH; 
if( ~isempty(g) ) 
   
   set( g.fig, 'visible', 'on' ); 
   f = fieldnames( h ); 
   for i=1:length(f)
      eval(['g.',f{i},'=h.',f{i},';']); 
   end 
   % Set options as needed
   g.axisType = options.axisType;
   g.date = options.date;
   % Store combined data
   PutH( g );
   
else

   % Color Definitions 
   %------------------ 
   bColor = [0.7 .8 .8]; 
   black  = [0 0 0]; 
      
   bgc    = 'backgroundcolor'; 
   fgc    = 'foregroundcolor'; 
   
   set(0,'units','pixels'); 
   width  = 775; 
   if( options.docked )
      height = 500; 
   else
      height = 70;
   end
   x      = 150; 
   y      = 50; 
   
   h.fig = figure( 'units', 'pixels', 'position', [x y width height], ...
      'NumberTitle','off', 'name','Animation GUI', 'Color',bColor,'menubar','none',... 
   'tag','AnimationGUI', 'CloseRequestFcn',CreateCallback( 'quit' ) );
      % SJT doublebuffer not supported in R2014b


   if( options.docked )
      set(h.fig,'resize','on','ResizeFcn',CreateCallback('resize'));
   end

   h.axisType = options.axisType;

   bColor = get(h.fig,'color');
   
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
   
   % Play Buttons 
   %------------- 
   x = 20; y = 10; w = 40; dw = 10; 
   
   
   h.reverse     = uicontrol( vcb{:}, 'position',[x y w 20], fgc,black, 'callback',CreateCallback( 'reverse' ),      'string','<');                    x = x+w+dw; 
   h.stepBack    = uicontrol( vcb{:}, 'position',[x y w 20], fgc,black, 'callback',CreateCallback( 'step back' ),    'string','|<');                   x = x+w+dw; 
   h.pause       = uicontrol( vcb{:}, 'position',[x y w 20], fgc,black, 'callback',CreateCallback( 'pause' ),        'string','||', 'enable','off');   x = x+w+dw; 
   h.stepForward = uicontrol( vcb{:}, 'position',[x y w 20], fgc,black, 'callback',CreateCallback( 'step forward' ), 'string','>|');                   x = x+w+dw; 
   h.play        = uicontrol( vcb{:}, 'position',[x y w 20], fgc,black, 'callback',CreateCallback( 'play' ),         'string','>' );                   x = x+w+dw; 
   h.record      = uicontrol( vcg{:}, 'position',[x y w 20], fgc,'red', 'callback',CreateCallback( 'record' ),       'string', 'O');                   x = x+w+dw;
   h.reset       = uicontrol( vcb{:}, 'position',[x y w 20], fgc,black, 'callback',CreateCallback( 'reset' ),        'string','Reset' );               x = x+w+dw; 
   
   h.zoomin      = uicontrol( vcb{:}, 'position',[x y w/2 20], fgc,black, 'callback',CreateCallback( 'zoom','in' ),    'string','+' ); x = x+w/2; 
   h.zoomout     = uicontrol( vcb{:}, 'position',[x y w/2 20], fgc,black, 'callback',CreateCallback( 'zoom','out' ),   'string','-'); x = x+w/2+dw; 
   
   set(h.zoomin,'fontsize',14)
   set(h.zoomout,'fontsize',14)
   
   resetAnimGUI  = 0;
   pauseAnimGUI  = 0;
   recordAnimGUI = 0;
   
   % Sample Rate Slider 
   %------------------- 
   ns      = length(h.time); 
   maxRate = max([2 round(ns/100)]); 
   w = 120; 
   h.sampleBar   = uicontrol( vcs{:}, 'position',[x y w 10], 'callback',CreateCallback( 'set sample rate' ),  'max',maxRate, 'min',1, 'value',1 );   
   y = y+10; w = 100; 
   uicontrol( vlt{:}, 'position',[x y w 15], fgc,black, bgc,bColor, 'string','Sample Rate:');                 
   x = x+w; w = 20; 
   h.sampleRate  = uicontrol( vrt{:}, 'position',[x y w 15], fgc,black, bgc,bColor, 'string',{'1'}); x = x+w+dw; 
   
   % Radio Buttons 
   %-------------- 
   w = 30; 
   uicontrol( vct{:},  'position',[x y 35 15], fgc,black, bgc,bColor, 'string','Equal');                                         %x = x+w+dw; 
   h.equalBtn    = uicontrol( vcg{:}, 'position',[x+10 y-15 w/2 15], bgc,bColor, 'callback',CreateCallback('toggle axis'), 'value',0  );   x = x+w+dw; 
   uicontrol( vct{:},  'position',[x y w 15], fgc,black, bgc,bColor, 'string','Tail');                                         %x = x+w+dw; 
   h.tailBtn     = uicontrol( vcg{:}, 'position',[x+10 y-15 w/2 15], bgc,bColor, 'value',0  );   x = x+w+dw; 
   
   uicontrol( vct{:},  'position',[x y w 15], fgc,black, bgc,bColor, 'string','Path');                                         %x = x+w+dw; 
   h.pathBtn     = uicontrol( vcg{:}, 'position',[x+10 y-15 w/2 15], bgc,bColor, 'value',0, ...
     'callback', 'ud=get(get(gco,''parent''),''userdata''); if(get(gco,''value'')), set(ud.satellitePath,''visible'',''on''), else, set(ud.satellitePath,''visible'',''off''), end'); x = x+w+dw; 
   
   % name sat
   %---------
   h.nameObj     = uicontrol( vcg{:}, 'position',[x y-10 60 20], fgc,'k', 'callback',CreateCallback( 'name obj' ),        'string','Show Name' ); x = x+60+dw;
   
   % help button
   %------------
   h.help        = uicontrol( vcb{:}, 'position',[x y-10 w 20], fgc,black, 'callback',CreateCallback( 'help' ),        'string','Help' );
      
   PutH( h ); 

   % 3D Plot Axes 
   %-------------- 
   c1 = 'white'; 
   c2 = 'black'; 
   if( ~options.docked )
      h.plotFig = figure('menubar','none','Name','Animation');
      parent = h.plotFig;
   else
      h.plotFig = h.fig;
      parent = h.fig;
   end
   h.axes = axes( 'Parent', parent, 'box', 'off', 'fontsize',8,...
      'xgrid','on', 'ygrid','on', 'zgrid','on', 'color',c1, 'xcolor',c2, 'ycolor',c2,'zcolor',c2, 'view',[-65,15]);
    % SJT fixes for release R2014b
   if isprop(h.axes,'SortMethod')
     set(h.axes,'SortMethod','childorder');
   else
     set(h.axes,'drawmode','fast');
   end
   if( options.docked )
      set(h.axes, 'units','pixels', 'Position', AxesPos);
   else
      set(h.axes, 'units','normalized' );
   end
   
   % Time Display 
   %------------- 
   x = 20; 
   y = height - 20; 
   h.timeLabel   = uicontrol( vctb{:}, 'position',[x y 35 15], bgc,bColor, 'string','Time:',fgc,black); x = x+w+dw;                              %x = x+w+dw; 
   h.timeDisplay = uicontrol( vrt{:},  'position',[x y 2*w 15], bgc,bColor, 'string',{'0.0'},fgc,black);  
   x = width - 60; 
   h.percDisplay = uicontrol( vrt{:},  'position',[x y 40 15], bgc,bColor, 'string',{'  0.0 %'},fgc,black);  
   
   PutH( h ); 
   
   % Camera Menu
   %------------ 
   h.cameraMenu       = uimenu('Label','&Camera'); 
   h.cameraZoomIn     = uimenu(h.cameraMenu, 'Label','Zoom &In',            'Callback',CreateCallback( 'zoom','in' ),       'enable','on'); 
   h.cameraZoomOut    = uimenu(h.cameraMenu, 'Label','Zoom &Out',           'Callback',CreateCallback( 'zoom','out' ),      'enable','on'); 
   h.cameraControls   = uimenu(h.cameraMenu, 'Label','Show Camera Controls','Callback',CreateCallback( 'camera controls' ), 'enable','on', 'checked','off'); 
   h.pointAtObject    = uimenu(h.cameraMenu, 'Label','Point At Object',     'Callback',CreateCallback( 'pointing status' ), 'enable','on', 'checked','off'); 
   for i=1:h.nSC
      h.pointAtSat(i) = uimenu(h.cameraMenu, 'Label',['Sat ',num2str(i)], 'Callback',CreateCallback( 'switch camera target',num2str(i) ), 'enable','on', 'checked','off' ); 
   end 
   set(h.pointAtSat(1),'separator','on'); 
   set(h.pointAtSat(1),'checked','on'); 
   h.point  = 0; 
   pointAtSat = 1; 
   
   % Background Menu 
   %---------------- 
   h.backgroundMenu   = uimenu('Label','&Background'); 
   h.backgroundWhite  = uimenu(h.backgroundMenu, 'Label','W&hite',         'Callback',CreateCallback( 'set background color','white' ), 'enable','on', 'checked','on' ); 
   h.backgroundBlack  = uimenu(h.backgroundMenu, 'Label','Blac&k',         'Callback',CreateCallback( 'set background color','black' ), 'enable','on', 'checked','off' ); 
   
   % View Menu 
   %---------------- 
   h.viewMenu   = uimenu('Label','&View'); 
   h.viewMenuXY = uimenu(h.viewMenu, 'Label','x-y', 'Callback',CreateCallback( 'set view','xy' ), 'accelerator','j', 'checked','off' ); 
   h.viewMenuYX = uimenu(h.viewMenu, 'Label','y-x', 'Callback',CreateCallback( 'set view','yx' ), 'accelerator','k', 'checked','on' ); 
   h.viewMenuXZ = uimenu(h.viewMenu, 'Label','x-z', 'Callback',CreateCallback( 'set view','xz' ), 'accelerator','l', 'checked','off' ); 
   h.viewMenuYZ = uimenu(h.viewMenu, 'Label','y-z', 'Callback',CreateCallback( 'set view','yz' ), 'accelerator','m', 'checked','off' ); 
   
   PutH( h ); 
   
   % Time Control Menu 
   %---------------- 
   h.timeControlMenu  = uimenu('Label','&Time Control','Callback',CreateCallback('time control')); 
   
   PutH(h)

end

h  = GetH;

% Initialize Axes 
%---------------- 
h.display  = InitializeAxes( h.axes, h.scData, h.tgtData, h.time, 0, h.point, 1, h.axisType ); 
h.axisOrig = [ get(h.axes,'XLim'), get(h.axes,'YLim'), get(h.axes,'ZLim') ]; 
h.view     = get(h.axes,'view'); 
h.originMarker  = []; 
h.targetPath    = []; 
h.satellitePath = []; 
h.light = [];
h.date = JD2000;
if ~isempty(options.date)
  h.date = options.date;
  uSun = SunV1(h.date);
  h.light = light('position',ECIToEF(JD2T(h.date))*uSun);
end

h.cameraControlsTag = [];

assignin('base','movieFrames',[]);
assignin('base','mI',1);

% accelerators for zooming in and out
%------------------------------------ 
set(0,'showhiddenhandles','on') 
op = findobj('label','&Open...'); 
set(op,'accelerator',''); 
set(h.cameraZoomIn,'accelerator','i') 
set(h.cameraZoomOut,'accelerator','o') 
set(0,'showhiddenhandles','off') 

if( length(h.time) <= 1 )
   enable = 'off';
else
   enable = 'on';
end
set(h.reverse,    'enable',enable);
set(h.stepBack,   'enable',enable);
set(h.pause,      'enable',enable);
set(h.stepForward,'enable',enable);
set(h.play,       'enable',enable);
set(h.reset,      'enable',enable);
set(h.record,     'enable',enable);
set(h.nameObj,    'enable',enable);

PutH( h ); 

DisplayTrajectory;
set(h.pathBtn,'value',1)


xdat = [];
ydat = [];
zdat = [];
for i=1:h.nSC
  xdat(i,:)=h.scData(i).r(1,:);
  ydat(i,:)=h.scData(i).r(2,:);
  zdat(i,:)=h.scData(i).r(3,:);
end



%--------------------------------------------------------------------------
%   Callback 
%--------------------------------------------------------------------------
function s = CreateCallback( action, modifier ) 
if( nargin > 1) 
   s = ['AnimationGUI( ''' action ''',''' modifier ''');']; 
else 
   s = ['AnimationGUI( ''' action ''');']; 
end 

%--------------------------------------------------------------------------
%   Get the data structure stored in the figure window 
%--------------------------------------------------------------------------
function d = GetH 

figH = findobj( allchild(0), 'flat', 'tag', 'AnimationGUI' ); 
d    = get( figH, 'UserData' ); 

%--------------------------------------------------------------------------
%   Put the data structure into the user data 
%--------------------------------------------------------------------------
function PutH( h ) 

set( h.fig, 'UserData', h ); 

%--------------------------------------------------------------------------
%   Add data to the window 
%--------------------------------------------------------------------------
function AddData( sc, tgt ) 

h = GetH; 
for i=1:h.nSC 
   h.scData(i).r(:,end+1)  = sc(i).r; 
   if( isfield(sc(i),'c') ) 
      h.scData(i).c(:,size(h.scData(i).r,2)) = sc(i).c; 
   end 
   if(~isempty(tgt)) 
      h.tgtData(i).r(:,end+1) = tgt(i).r; 
      if( isfield(tgt(i),'c') )
         h.tgtData(i).c(:,size(h.scData(i).r,2)) = tgt(i).c; 
      end 
   end 
end 

PutH( h ); 

%--------------------------------------------------------------------------
%   Update the image on the screen 
%--------------------------------------------------------------------------
function Update( index, direction ) 

global pointAtSat recordAnimGUI;

h = GetH; 
d = h.display; 

% Update SC Display 
%------------------ 
if( ishandle(d.head) & ishandle(d.tail) ) 
   
   % draw the tail? 
   doTail = 0; 
   if( get(h.tailBtn,'value') ) 
      doTail = 1; 
   end 

   % cycle through all objects 
   for i = 1:h.nSC 
      
      % actual object 
      head  = h.scData(i).r(:,index); 
      if( h.scData(i).u(index)>0 ) 
         color = h.scData(i).cc; 
      else 
         color = h.scData(i).c(:,index); 
      end 
      set(d.head(i), 'xdata',head(1), 'ydata',head(2), 'zdata',head(3), 'color',color ); 
      if( doTail ) 
         if( direction > 0 ) 
            tailIndex = max([ index-1, 1  ]) :  -1 : max([ index-d.lt, 1 ]); 
         else 
            tailIndex = min([ index+1, d.ns ]) :  1 : min([ index+d.lt, d.ns ]); 
         end 
         tail = h.scData(i).r(:,tailIndex); 
         set(d.tail(i), 'xdata',tail(1,:), 'ydata',tail(2,:), 'zdata',tail(3,:), 'color',color ); 
      end 
   
      % target 
      if( h.doTarget ) 
         headTgt = h.tgtData(i).r(:,index); 
         set(d.headTgt(i), 'xdata',headTgt(1), 'ydata',headTgt(2), 'zdata',headTgt(3) ); 
      end 
   
      % draw a cone
      if( Mag(h.scData(i).axis)>0 )      
         axis  = h.scData(i).axis(:,index);
         angle = h.scData(i).angle(:,index)/2;
                  
         len = sqrt(head'*head)-.75*6378;
         [v, f] = Cone( head, axis, angle, len, 30 );
         set(d.cone(i),'vertices',v,'faces',f,'facecolor',color);
      end
      
   end 

   % if pointing at an object, resolve the camera target 
   if( h.point ) 
      if( index>1 )
         vel = (h.scData(pointAtSat).r(:,index) - h.scData(pointAtSat).r(:,index-1));
      else
         vel = (h.scData(pointAtSat).r(:,index+1) - h.scData(pointAtSat).r(:,index));
      end
      
      set(h.axes,'cameraTarget',h.scData(pointAtSat).r(:,index)'); 
      CameraControls('update',h.cameraControlsTag,vel);
      
      
   end 

end 

% Check the size 
%--------------- 
xLim = get(h.axes,'XLim'); 
yLim = get(h.axes,'YLim'); 
zLim = get(h.axes,'ZLim'); 
reset = zeros(1,3); 

for i=1:h.nSC 
   r = h.scData(i).r(:,index) + h.scData(i).axis(:,index); 
   if( r(1) <= xLim(1) ) 
      xLim(1)  = r(1)-.01*abs(r(1)); reset(1) = 1; 
   end 
   if( r(1) >= xLim(2) ) 
      xLim(2)  = r(1)+.01*abs(r(1)); reset(1) = 1; 
   end 
   if( r(2) <= yLim(1) ) 
      yLim(1)  = r(2)-.01*abs(r(2)); reset(2) = 1; 
   end 
   if( r(2) >= yLim(2) ) 
      yLim(2)  = r(2)+.01*abs(r(2)); reset(2) = 1; 
   end 
   if( r(3) <= zLim(1) ) 
      zLim(1)  = r(3)-.01*abs(r(3)); reset(3) = 1; 
   end 
   if( r(3) >= zLim(2) ) 
      zLim(2)  = r(3)+.01*abs(r(3)); reset(3) = 1; 
   end 
end 
if(reset(1)), set(h.axes,'XLim',xLim); end 
if(reset(2)), set(h.axes,'YLim',yLim); end 
if(reset(3)), set(h.axes,'ZLim',zLim); end 

% Time and Percent Displays 
%-------------------------- 
if( index <= length(h.time) && length(h.time) > 1 )
   set( h.timeDisplay, 'string', {sprintf('%1.2f',h.time(index))} );     
   set( h.percDisplay, 'string', {sprintf('%1.1f %s',(index-1)/(length(h.time)-1)*100,'%')} ); 
end 

% Lighting, for planets
%----------------------
if ~isempty(h.light)
  if ~ishandle(h.light)
    % Reset or other calls to InitializeAxes will delete the light object,
    % recreate it here if needed
    h.light = light;
  end
  % Set the light direction to the current sun vector
  jDNow = h.date+h.time(index)/86400;
  c = ECIToEF( JD2T(jDNow) );
  set(h.light,'position',c*SunV1(jDNow));
end

% refresh the display with the new properties
drawnow;

% record the frame?
if( recordAnimGUI )
   evalin('base','h=findobj(''tag'',''AnimationGUI''); h=get(h,''userdata''); axes(h.axes); movieFrames(:,mI) = getframe;');
   evalin('base','mI = mI+1;');
end

h          = GetH; 
h.done     = 0; 
h.display  = d; 
h.indexNow = index; 
PutH( h ); 

%--------------------------------------------------------------------------
%   Step Back 
%--------------------------------------------------------------------------
function StepBack 

h = GetH; 
x = round(get(h.sampleBar,'value')); 
if( h.indexNow - x < 1 )
   h.indexNow = 1 + x; 
end 

Update( h.indexNow - x, -1 );     

%--------------------------------------------------------------------------
%   Step Forward 
%--------------------------------------------------------------------------
function StepForward 

h = GetH; 
x = round(get(h.sampleBar,'value')); 
%h.indexNow = h.indexNow + x; 
if( h.indexNow + x > length(h.time) )
   h.indexNow = length(h.time) - x; 
   %   return; 
end 
%PutH( h ); 

Update( h.indexNow + x, 1 ); 

%--------------------------------------------------------------------------
%   Play 
%--------------------------------------------------------------------------
function Play( reverse ) 

global resetAnimGUI pauseAnimGUI recordAnimGUI

if( nargin < 1 ) 
   reverse = 0; 
end 

if( reverse ) 
   dir = -1; 
else 
   dir = 1; 
end 

h = GetH; 
if( resetAnimGUI )
   resetAnimGUI = 0; 
   h.done = 1; 
end 
if( h.done && ~reverse )
   h.display = InitializeAxes( h.axes, h.scData, h.tgtData, h.time, 1, h.point, h.display.pointAt, h.axisType ); 
   h.indexNow = 1; 
   h.done = 0; 
end 
PutH( h ); 

axes(h.axes)
axis vis3d 
cameratoolbar('setmode','orbit') 
set(h.pause,      'enable','on'); 
set(h.play,       'enable','off'); 
set(h.reverse,    'enable','off'); 
set(h.stepForward,'enable','off'); 
set(h.stepBack,   'enable','off'); 

ns      = size(h.scData(1).r,2); 
x       = round(get(h.sampleBar,'value'));

if( recordAnimGUI )
   assignin('base','nFrames',floor(ns/x));
   assignin('base','mI',1);
   evalin('base','movieFrames = moviein(nFrames);');
end

j    = h.indexNow; 
left = 1; 
while left >= 0 %j <= ns, 
   
   if( pauseAnimGUI )
      return 
   end 

   Update( j, dir );
   
   %pause(1/10);
   
   if( resetAnimGUI )
      return; 
   end 

   if( (~reverse && j==ns) || (reverse && j==0) ) 
      break; 
   end 

   x = round(get(h.sampleBar,'value')); 
   if( reverse ) 
      j    = max([ j-x, 0  ]); 
      left = j-1; 
   else 
      j    = min([ j+x, ns ]); 
      left = ns - j; 
   end 

end 

%rotate3d on 

h = GetH; 
h.done = 1; 
PutH( h ); 
set(h.pause,      'enable','off'); 
set(h.play,       'enable','on'); 
set(h.reverse,    'enable','on'); 
set(h.stepForward,'enable','on'); 
set(h.stepBack,   'enable','on'); 
set(h.record,     'value',0);

if( ~reverse ) 
   DisplayTrajectory; 
end 

%--------------------------------------------------------------------------
%   Resize the GUI, and keep it looking nice 
%--------------------------------------------------------------------------
function ResizeGUI 

h = GetH; 
if( isempty(h) )
   return; 
end 

set(h.timeDisplay,'position',TimePos(h.timeDisplay)); 
set(h.timeLabel,  'position',TimePos(h.timeLabel)); 
set(h.percDisplay,'position',PercPos); 
set(h.axes,       'position',AxesPos); 
drawnow; 

PutH( h ); 

%--------------------------------------------------------------------------
%   Get Axes Positions 
%--------------------------------------------------------------------------
function aPos = AxesPos 

h = GetH; 

fPos = get(h.fig, 'position'); 

wf = fPos(3);  
hf = fPos(4); 

sm = 0.08; 
tm = 0.08; 
ya = 100; 

xa = wf * sm; 
wa = wf * (1 - 2*sm ); 
ha = hf * (1 - tm ) - ya; 

aPos = [xa ya wa ha]; 

%--------------------------------------------------------------------------
%   Get Time Display Position 
%--------------------------------------------------------------------------
function tPos = TimePos( handle ) 

h = GetH; 

fPos    = get(h.fig,  'position'); 
tPos    = get(handle, 'position'); 
tPos(2) = fPos(4)-20; 

%--------------------------------------------------------------------------
%   Get Percent Display Position 
%--------------------------------------------------------------------------
function pPos = PercPos 

h = GetH; 

fPos    = get(h.fig,         'position'); 
pPos    = get(h.percDisplay, 'position'); 
pPos(1) = fPos(3)-60; 
pPos(2) = fPos(4)-20; 

%--------------------------------------------------------------------------
%   Display the Trajectory 
%--------------------------------------------------------------------------
function DisplayTrajectory( newFig ) 

if( nargin<1 )
   newFig = 0;
end

h  = GetH; 

% Redo the plot to keep the lines permanently 
%-------------------------------------------- 
axes(h.axes)
hold on; 

% if going into new figure window, make the figure current
if( newFig )
   figure( newFig )
end

% if going into animation window, store plots in handles
h.originMarker  = [];
h.targetPath    = [];
h.satellitePath = [];

% do the plotting the same for both cases
for i=1:h.nSC
  h.originMarker(end+1) = plot3(h.scData(i).r(1,1), h.scData(i).r(2,1), h.scData(i).r(3,1), 'go', 'markersize', 10 );
  if( ~isempty(h.tgtData) )
     h.targetPath(end+1) = plot3(h.tgtData(i).r(1,:), h.tgtData(i).r(2,:), h.tgtData(i).r(3,:), 'color',h.tgtData(i).c(:,1),'linestyle','--', 'linewidth',.1 );
  end
  for k=1:length(h.scData(i).iD)-1
    colID = h.scData(i).iD(k):h.scData(i).iD(k+1)-1;
    h.satellitePath(end+1) = plot3(h.scData(i).r(1,colID), h.scData(i).r(2,colID), h.scData(i).r(3,colID),...
      'color',h.scData(i).c(:,colID(1)), 'linewidth',1.0 );
  end
end

if( newFig )
   grid on
   axis equal
   AddView;
   AddZoom;
   title('Trajectory in Local Reference Frame','fontsize',14,'fontname','Arial')
   xlabel('x_H - azimuth (km)',                'fontsize',14,'fontname','Arial')
   ylabel('y_H - along-track (km)',            'fontsize',14,'fontname','Arial')
   zlabel('z_H - cross-track (km)',            'fontsize',14,'fontname','Arial')
   %rotate3d on
else
   PutH( h ); 
   %rotate3d on
end
cameratoolbar('setmode','orbit')



%--------------------------------------------------------------------------
%   Complete the required data set 
%--------------------------------------------------------------------------
function d = CompleteData( data ) 

d.scData  = data.sc; 
d.tgtData = data.tgt; 

% Time 
%----- 
if( ~isempty( data.time ) ) 
   d.time = data.time; 
elseif( isfield(d.scData(1),'t') && ~isempty(d.scData(1).t) ) 
   d.time = d.scData(1).t; 
else 
   d.time = 0:1:size(d.scData(1).r,2)-1; 
end 

d.nSC = length(d.scData); 
d.ns  = length(d.time); 

% Axis
%-----
if( ~isfield(d.scData,'axis') )
   for i=1:d.nSC
      d.scData(i).axis  = zeros(3,d.ns); 
      d.scData(i).angle = zeros(1,d.ns);
   end 
else
   for i=1:d.nSC
      if( size(d.scData(i).axis,1)==3 && size(d.scData(i).axis,2)==1 )
         d.scData(i).axis = DupVect( d.scData(i).axis, d.ns );
      elseif( isempty(d.scData(i).axis) )
         d.scData(i).axis  = zeros(3,d.ns); 
         d.scData(i).angle = zeros(1,d.ns);
      end
      if( size(d.scData(i).angle,2)==1 )
         d.scData(i).angle = ones(1,d.ns)*d.scData(i).angle;
      end
   end
end

% Use default color if not provided 
%---------------------------------- 
if( ~isfield( d.scData(1), 'c' ) ) 
   colorOrder = get(0,'DefaultAxesColorOrder');
   nColors = size(colorOrder,1);
   for i=1:d.nSC
      k=mod(i,nColors);
      if(k==0)
        k=nColors;
      end
      d.scData(i).c = colorOrder(k,:)'; 
      if( ~isempty( data.tgt ) ) 
         d.tgtData(i).c = colorOrder(k,:)';
      end 
   end 
end
for i=1:d.nSC
   if( size(d.scData(i).c,1)==3 && size(d.scData(i).c,2) == 1 )
      d.scData(i).c = DupVect( d.scData(i).c, d.ns );
      d.scData(i).iD = [1 d.ns+1];
   elseif( size(d.scData(i).c,2)~=d.ns )
      error('Incorrect format for color.');
   else
      % divide into color-coded segments
      if size(d.scData(i).c,2)>1
        d.scData(i).iD = 1;
        color = d.scData(i).c(:,1);
        for j=2:size(d.scData(i).c,2)
          if ~all(d.scData(i).c(:,j)==color)
            d.scData(i).iD(end+1)=j;
            color = d.scData(i).c(:,j);
          end
        end
      end
      d.scData(i).iD(end+1) = d.ns+1;
   end
end

% conditional vector 
%------------------- 
if( ~isfield( d.scData(1), 'u' ) ) 
   for i=1:d.nSC
      d.scData(i).u = zeros(1,d.ns); 
   end 
end 

% conditional color 
%------------------ 
if( ~isfield( d.scData(1), 'cc' ) ) 
   for i=1:d.nSC
      d.scData(i).cc = [1; .25; .45]; 
   end 
end 


%-------------------------------------- 
% $Date: 2020-06-10 12:58:40 -0400 (Wed, 10 Jun 2020) $ 
% $Revision: 52694 $ 
