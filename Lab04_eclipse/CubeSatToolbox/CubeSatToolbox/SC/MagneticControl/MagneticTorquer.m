function y = MagneticTorquer( action, d )

%% Simple MagneticTorquer model. Outputs the torque in body coordinates.
%
%   Input fields on initialization are:
%
%   d.powerConsumption (1,1)  Watts
%   d.dipole           (3,n)  ATM^2
%
%   The magnetic field needs to be set for the output to be nonzero. The field
%   should be in body coordinates.
%
%   Failure mode is zero output. Commands anf failures are input using a matrix
%   of logical values.
%--------------------------------------------------------------------------
%   Forms:
%            MagneticTorquer( 'initialize', d )
%            MagneticTorquer( 'update' )
%            MagneticTorquer( 'set bfield', b )
%            MagneticTorquer( 'set failure', f )
%            MagneticTorquer( 'set command', c )
%   power  = MagneticTorquer( 'get power consumption' )
%   torque = MagneticTorquer( 'output' )
%   d      = MagneticTorquer( 'get default datastructure' )
%--------------------------------------------------------------------------
%
%   -------
%   Inputs
%   -------
%   action      (1,:)     'initialize' 'update'  'output' 
%                         'set bfield' 'set failure'
%   d           (1,1)     Depends on the action
%
%   -------
%   Outputs
%   -------
%   y           (1,1)     Depends on the action
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002, 2007 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

persistent a s

switch action
	case 'initialize'
	  if( nargin < 2 )
		  a = Default;
	  else
	    a = d;
	  end
	  s.failure     = [0;0;0];
	  s.bFieldBody  = [0;0;0];
	  s.power       = 0.0;
	  s.command     = [];
	  
  case 'get power consumption'
	  y          = s.power;

  case 'update'
	  n        = length(s.command);
	  dipole   = zeros(3,n);
	  s.power  = 0;

	  for k = 1:n
		 if( s.command(k) && ~s.failure(k) )
		   dipole  = a.dipole(:,k);
		   s.power = s.power + a.powerConsumption;
		 end
	  end
	 
	  s.output = sum( Cross( dipole, s.bFieldBody ), 2 );
	  
	case {'output' 'get output'}
	  y = s.output;
	  
  case 'set bfield'
	  s.bFieldBody = d;
	  
  case {'put command' 'set command'}
	  s.command = d;
	
  case 'set failure'
	  s.failure = d;
	  
  case 'get default datastructure'
	  y = Default;
    
  otherwise
    error('PSS:MagneticTorquer:error','MagneticTorquer: unknown action')
end

%---------------------------------------------------------------------------
%   Default data
%---------------------------------------------------------------------------
function a = Default

a.dipole                 = zeros(3,3);
a.powerConsumption       = 0;
a.residualDipoleFraction = 0;

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 13:56:08 -0400 (Thu, 11 May 2017) $
% $Revision: 44558 $
