function [dC, dSim] = LunarMissionControl( action, jD, dC, dSim, meas, cList )


%%	Implements a lunar mission control system.
%	The command list cell array is {time command data}
%	where data is a data structure for that command. The command list
%	rows should be in order of Julian date. You can also use +sec instead of
% jD in which case the time is +sec after the previous command. If the 
% first command is +sec then it is +sec from the time passed on
% initialization.
%
% Supported commands:
%
%  Command                          data
%  'align with a quaternion',        struct('q_target',[0;1;0;0]);...
%  'lunar orbit insertion prepare',	struct('thrust',20,'massInitial',6,...
%                                          'uE', 290*9.806,...
%                                          'body_vector',[1;0;0],...
%                                          'hLunarOrbit',200);...
%  'align for lunar insertion',      [];...
%  'start main engine',              struct('iD',1,'thrust',20)};
%
% uE is exhaust velocity in m/s. massInitial is the mass at the start
% of the burn. hLunarOrbit is the altitude of the burn.
%
%	meas can be the state vector.
%
%	dC = LunarMissionControl gives the default data structure. This also
%	opens a GUI that shows the command list and current command that is
%	being executed.
%
%	Commands are implemented via the dSim data structure. This is compatible
% with RHSLunarMission.
%   
%--------------------------------------------------------------------------
%   Form:
%   [dC, dSim] = LunarMissionControl( action, jD, dC, dSim, meas, cList )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   action  (1,:)   'initialize', 'update', 'terminate'
%   jD      (1,1)   Julian date
%   dC      (.)     Controller data structure
%   dSim    (.)     Simulation data structure
%   meas    (.)     Measurement data structure or state vector
%                   .qECIToBody (4,1) Quaternion
%                   .rECI       (3,1) ECI position
%                   .vECI       (3,1) ECI velocity
%                   .omega      (3,1) Body rate
%                   .omegaRWA   (:,1) RWA rates                  
%   cList   {:,3}   Command list cell array
%
% 	-------
%   Outputs
%   -------
%   dC      (.)     Controller data structure
%   dSim    (.)     Simulation data structure
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%--------------------------------------------------------------------------

persistent hGUI

if( nargin < 1 )
  dC = DefaultDataStructure;
  return
end

dayToSecond = 86400;

switch lower(action)
  case 'initialize'
    dC    = Initialize( dC );
    hGUI  = InitializeGUI( jD );
    return
    
  case 'update'

    if( ~isstruct(meas) )
      meas = IdealMeasurements( meas );
    end

    % Determine if the current command is ready to submit
    dC.kCurrent   = CommandListProcessing( hGUI.jD0, cList, dC.kCurrent, jD );    
    dC.p.inertia  = dC.mass.inertia;  
    k             = dC.kCurrent;
    % Process the current command
    if( k > 0 )
      switch lower(cList{k,2})
        case 'align with a quaternion'
          dC.p.mode = 2;
          dC.p.q_desired_state = cList{k,3}.q_target;
        
        case 'align with a vector'
          dC.p.mode         = 1;
          dC.p.body_vector  = cList{k,3}.body_vector;
          dC.p.eci_vector   = cList{k,3}.eci_vector;
     
        case 'lunar orbit insertion prepare'
          dR                    = meas.rECI - dC.rMoon;
          dV                    = meas.vECI - dC.vMoon;
          [~, uECI, dC.tBurn]   = LunarOrbitInsertion( cList{k,3}.hLunarOrbit, dR, dV,  ...
                                cList{k,3}.massInitial,  cList{k,3}.uE,  cList{k,3}.thrust );
          dC.p.body_vector      = cList{k,3}.body_vector;
          dC.p.eci_vector       = uECI;
          dSim.uECI = uECI; 
        
        case 'align for lunar insertion'
          dC.p.mode         = 1;
          dC.burnStarted    = 0;

        case 'start main engine'
          dSim.thruster.thrust(cList{k,3}.iD) = cList{k,3}.thrust;
          
          if( dC.burnStarted == 0 )
            dC.tBurnStart   = jD;
            dC.burnStarted  = 1;
          end
        
          if( dayToSecond*(jD - dC.tBurnStart) > dC.tBurn )
            dSim.thruster.thrust(cList{k,3}.iD) = 0;
          end
        
        case 'stop main engine'
          dSim.thruster.thrust(cList{k,3}.iD) = 0;
      end
    end
        
    % Command list GUI
    if( k > 0 )
      hGUI = UpdateGUI( hGUI, jD, cList{k,2} );
    else
      hGUI = UpdateGUI( hGUI, jD, '' );
    end
    
    % Attitude Control
    [torqueACS, dC.p]  = PID3Axis( meas.qECIToBody, dC.p );

    % Momentum Control
    h         =  dC.mass.inertia*meas.omega;
    hRWA      =  dC.rWA.inertia*dC.rWA.u*meas.omegaRWA;
    torqueMM	=	-dC.mMGain.*QTForm( meas.qECIToBody, h + hRWA );

    % Torque distribution
    if( dC.torqueDistribution == 0 )
      dSim.rWA.torque = -torqueACS;
    else
    end
        
  case 'terminate'
    close(hGUI.fig)

end
  
  
%--------------------------------------------------------------------------
%   Default data structure
%--------------------------------------------------------------------------
function dC = DefaultDataStructure

dC.kLast  = 1;
dC.mass   = struct( 'mass',0,'cM',[0;0;0],'inertia',zeros(3,3));
dC.rWA    = struct(	'inertia',  	0.01,...
                    'fDamping',   [0;0;0],...
                    'u',          eye(3),...
                    'torque',     [0;0;0],...
                    'fCoulomb', 	[0;0;0]);
                  
dC.mMGain = [0.01;0.01;0.01];
dC.torqueDistribution = 0;

dC.p      = PID3Axis;
dC.vMoon  = [0;0;0];
dC.rMoon  = [0;0;0];
dC.tBurn  = 0;
dC.tBurnStart = 0;
dC.burnStarted = 0;

%--------------------------------------------------------------------------
%   Initialize
%--------------------------------------------------------------------------
function dC = Initialize( dC )

[dC.p.a, dC.p.b, dC.p.c, dC.p.d] = PIDMIMO( 1, 1, 0.01, 200, 0.1, dC.dT );
dC.p.inertia	= dC.mass.inertia;
dC.kCurrent   = 0;

%--------------------------------------------------------------------------
%   Ideal measurements
%--------------------------------------------------------------------------
function meas = IdealMeasurements( x )

meas.rECI       = x(1:3);
meas.vECI       = x(4:6);
meas.qECIToBody	= x(7:10);
meas.omega      = x(11:13);
meas.omegaRWA   = x(22:end);

%--------------------------------------------------------------------------
%   Update the display
%--------------------------------------------------------------------------
function hGUI = UpdateGUI( hGUI, jD, command )

jDNow = now;

dTReal = jDNow - hGUI.lastJD; % days
if (dTReal > 1/86400)

  mET       = SecToString((jD - hGUI.jD0)*86400);
  s         = sprintf('MET %s', mET); 
  set( hGUI.text, 'String', s );  

  s         = sprintf('Current Command:  %s', command); 
  set( hGUI.text2, 'String', s );  

  drawnow;

  hGUI.lastJD = jDNow;
  
end

%--------------------------------------------------------------------------
%	 Initialize the GUI
%--------------------------------------------------------------------------
function h = InitializeGUI( jD )

h.jD0 = jD;

set(0,'units','pixels')
p       = get(0,'screensize');
bottom	= p(4) - 190;
width   = 400;
h.fig   = figure('name','Lunar Mission Control','Position',[340 bottom 400 90],'NumberTitle','off',...
                      'menubar','none','resize','off','closerequestfcn',...
                     'TimeDisplay(''close'')');

v        = {'Parent',h.fig,'Units','pixels','fontunits','pixels'};

h.text   = uicontrol( v{:},'fontsize',12,...
                      'Position',[ 20 60 340 16], 'Style', 'text', 'Tag','StaticText1');
h.text2  = uicontrol( v{:},'fontsize',12,...
                      'Position',[ 20 40 340 16], 'Style', 'text', 'Tag','StaticText2');
space = 5;
x = 5;
w = (width-15)/3;
h.pause     = uicontrol( v{:}, 'Position',[ x  0    w 20],'string','Pause','CallBack','TimeCntrl(''pause'')'); x = x + w + space;
h.close     = uicontrol( v{:}, 'Position',[ x  0    w 20],'string','Stop', 'CallBack','TimeCntrl(''stop'')');  x = x + w + space;
h.plot      = uicontrol( v{:}, 'Position',[ x  0    w 20],'string','Stop and Plot', 'CallBack','TimeCntrl(''plot'')');
drawnow;

h.lastJD = now;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2020-05-08 14:41:04 -0400 (Fri, 08 May 2020) $
% $Revision: 52176 $

