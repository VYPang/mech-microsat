function [dEl,m] = Hills2DeltaElem( el0, xH, J2 )

%% Computes the orbital element differences from the Hills frame state and the
%   reference orbital elements.
%
%   Since version 7.
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el0           (1,6)  chief orbital elements         [a,th,i,q1,q2,W]
%   xH            (6,:)  relative position and velocity in Hills frame [km; km/s]
%   J2             (1)   size of the J2 perturbation
%
%   -------
%   Outputs
%   -------
%   dEl           (:,6)  orbital element differences:   [a,th,i,q1,q2,W]
%   m             (6,6)  transformation matrix 
%   
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  References:     Joseph B. Mueller, Princeton Satellite Systems
%                    Terry Alfriend, Texas A&M
%--------------------------------------------------------------------------
%    Copyright (c) 2003 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------

if( nargin < 1 )
   RunDemo;
   return;
end

if( nargin < 3 )
   J2 = 0;
end

tol = 1e-12;

% Constants
%----------
mu = 398600.44;                                       % gravitational constant [km^3/s^2]
Re = 6378.137;                                         % equatorial radius of the earth [km]

% Orbit parameters
%-----------------
a  = el0(1);                                           % semi-major axis [km]
th = el0(2);                                           % argument of latitude [rad]
i  = el0(3);                                           % inclination [rad]
q1 = el0(4);                                           % e*cos(w)
q2 = el0(5);                                           % e*sin(w)
e  = sqrt(q1*q1 + q2*q2);                              % eccentricity
p  = a*(1-e^2);                                       % semi-latus rectum [km]
R  = p/(1 + q1*cos(th) + q2*sin(th));                 % magnitude of radius vector [km]

% Initial repeated terms
%-----------------------
pInv  = 1 / p;
sinTh = sin( th );
cosTh = cos( th );
sqrtMu_p = sqrt(mu*pInv);

% Velocities
%-----------
Vt = sqrtMu_p * ( 1 + q1*cosTh + q2*sinTh );     % tangential velocity
Vr = sqrtMu_p * ( q1*sinTh - q2*cosTh );         % radial velocity

% More Repeated Terms
%--------------------
aInv  = 1 / a;
RInv  = 1 / R;
RInv2 = RInv*RInv;
RInv3 = RInv*RInv2;
R_a   = R * aInv;
R_p   = R * pInv;
Vr_a  = Vr * aInv;
Vt_a  = Vt * aInv;
aVr_p = Vr * a * pInv;
aVt_p = Vt * a * pInv;
Vr2   = Vr*Vr;
Vt2   = Vt*Vt;
VtInv = 1 / Vt;
cosI  = cos( i );
sinI  = sin( i );
cosI2 = cosI*cosI;
sinI2 = sinI*sinI;
cosTh2 = cosTh*cosTh;
sinTh2 = sinTh*sinTh;
muInv  = 1 / mu;
sqrtP_mu = sqrt(p*muInv);

if( abs(i) > tol )
   cotI   = cot( i );
   cscI   = csc( i );
else
   cotI   = 0;
   cscI   = 0;
end

Ec    = -0.5*mu*aInv;
alpha = 3*J2*Re*Re;
sigma = -0.5*mu*R*R*R_p*Vt_a*sinI;
EcInv = 1 / Ec;

% Transformation Matrix
%----------------------
m = zeros(6,6);

m(1,1) = (EcInv*RInv) * ( (mu*RInv)*(3*a-2*R) - a*(2*Vr2 + 3*Vt2) );
m(1,2) = -(Vr*EcInv) * ( 2*aVt_p - Vt*R_p - a*RInv*VtInv*( Vr2 + 2*Vt2 ) );
m(1,3) = alpha * ( sinI*cosI*sinTh*EcInv*pInv*RInv2 ) * ( (mu*RInv)*(2*a-R) - a*(Vr2 + 2*Vt2) );
m(1,4) = -a*Vr*EcInv;
m(1,5) =   (R*EcInv) * ( 2*aVt_p - Vt*R_p - a*RInv*VtInv*( Vr2 + 2*Vt2 ) );

m(2,2) = RInv + alpha * ( cosI2*sinTh2*pInv*RInv2 );
m(2,3) = RInv*VtInv*( Vr*sinTh + Vt*cosTh )*cotI;
m(2,6) = -sinTh*VtInv*cotI;

m(3,2) = -alpha*( sinI*cosI*sinTh*cosTh*pInv*RInv2 );
m(3,3) = (Vt*sinTh - Vr*cosTh)*RInv*VtInv;
m(3,6) = cosTh*VtInv;

m(4,1) = RInv2*VtInv*p*( 2*Vr*sinTh + 3*Vt*cosTh );
m(4,2) = -muInv*( (Vr2+Vt2)*sinTh + Vr*Vt*cosTh ) + RInv*sinTh + alpha*(VtInv*VtInv*RInv3*cosI2*sinTh2)*( Vt*(Vr*cosTh - Vt*sinTh) + RInv*mu*sinTh );
m(4,3) = ( muInv*( (Vr2-Vt2)*sinTh*cosTh + Vr*Vt*(cosTh2-sinTh2) ) + RInv*VtInv*sinTh*(Vr*sinTh + Vt*cosTh) )*cotI + alpha*(VtInv*RInv3*sinI*cosI*sinTh)*( Vr*sinTh + 2*Vt*cosTh );
m(4,4) = sqrtP_mu*sinTh;
m(4,5) = 2*sqrtP_mu*cosTh + R*Vr*sinTh*muInv;
m(4,6) = -( muInv*( R*sinTh*(Vr*cosTh - Vt*sinTh) ) + VtInv*sinTh2 )*cotI;

m(5,1) = -p*RInv2*VtInv*( 2*Vr*cosTh - 3*Vt*sinTh );
m(5,2) = muInv*( (Vr2+Vt2)*cosTh - Vr*Vt*sinTh ) - RInv*cosTh + alpha*(VtInv*VtInv*RInv3*cosI2*sinTh2)*( Vt*(Vr*sinTh + Vt*cosTh) - RInv*mu*cosTh );
m(5,3) = ( muInv*power( (Vr*sinTh+Vt*cosTh),2 ) - RInv*VtInv*cosTh*(Vr*sinTh + Vt*cosTh) )*cotI - alpha*(VtInv*RInv3*sinI*cosI*sinTh)*( Vr*cosTh - 2*Vt*sinTh );
m(5,4) = -sqrtP_mu*cosTh;
m(5,5) = 2*sqrtP_mu*sinTh - R*Vr*cosTh*muInv;
m(5,6) = -( muInv*( R*sinTh*(Vr*sinTh + Vt*cosTh) ) - VtInv*sinTh*cosTh )*cotI;

m(6,2) = -alpha*( pInv*RInv2*cosI*sinTh2 );
m(6,3) = -RInv*VtInv*cscI*( Vr*sinTh + Vt*cosTh );
m(6,6) = VtInv*cscI*sinTh;

dEl = transpose( m * xH );

%-----------------------------------------
% Run the Demo
%-----------------------------------------
function RunDemo;

e   = 1e-3;
w   = 2*pi/3;
el0 = [7000, pi/3, pi/4, e*cos(w), e*sin(w), pi/6];
n   = 2000;
for i=1:n,
   xH = [rand(3,1)-.5*ones(3,1); (rand(3,1)-.5*ones(3,1))*1e-5]; 
   dEl = Hills2DeltaElem( el0, xH ); 
   xH1 = DeltaElem2Hills( el0, dEl ); 
   err(:,i) = (xH1-xH)*1e6;
   xHs(:,i) = xH*1e6;
end

% plot rel pos / vel error
figure, 
subplot(211),
plot(1:n,err(1:3,:),'linewidth',2)
ylabel('\Deltar\newline[mm]','rotation',0)
legend('x','y','z')
grid on, zoom on
title('Relative Position and Velocity Error After Conversions')
subplot(212),
plot(1:n,err(4:6,:),'linewidth',2)
ylabel('\Deltav\newline[mm/s]','rotation',0)
grid on, zoom on

% plot percent error
figure, 
subplot(211),
plot(1:n,err(1:3,:)./xHs(1:3,:)*100,'linewidth',2)
ylabel('\Deltar','rotation',0)
legend('x','y','z')
grid on, zoom on
title('Percent Error After Conversions')
subplot(212),
plot(1:n,err(4:6,:)./xHs(1:3,:)*100,'linewidth',2)
ylabel('\Deltav','rotation',0)
grid on, zoom on



%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-09 15:16:37 -0400 (Tue, 09 May 2017) $
% $Revision: 44523 $
