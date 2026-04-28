function y = SingleAxisLinearDrive( action, d )

%% Model a single axis drive with the motor dynamics modeled by a lag.
% Typing SingleAxisLinearDrive is the same as
% SingleAxisLinearDrive('initialize')
%--------------------------------------------------------------------------
%
%   -------
%   Inputs
%   -------
%   action      (1,:)     'initialize' 'get power consumption'
%                         'set torque'  'get torque'
%                         'get state derivative' 'update'
%                         'set failure' 'get default datastructure'
%   d           (1,1)     Depends on the action
%
%   -------
%   Outputs
%   -------
%   y           (1,1)     Depends on the action
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
  action = 'initialize';
end

persistent a

switch action
	case 'initialize'
	  if( nargin < 2 )
		a = Default;
	  else
	    a = d;
	  end
	  a.torque          = 0;
	  a.stateDerivative = 0;
	  a.torqueDemand    = 0;
	  a.failure         = 0;
	  
    case 'get power consumption'
	  y = a.powerConsumption;

    case 'set torque'	
	  a.torqueDemand = d;
	  
	case 'get torque'	  
	  y = a.torque;

   case 'get state derivative'
	  y = a.stateDerivative
	  
    case 'update'
      a.torque          = d;
	  a.stateDerivative = (a.torqueDemand - d)/a.tau;
	
    case 'set failure'
	  a.failure = d;
	  
    case 'get default datastructure'
	  y = Default;

end

%--------------------------------------------------------------------------
%   Default data
%--------------------------------------------------------------------------
function a = Default

a.tau              = 0.1;
a.powerConsumption = 0;

% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 12:07:36 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52632 $
