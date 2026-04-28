function TimeDisplay( action, varargin )

%% Displays an estimate of time to go.
%
% Call TimeDisplay('update') each step; the step counter is incremented
% automatically. This GUI does NOT provide any simulation controls
% (pause/stop). Updates at 0.5 sec intervals.
%
% TimeDisplay( 'initialize', nameOfGUI, totalSteps )
% TimeDisplay( 'update' )
% TimeDisplay( 'close' )
%
% You can only have one TimeDisplay operating at once.
%
%--------------------------------------------------------------------------
%   Form:
%   TimeDisplay( action, varargin )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action        (1,:)    'initialize' 'update' 'close'
%   nameOfGUI     (1,:)    Name to display
%   totalSteps    (1,1)    Total number of steps
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

persistent hGUI

switch action
  case 'initialize'
    hGUI            = BuildGUI( varargin{1} );
    hGUI.totalSteps = varargin{2};
    hGUI.stepsDone  = 0;
    hGUI.jD0        = now;
    hGUI.lastJD     = now;
  case 'update'
    if( isempty( hGUI ) )
      return
    end
    hGUI.stepsDone = hGUI.stepsDone + 1;
    hGUI = Update( hGUI );
  case 'close'
    if ~isempty(hGUI) && ishandle(hGUI.fig)
      delete( hGUI.fig );
    else
      delete(gcf)
    end
    hGUI = [];
end

%% TimeGUI>>Update
function hGUI = Update( hGUI )

jD     = now;
dTReal = jD-hGUI.lastJD; % days
if (dTReal > 0.5/86400)
  stepPerJD = hGUI.stepsDone/(jD - hGUI.jD0);
  stepsToGo = hGUI.totalSteps - hGUI.stepsDone;
  tToGo     = stepsToGo/stepPerJD;
  datev     = datevec(tToGo);
  s         = sprintf('%4.2f%% complete with %2.2i:%2.2i:%5.2f to go',...
                      100*(hGUI.stepsDone/hGUI.totalSteps),datev(4),datev(5),datev(6)); 

  set( hGUI.percent, 'String', s );   
  drawnow;
  hGUI.lastJD = jD;
end

%% TimeGUI>>BuildGUI
function h = BuildGUI( name )

set(0,'units','pixels')
p           = get(0,'screensize');
bottom      = p(4) - 190;
h.fig       = figure('name',name,'Position',[340 bottom 298 90],'NumberTitle','off',...
                     'menubar','none','resize','off','closerequestfcn',...
                     'TimeDisplay(''close'')');

v           = {'Parent',h.fig,'Units','pixels','fontunits','pixels'};

hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug

h.percent   = uicontrol( v{:}, 'Position',[ 20 50 260 15], 'Style','text', 'Tag','StaticText2');
drawnow;

%--------------------------------------
% $Date: 2018-08-07 14:35:08 -0400 (Tue, 07 Aug 2018) $
% $Revision: 46862 $
