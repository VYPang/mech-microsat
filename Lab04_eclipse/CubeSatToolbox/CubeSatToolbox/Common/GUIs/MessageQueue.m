function MessageQueue( action, modifier, msg, ~ )

%% Creates a message queue GUI. Once opened, it stays open. 
%   It accumulates messages from any function that sends messages to the queue.
%
%   Add this to your code whenever you want a to alert the user to an error.
%
%   MessageQueue('add', myFunction ,'The error','error');
%
%   Add this to your code whenever you want a to send the user a message.
%
%   MessageQueue('add', myFunction ,'The message');
%
%   You can turn on a sound notification. Use MessageQueue( 'sound on' ).
%
%--------------------------------------------------------------------------
%   Form:
%   MessageQueue( action, modifier, msg, err )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action          (1,:)   Action to be taken 
%   modifier        (1,:)   Action modifier
%   msg             (1,:)   Message
%   err             (1,:)   If anything entered an error
%
%   -------
%   Outputs
%   -------
%   none
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999-2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  action  = 'initialize';
end

switch action
  case 'initialize'
    InitializeGUI;

  case 'bring to front'
    h = GetH;
    if( isempty(h) )
      InitializeGUI;
      h = GetH;
    end
    figure(h.fig);

  case 'add'
    h = GetH;
    if( isempty(h) )
      InitializeGUI;
      h = GetH;
    end
    try, modifier = [num2str(FSWClock('get met')),' - ',modifier];, end
    s = get( h.errorList, 'string' );
    if( nargin > 3 )
      z = sprintf( '%s: ERROR - %s',modifier,msg);
    else
      z = sprintf( '%s: %s',modifier,msg);
    end
    s = {z s{:}};
    if( h.makeSound )
       sound(h.sound.sound,10000);
    end
    set( h.errorList, 'string', s );
    set( h.errorList, 'value',  1 );

  case 'clear'
    h = GetH;
    if( isempty(h) )
      InitializeGUI;
      h = GetH;
    end
    
    set( h.errorList, 'string', {} );
    set( h.errorList, 'value',  1 );

    % Bring this figure to the front
    %-------------------------------
    figure( h.fig );
     
	case 'quit'
    h = GetH;
    if( isfield( h, 'fig' ) & ishandle( h.fig ) )
      CloseFigure( h.fig );
    end
  
  case 'help'
    HelpSystem( 'initialize', 'OnlineHelp' );
    
 case 'sound off'
    h = GetH;
    h.makeSound = 0;
    PutH(h);

 case 'sound on'
    h = GetH;
    h.makeSound = 1;
    PutH(h);
    
 case 'show'
    h = GetH;
    set(h.fig,'visible','on');
    
 case 'hide'
    h = GetH;
    set(h.fig,'visible','off');
    
end

%--------------------------------------------------------------------------
%   Initialize the GUI
%--------------------------------------------------------------------------
function InitializeGUI

h = GetH;

if( ~isempty(h) )
   if( ishandle(h.fig) )
      figure(h.fig); % bring to front
   end
   return;
end

% The figure window
%------------------
         set(0,'units','pixels');
p      = get(0,'screensize');
height = 400;
width  = 400;
bottom =  20;
left   =  10;
h.fig  = figure('name','Message Queue','Units','pixels', 'Position',[left bottom width height ],...
                'NumberTitle','off','tag', 'Error Queue', 'resize', 'off' );

v           = {'parent', h.fig, 'units', 'pixels', 'fontunits', 'pixels', 'fontsize', 10, 'fontname', 'helvetica' };    
hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug
h.errorList = uicontrol( v{:}, 'Position', [          5 30 width-10 360 ], 'string', {''}, 'style', 'listbox', 'backgroundcolor', [1 1 1] );
h.clear     = uicontrol( v{:}, 'Position', [width - 255  5       80  20 ], 'string', 'Clear', 'callback', CreateCallback('clear') );
h.quit      = uicontrol( v{:}, 'Position', [width - 170  5       80  20 ], 'string', 'QUIT',  'callback', CreateCallback('quit') );
h.help      = uicontrol( v{:}, 'Position', [width -  85  5       80  20 ], 'string', 'HELP',  'callback', CreateCallback('help') );

h.sound     = load('Sosumi');
h.makeSound = 0;
PutH( h );

%--------------------------------------------------------------------------
%   Get data from the figure handle
%--------------------------------------------------------------------------
function h = GetH

figH = findobj( allchild(0), 'tag', 'Error Queue' );
h    = get( figH, 'userData' );

%--------------------------------------------------------------------------
%   Put data into the figure handle
%--------------------------------------------------------------------------
function PutH( h )

set( h.fig, 'userdata', h );

%--------------------------------------------------------------------------
%   Sim callback
%--------------------------------------------------------------------------
function s = CreateCallback( action, ~ )

s = ['MessageQueue( ''' action ''');'];

%--------------------------------------
% $Date: 2019-12-29 13:35:15 -0500 (Sun, 29 Dec 2019) $
% $Revision: 50749 $
