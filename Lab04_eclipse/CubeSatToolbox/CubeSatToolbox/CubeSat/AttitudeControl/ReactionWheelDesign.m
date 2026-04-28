function [thickness, inertia, torque, mass] = ReactionWheelDesign( d )

%% Design a reaction wheel to meet input requirements.
%
% Each input has a corresponding input d.units.name which contains
% the units in a string.
%
% Type ReactionWheelDesign for a demo.
%
%--------------------------------------------------------------------------
%   Form:
%   [thickness, inertia, torque, mass]  = ReactionWheelDesign( d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d      (.)       Data structure
%                    .radius      (1,1) Allowable wheel radius    (m)
%                    .wheelSpeed  (1,1) Allowable wheel speed     (rad/s)
%                    .h           (1,1) Maximum momentum storage  (Nms)
%                    .density     (1,1) Density of wheel material (kg/m^3)
%                    .dhdt        (1,1) Maximum momentum change   (Nm)
%
%   -------
%   Outputs
%   -------
%   thickness   (1,1) Wheel thickness           (m)
%   inertia     (1,1) Wheel polar inertia       (Nm^2)
%   torque      (1,1) Wheel torque              (Nm)
%   mass	    (1,1) Wheel mass                  (kg)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
	d.radius     = 0.02;
	d.h          = 0.02;
	d.density    = 19300; % Tungsten
	d.dhdt       = 0.01;
  d.wheelSpeed = 6000*pi/30;
	ReactionWheelDesign( d );
	return
end

% Calculation
torque     = d.dhdt;
inertia    = d.h/d.wheelSpeed;
thickness  = 2*inertia/(d.density*pi*d.radius^4);
mass       = thickness*d.density*pi*d.radius^2;

% Default output
if( nargout < 1 )
  fprintf('Reaction Wheel Design\n---------------------\n')
  fprintf('Mass                 = %12.5f kg\n',       mass         );
  fprintf('Torque               = %12.5f Nm\n',       torque     	);
  fprintf('Momentum storage     = %12.5f Nms\n',      d.h        	);
  fprintf('Material density     = %12.5f kg/m^3\n',   d.density    );
  fprintf('Wheel speed          = %12.5f rad/s\n',   	d.wheelSpeed	);
  fprintf('Momentum change      = %12.5f Nms\n',     	d.dhdt       );
  fprintf('Inertia              = %12.5f kg-m^2\n',  	inertia    	);
  fprintf('Thickness            = %12.5f m\n',        thickness  	);
  clear d;
end
    
%--------------------------------------
% $Date: 2020-06-19 15:04:48 -0400 (Fri, 19 Jun 2020) $
% $Revision: 52850 $
