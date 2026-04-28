function status = ODETimeDisplay( time, ~, action, varargin )

%% Displays an estimate of time to go, compatible with ode113.
% Pass this function as an outputfcn for a MATLAB ODE. Opens a window displaying
% the percent complete and an estimate of the time to go. Updates at 0.5 sec
% intervals. The time to go will not be exact, as the ode is calculating
% variable time steps, but will become more accurate as the sim progresses.
%
% You can only have one ODETimeDisplay operating at once.
%--------------------------------------------------------------------------
%   Form:
%   status = ODETimeDisplay( tspan, y0, 'init' )
%   status = ODETimeDisplay( t, y, '' )
%   status = ODETimeDisplay( [], [], 'done' )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   time          (n)      Time
%   y             (n,1)    Data (currently unused)
%   action        (1,:)    'init', '', or 'done'
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
%%
persistent hGUI

status = 0;
switch action
  case 'init'
    hGUI            = BuildGUI( 'ODE Time Display' );
    hGUI.tspan      = time;
    hGUI.timeDone   = 0;
    hGUI.timeLast   = 0;
    hGUI.rateAvg    = 0;
    hGUI.rateVec    = [];
    hGUI.nSteps     = 0;
    hGUI.jD0        = now;
    hGUI.lastJD     = now;
  case 'done'
    if ~isempty(hGUI) && ishandle(hGUI.fig)
      delete( hGUI.fig );
    else
      delete(gcf)
    end
    hGUI = [];
  otherwise
    if( isempty( hGUI ) )
      return
    end
    hGUI.timeDone = time(end);
    hGUI = Update( hGUI );
end

%--------------------------------------------------------------------------
function hGUI = Update( hGUI )
% Update the display
%--------------------------------------------------------------------------

jD     = now;
dTReal = jD-hGUI.lastJD; % days
if (dTReal > 0.5/86400)
  t0     = hGUI.tspan(1);
  tEnd   = hGUI.tspan(end);
  rate   = (hGUI.timeDone-hGUI.timeLast)/dTReal;
  % deltaRate = (hGUI.timeDone-t0)/(jD - hGUI.jD0); % alternative average
  % simple moving average with 4 samples
  nMove = 4;
  if length(hGUI.rateVec) == nMove
    rateAvg = hGUI.rateAvg + rate/nMove - hGUI.rateVec(nMove)/nMove;
    hGUI.rateVec = [rate hGUI.rateVec(1:end-1)];
  else
    hGUI.rateVec = [rate hGUI.rateVec];
    rateAvg = mean(hGUI.rateVec);
  end
  tToGo  = (tEnd - hGUI.timeDone)/rateAvg;
  datev  = datevec(tToGo);
  s      = sprintf('%4.2f%% complete with %2.2i:%2.2i:%2.0f to go',...
                   100*(hGUI.timeDone-t0)/(tEnd-t0),...
                   datev(4),datev(5),datev(6)); 

  set( hGUI.percent, 'String', s );   
  drawnow;
  hGUI.lastJD = jD;
  hGUI.timeLast = hGUI.timeDone;
  hGUI.rateAvg = rateAvg;
  hGUI.nSteps = hGUI.nSteps+1;
end

%--------------------------------------------------------------------------
function h = BuildGUI( name )
%	Initialize the GUIs
%--------------------------------------------------------------------------

set(0,'units','pixels')
p           = get(0,'screensize');
bottom      = p(4) - 190;
h.fig       = figure('name',name,'Position',[340 bottom 298 90],'NumberTitle','off',...
                     'menubar','none','resize','off','closerequestfcn',...
                     'ODETimeDisplay([],[],''done'');');

v           = {'Parent',h.fig,'Units','pixels','fontunits','pixels'};

hMatlab6Bug = uicontrol('visible','off'); % Added to fix a Matlab 6 bug

h.percent   = uicontrol( v{:}, 'Position',[ 20 50 260 15], 'Style','text',...
                         'Tag','StaticText2');
drawnow;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-01 16:57:45 -0400 (Mon, 01 May 2017) $
% $Revision: 44443 $
