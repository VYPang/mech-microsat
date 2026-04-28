function y = SingleAxisDrive( action, d )

%% Model a stepping motor drive.
%
%   -------
%% Inputs
%   -------
%   action      (1,:)     'initialize' 'set failure' 'get power consumption'
%                         'set steps' 'set direction' 'get angle'
%                         'set angle'  'update' 'get default datastructure'
%   d           (1,1)     Depends on the action
%
%   -------
%   Outputs
%   -------
%   y           (1,1)     Depends on the action
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

persistent a

switch action
	case 'initialize'
	  if( nargin < 2 )
      a = Default;
	  else
	    a = d;
	  end
	  a.angle      = [0;0];
	  a.direction  = [1;1];
	  a.stepDemand = [0;0];
	  a.failure    = [0;0];
	  
  case 'get power consumption'
	  y = a.stepPower*sum(sign(a.stepDemand));

  case 'set steps'	
	  a.stepDemand = a.stepDemand + d;
    
  case 'set direction'
	  a.direction  = d;
	  
	case 'get angle'	  
	  y            = a.angle;
	  
	case 'set angle'	  
	  a.angle      = d;
	  
  case 'update'
    % always applied in fixed direction unless direction changed
	  nSteps       = d*a.steppingRate;
	  deltaSteps   = min( [[nSteps;nSteps] abs(a.stepDemand.*~a.failure)], [], 2 );
	  a.angle      = a.angle + a.stepAngle*a.direction.*deltaSteps;
	  a.stepDemand = a.stepDemand - a.direction.*deltaSteps;
	
  case 'set failure'
	  a.failure = d;
	  
  case 'get default datastructure'
	  y = Default;

end

%---------------------------------------------------------------------------
%   Default data
%---------------------------------------------------------------------------
function a = Default

a.stepPower    = 0;
a.steppingRate = 8.0;
a.stepAngle    = 0.0209;

% PSS internal file version information
%--------------------------------------
% $Date: 2019-12-01 22:31:03 -0500 (Sun, 01 Dec 2019) $
% $Revision: 50474 $
