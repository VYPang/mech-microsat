function TimeCntrl( action )

%% Perform actions specified by the time display.
%
% This routine is called by a callback routine in TimeGUI.m. You do not 
% normally call it yourself.
%
% Initialize the global as follows:
%
% global simulationAction
% simulationAction = ' ';
%
% Use the following code in your simulation loop:
%
% switch simulationAction
%   case 'pause'
%     pause
%     simulationAction = ' ';
%   case 'stop'
%     return;
%   case 'plot'
%     break;
% end
%
% Since version 2.
%--------------------------------------------------------------------------
%   Form:
%   TimeCntrl( action )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action    (1,:) Action to take
%
%   -------
%   Outputs
%   -------
%   None
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright 1997 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

global simulationAction;

if( nargin > 0 )
  switch action
    case {'pause','plot','stop'}
      simulationAction = action;
    otherwise
      simulationAction =' ';
  end
else
  simulationAction = ' ';
end

%--------------------------------------
% $Date: 2019-12-29 13:35:15 -0500 (Sun, 29 Dec 2019) $
% $Revision: 50749 $
