function x = RWA( action, y, k )

%% A RWA model using FrictionSmooth.
%
%   You will initialize to a Honeywell HR0610 model. Only marketing sheet data is
%   used.
%
%   This model uses FrictionSmooth to model the friction.
%
%   k      = RWA( 'initialize' );                         Initializes the wheel
%   k      = RWA( 'initialize',                 [], k );  Initializes the wheel(s)
%   x      = RWA( 'get tachometer measurement', [], k );  Gets the wheel speed
%   d      = RWA( 'get default datastructure',  [], k );  Gets the default RWA data
%   d      = RWA( 'get datastructure',          [], k );  Gets the RWA data
%   x      = RWA( 'get power',                  [], k );  Gets the power.
%   x      = RWA( 'get current',                [], k );  Gets the power from d
%   x      = RWA( 'get motor voltage',          [], k );  Gets the motor voltage.
%            RWA( 'put voltage',               vIn, k );  Puts the voltage into d
%   x      = RWA( 'compute torque',             [], k );  Computes torque
%            RWA( 'torque speed curve',      omega, k );  Plots the torque speed curve
%                                                         if omega is [] it will use a
%                                                         default rate vector. Omega
%                                                         must be a 1-by-n array.
%   
%   k can be a number or a tag.
%
%   A typical calling sequence is
%
%   RWA;
%
%   loop:
%      d           = RWA( 'put voltage',       voltageIn, k );
%      [torque, d] = RWA( 'compute torque',    omega,     k );
%      power       = RWA( 'get power',         [],        k );
%      current     = RWA( 'get current',       [],        k );
%      voltage     = RWA( 'get motor voltage', [],        k );
%   end loop;
%
%   Since version 3.
%--------------------------------------------------------------------------
%   Form:
%   x = RWA( action, y, k )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action	  (:)    Action
%   y         (1,1)  See above
%             (1,1)  Datastructure for the wheels
%                    .kT          (1,1) Torque constant (N/A)
%                    .kV          (1,1) Voltage Gain (N/rad/sec)
%                    .kW
%                    .friction    = struct( 'fStatic',  (1,1), 'kStatic',  (1,1),
%                                           'fCoulomb', (1,1), 'kCoulomb', (1,1),
%                                           'bViscous', (1,1) );
%                    .currentMax  (1,1) Upper current limit (A)
%                    .currentMin  (1,1) Lower current limit (A)
%                    .busVoltage  (1,1) Bus voltage
%                    .r           (1,1) Motor resistance (Ohms)
%                    .kMaxTach    (1,1) Maximum tach count
%                    .kMinTach    (1,1) Minimum tach count
%                    .resTach     (1,1) Tach resolution
%                    .kMaxVoltage (1,1) Maximum voltage count
%                    .kMinVoltage (1,1) Minimum voltage count
%                    .resVoltage  (1,1) D/A resolution
%                    .kMinVoltage (1,1) Minimum voltage count
%                    .voltageWord (1,1) Voltage word  
%                    .omega       (1,1) Wheel speed
%                    .power       (1,1) Electrical power 
%                    .current     (1,1) Motor current 
%                    .voltage     (1,1) Motor voltage 
%                    .inertia
%
%   -------
%   Outputs
%   -------
%   x        (:)    Output
%   k        (1,1)  Index
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998-1999 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

persistent d tag

if( nargin < 1 )
  action = 'initialize';
end

if( nargin < 2 )
  y = [];
end

if( nargin < 3 )
  k = [];
end

% Analyze the index
%------------------
[k, tag] = ProcessTag( action, tag, k, 'RWA' );

% Perform the action
%-------------------

switch action
  case 'initialize'
    if( isempty(d) )
      if( isempty(y) )
        d = Default;
      else
        d = y;
      end
    else
      d = [d Default];
    end
    x = k;

  case 'get tachometer measurement'
    x       = FloatToWord( d(k).omega, d(k).kMaxTach, d(k).kMinTach, d(k).resTach );

  case 'get default datastructure'
    x       = Default;

  case 'get datastructure'
    x       = d;

  case 'get power'
    x       = d(k).power;

  case 'get current'
    x       = d(k).current;

  case 'get motor voltage'
    x       = d(k).voltage;

  case 'get inertia'
    x       = d(k).inertia;

  case 'put voltage'
    d(k).voltageWord = y;

  case 'put speed'
    d(k).omega       = y;

  case 'compute torque'
    omega = d(k).omega;

    % Convert to a floating point number and multiply by the voltage gain
    %--------------------------------------------------------------------
    d(k).voltage    = d(k).kV.*WordToFloat( d(k).voltageWord, d(k).kMaxVoltage, d(k).kMinVoltage, d(k).resVoltage );

    % Bus voltage limit
    %------------------
    j               = find( abs(d(k).voltage) > d(k).busVoltage );
    d(k).voltage(j) = sign(d(k).voltage(j))*d(k).busVoltage;

    % Apply back emf
    %---------------
    d(k).current = (d(k).voltage - d(k).kT.*omega)./d(k).r;

    % Current limits
    %---------------
    j               = find( d(k).current < d(k).currentMin );
    d(k).current(j) = d(k).currentMin;
    j               = find( d(k).current > d(k).currentMax );
    d(k).current(j) = d(k).currentMax;

    % Compute torque subtracting friction
    %------------------------------------
    x       = d(k).kT.*d(k).current - d(k).kW.*omega - FrictionSmooth( omega, d(k).friction );
     
    % Store for calls to power bus
    %-----------------------------
    d(k).power = d(k).current.*d(k).voltage;

  case 'torque speed curve'

    if( isempty(y) )
      omega  = linspace( -200*pi, 200*pi, 200 );
    else
      omega  = y;
    end

    if( isempty(k) )
      RWA('initialize');
    else
      RWA('initialize',[],k);
    end

    torque  = zeros(1,length(omega));
    power   = zeros(1,length(omega));
    current = zeros(1,length(omega));
    vIn     = zeros(1,length(omega));

    for j = 1:length(omega)
      if( omega(j) >= 0)
        vIn = d(1).kMaxVoltage;
      else
        vIn = d(1).kMinVoltage;
      end
      RWA(   'put speed', omega(j), 1 );
      RWA( 'put voltage',   vIn, 1 );
      torque(j)  = RWA( 'compute torque', 1 );
      power(j)   = RWA( 'get power',      1 );
      current(j) = RWA( 'get current',    1 );
    end
    Plot2D( omega, [torque; power;current], 'Rate (rad/sec)',['Torque  (N)';'Power   (W)';'Current (A)'],'Torque Speed Curve');

  otherwise
    disp(['RWA: action ' is an unknown action'])
end

%-------------------------------------------------------------------------------
%	  These numbers give the performance of the Honeywell HR 0610
%-------------------------------------------------------------------------------
function d = Default

d.currentMax   =  3.47;
d.currentMin   = -3.47;
d.busVoltage   = 28;
d.inertia      =  6/(200*pi);
d.kT           =  0.0216;
d.r            =  6.63;
d.kW           =  4.93e-5;
d.friction     = struct('fStatic', 0, 'kStatic', 0, 'fCoulomb', 0, 'kCoulomb', 0,'bViscous', 0 );
d.kV           =   4.6;
d.kMaxTach     =  2048;
d.kMinTach     = -2047;
d.resTach      =  410*pi/4096;
d.kMaxVoltage  =   128;
d.kMinVoltage  =  -127;
d.resVoltage   =  10/256;
d.omega        =  0;
d.voltageWord  =  0;
d.power        =  0;
d.current      =  0;
d.voltage      =  0;

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:15:45 -0400 (Thu, 11 May 2017) $
% $Revision: 44570 $


