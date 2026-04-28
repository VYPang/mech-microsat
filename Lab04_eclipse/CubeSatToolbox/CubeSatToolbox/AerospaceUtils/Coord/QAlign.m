function [q,rotAngle,sepAngle] = QAlign( q0, uBAxis, uBVec, uITarget )

%% Rotate about a body axis to align a body vector with an inertial vector.
%
% 1. Begin with an initial quaternion
%
% 2. Rotate about a body-frame axis to align a body-frame vector with an 
%   inertial target vector
%
% 3. Return the new quaternion
%
% Will generate a plot if no outputs are requested.
%--------------------------------------------------------------------------
%   Form:
%   [q,rotAngle,sepAngle] = QAlign( q0, uBAxis, uBVec, uITarget );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   q0          (4,:) Beginning inertial to body quaternion
%   uBAxis      (3,1) Body-frame axis to rotate about
%   uBVec       (3,1) Body-frame vector to align
%   uITarget    (3,:) Inertial-frame vector to point at
%
%   -------
%   Outputs
%   -------
%   q           (4,:) Resulting Inertial-to-Body quaternion after rotation
%   rotAngle    (1,:) Angle of rotation [rad]
%   sepAngle    (1,:) Separation angle between body vector and target [rad]
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 2007 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
% Since version 7 (2007)
%--------------------------------------------------------------------------

[qRot,ub,rotAngle,sepAngle] = QRotateToAlign( uBAxis, uBVec, QForm(q0,uITarget) );
q = QMult( q0, QPose(qRot) );
   
if( nargout==0 )
   uIVec = QTForm(q,uBVec);
   nT    = size(q0,2);
   angle = zeros(1,nT);
   for i=1:nT
      angle(i) = acos( uIVec(:,i)'*uITarget(:,i) );
   end
   NewFig('QAlign');
   plot(1:nT,[angle;sepAngle]*180/pi), grid on, zoom on
   title('Separation Angle')
   ylabel('[deg]')
   xlabel('Index')
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2016-03-18 15:25:16 -0400 (Fri, 18 Mar 2016) $
% $Revision: 41949 $
