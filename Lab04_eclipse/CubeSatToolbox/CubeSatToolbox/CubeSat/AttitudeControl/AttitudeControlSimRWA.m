function data = AttitudeControlSimRWA( qEB0, wB0, qEBDes, t, inrBody, inrWhl, maxRate, control )

%% Simulate a rigid body with 3-axis attitude control.
%
%--------------------------------------------------------------------------
%   Form:
%   data = AttitudeControlSimRWA( qEB0, wB0, qEBDes, t, inrBody, inrWhl, ...
%   maxRate, control );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   qEB0       (4,1)    Initial ECI to Body quaternion
%   qEBDes     (4,:)    Desired ECI to Body quaternion over time
%   t          (1,:)    Time vector (sec)
%   inrBody    (3,3)    Inertia matrix for the rigid body
%   inrWhl     (3,1)    Wheel inertias. Enter a scalar if all the same.
%   maxRate    (1,1)    Maximum slew rate (rad/s)
%   control     (.)     Control data structure with fields:
%                        .a      A matrix of discretestate space controller
%                        .b      B matrix of discretestate space controller
%                        .c      C matrix of discretestate space controller
%                        .d      D matrix of discretestate space controller
%                        .tSamp  Sampling time (sec)
%                 
%   -------
%   Outputs
%   -------
%   data        (.)     Data structure with fields:
%                       .t      (1,:)    Time vector (intervals at tSamp)
%                       .qEB    (4,:)    ECI to Body quaternion
%                       .wB     (3,:)    Body rate (rad/s)
%                       .torque (3,:)    Body torque (Nm)
%                       .wW     (3,:)    Wheel rates (rad/s)
%                       .power  (3,:)    Required power draw (Watts)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 8.
%--------------------------------------------------------------------------


% Demo
%-----
if( nargin < 1 )
   qEB0 = [1;0;0;0];
   wB0  = [0;0;0];
   t = linspace(0,100,300);
   qEBDes = AU2Q(2*pi*t/40,[0;1;0]);
   qEBDes(:,t>40) = repmat(qEBDes(:,find(t<=40,1,'last')),1,length(find(t>40)));
   inrBody = [.3 0 0; 0 .3 0; 0 0 .2];
   inrWhl = .01;
   maxRate = 8*pi/180;
   
   % Design controller
   %------------------
   zeta = 0.7071; % damping ratio (critically damped)
   omega = .03;   % natural frequency
   tauInt = 100;  % integrator time constant (sec)
   omegaR = 2;    % derivative roll-off
   
   % Calculate state-space control system matrices
   %----------------------------------------------
   [ak, bk, ck, dk] = PIDMIMO( 1, zeta, omega, tauInt, omegaR);
   tSamp = 0.125;
   [akd,bkd] = C2DelZOH(ak,bk,tSamp);
   control.a = akd;
   control.b = bkd;
   control.c = ck;
   control.d = dk;
   control.tSamp = tSamp;
   AttitudeControlSimRWA( qEB0, wB0, qEBDes, t, inrBody, inrWhl, maxRate, control );
   return;
end


% controller data
akd   = control.a;
bkd   = control.b;
ck    = control.c;
dk    = control.d;
tSamp = control.tSamp;

% regular spaced time vector
time = 0:tSamp:t(end);

% desired quaternion over this time vector
qEBDes = interp1(t,qEBDes',time)';

invInertia = inv(inrBody);

trqDist = [0;0;0];

% Simulation
%-----------
x = [qEB0;wB0];

% max angle change each time step
stepLimit   = maxRate*tSamp;

if( size(inrWhl,1)==3 )
   inrWhl = diag(inrWhl);
end
wheelGain = -inv(inrWhl)*inrBody;

% calculate LVLH quaternion a priori
xRoll = [0;0];
xPitch= [0;0];
xYaw  = [0;0];
xPlot = zeros(7,length(t));
wW    = zeros(3,length(t));
trq   = zeros(3,length(t));
angleError = trq;
qECIToTargetOld = x;
for k = 1:length(time)
   xPlot(:,k) = x;
      acc = zeros(3,1);

      % Rename for clarity
      qECIToBody = x(1:4);
      
      % Compute the change in target quaternion
      %----------------------------------------
      deltaQ     = QMult(  QPose( qECIToTargetOld ), qEBDes(:,k) );
      [angle, u] = Q2AU( deltaQ );

      % Change the target by no more than stepLimit
      %--------------------------------------------
      if( abs(angle) >  stepLimit )
         deltaQ       = AU2Q( sign(angle)*stepLimit, u );
         qECIToTarget = QMult( qECIToTargetOld, deltaQ );
      else
         qECIToTarget = qEBDes(:,k);
      end

      % memory
      qECIToTargetOld = qECIToTarget;

      % Compute the body-to-target quaternion
      qBodyToTarget = QMult( QPose(qECIToBody), qECIToTarget );
      if( qBodyToTarget(1) < 0 )
         qBodyToTarget = -qBodyToTarget;
      end
      angleError(:,k) = 2*qBodyToTarget(2:4); % + randn(3,1)*noiseSigma;

      % The delta form of the controller
      acc(1) =          ck*xRoll  + dk*angleError(1,k);
      xRoll  = xRoll  + akd*xRoll  + bkd*angleError(1,k);

      acc(2) =          ck*xPitch + dk*angleError(2,k);
      xPitch = xPitch + akd*xPitch + bkd*angleError(2,k);

      acc(3) =         ck*xYaw   + dk*angleError(3,k);
      xYaw   = xYaw  + akd*xYaw   + bkd*angleError(3,k);

      tExt  = -inrBody*acc;

   % This is the numerical integration of the dynamics:
   x = RK4( @FRB, x, tSamp, time(k), inrBody, invInertia, tExt+trqDist );
   trq(:,k) = tExt;
   wW(:,k)  = wheelGain*x(5:7);
end

data.t = time;
data.qEB = xPlot(1:4,:);
data.wB = xPlot(5:7,:);
data.torque = trq;
data.wW = wW;
data.power = sum(abs(trq.*data.wW));

% Default output
%---------------
if( nargout==0 )
   figure('name','Quaternion')
   plot(time,xPlot(1:4,:)), xlabel('Time (s)'), legend('qS','qX','qY','qZ'), title('Quaternion'), grid on, zoom on
   hold on
   plot(time,qEBDes,'--')
   figure('name','Body rates')
   plot(time,xPlot(5:7,:)*180/pi), xlabel('Time (s)'), legend('wX','wY','wZ'), title('Body rates [deg/s]'), grid on, zoom on
   figure('name','Control Torques')
   plot(time,trq), xlabel('Time (s)'), legend('Tx','Ty','Tz'), title('Control Torques [Nm]'), grid on, zoom on
   figure('name','Angular Error')
   plot(time,angleError*180/pi), xlabel('Time (s)'), legend('eX','eY','eZ'), title('Angular Error Input to Control Law [deg]'), grid on, zoom on
end



%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
