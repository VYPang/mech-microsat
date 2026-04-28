function [xH,m] = DeltaElem2Hills( el0, dEl, J2 )

%% Computes the Hills frame state from orbital element differences and 
%   reference orbital elements.
%--------------------------------------------------------------------------
%   Usage:
%   [xH,m] = DeltaElem2Hills( el0, dEl, J2 );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el0           (1,6)  reference orbital elements:    [a,th,i,q1,q2,W]
%   dEl           (:,6)  orbital element differences:   [a,th,i,q1,q2,W]
%   J2             (1)   size of the J2 perturbation
%
%   -------
%   Outputs
%   -------
%   xH            (6,:)  relative position and velocity in Hills frame [km; km/s]
%   m             (6,6)  transformation matrix 
%   
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  References:     Joseph B. Mueller, Princeton Satellite Systems
%                    Terry Alfriend, Texas A&M
%--------------------------------------------------------------------------
%    Copyright (c) 2002 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%   2019.1 Update default value of mu
%--------------------------------------------------------------------------

if( nargin < 1 )
   RunDemo;
   return;
end

if( nargin < 3 )
   J2 = 0;
end

% Constants
%----------
mu = 3.98600436e5;                                    % gravitational constant [km^3/s^2]
Re = 6378.137;                                       % equatorial radius of the earth [km]

% Orbit parameters
%-----------------
a  = el0(1);                                          % semi-major axis [km]
th = el0(2);                                          % argument of latitude [rad]
i  = el0(3);                                          % inclination [rad]
q1 = el0(4);                                          % e*cos(w)
q2 = el0(5);                                          % e*sin(w)
e  = sqrt(q1*q1 + q2*q2);                                   % eccentricity
p  = a*(1-e^2);                                       % semi-latus rectum [km]
R  = p/(1 + q1*cos(th) + q2*sin(th));                 % magnitude of radius vector [km]

% Initial repeated terms
%-----------------------
sqrtMu_p = sqrt(mu/p);
sinTh = sin( th );
cosTh = cos( th );

% Velocities
%-----------
Vt = sqrtMu_p * ( 1 + q1*cosTh + q2*sinTh );    % tangential velocity
Vr = sqrtMu_p * ( q1*sinTh - q2*cosTh );        % radial velocity

% More Repeated Terms
%--------------------
aInv  = 1 / a;
pInv  = 1 / p;
RInv  = 1 / R;
R_a   = R * aInv;
R_p   = R * pInv;
Vr_a  = Vr * aInv;
Vt_a  = Vt * aInv;
aVr_p = Vr * a * pInv;
aVt_p = Vt * a * pInv;
cosI  = cos( i );
sinI  = sin( i );
cosI2 = cosI*cosI;
sinI2 = sinI*sinI;
sinTh2 = sinTh*sinTh;

alpha = 3*J2*Re*Re;

% Transformation Matrix
%----------------------
m = zeros(6,6);

m(1,1) = R_a;
m(1,2) = R*Vr/Vt; %R*R_p * (q1*sinTh-q2*cosTh)
m(1,4) = -R_p * (2*a*q1 + R*cosTh);
m(1,5) = -R_p * (2*a*q2 + R*sinTh);

m(2,2) = R;
m(2,6) = R * cosI;

m(3,3) = R * sinTh;
m(3,6) = -R * sinI * cosTh;

m(4,1) = -0.5 * Vr_a;
m(4,2) = sqrtMu_p*(p*RInv - 1);
m(4,4) = aVr_p * q1 + sqrtMu_p * sinTh;
m(4,5) = aVr_p * q2 - sqrtMu_p * cosTh;

m(5,1) = -1.5 * Vt_a;
m(5,2) = -Vr;
m(5,3) = -alpha*(Vt*sinI*cosI*sinTh2*pInv*RInv);
m(5,4) = 3 * aVt_p * q1 + 2 * sqrtMu_p * cosTh;
m(5,5) = 3 * aVt_p * q2 + 2 * sqrtMu_p * sinTh;
m(5,6) = Vr * cosI + alpha*pInv*RInv*( Vt*sinI2*cosI*sinTh*cosTh );

m(6,2) = alpha*pInv*RInv*Vt*sinI*cosI*sinTh;
m(6,3) = Vt * cosTh + Vr * sinTh;
m(6,6) = (Vt * sinTh - Vr * cosTh) * sinI + alpha*Vt*sinI*cosI2*sinTh*pInv*RInv;

xH = m * transpose(dEl);

%-----------------------------------------
% RunDemo
%-----------------------------------------
function RunDemo

e   = 1e-3;
w   = 2*pi/3;
el0 = [7000, pi/3, pi/4, e*cos(w), e*sin(w), pi/6];
n   = 2000;
dEls = zeros(6,n);
err = dEls;
for i=1:n,
   sgn  = sign(rand-.5);
   dEl0 = [sgn*(rand)*1e-3, (rand-.5)*1e-5, (rand-.5)*1e-6, (rand-.5)*1e-6, (rand-.5)*1e-6, (rand-.5)*1e-6]*1e1;
   xH   = DeltaElem2Hills( el0, dEl0 ); 
   dEl  = Hills2DeltaElem( el0, xH ); 
   err(:,i) = transpose(dEl0-dEl);
   dEls(:,i) = transpose(dEl0);
end

% plot element difference errors
figure, 
subplot(321),
plot(1:n,err(1,:)*1e6,'linewidth',2)
ylabel('\Deltaa\newline[mm]','rotation',0), grid on, zoom on
title('Element Difference Errors After Conversions')
subplot(322),
plot(1:n,err(2,:),'linewidth',2)
ylabel('\Delta\theta\newline[rad]','rotation',0), grid on, zoom on
subplot(323),
plot(1:n,err(3,:),'linewidth',2)
ylabel('\Deltai\newline[rad]','rotation',0), grid on, zoom on
%figure,
subplot(324),
plot(1:n,err(4,:),'linewidth',2)
ylabel('\Deltaq_1','rotation',0), grid on, zoom on
subplot(325),
plot(1:n,err(5,:),'linewidth',2)
ylabel('\Deltaq_2','rotation',0), grid on, zoom on
subplot(326),
plot(1:n,err(6,:),'linewidth',2)
ylabel('\Delta\Omega\newline[rad]','rotation',0), grid on, zoom on

% plot percent error
figure, 
subplot(321),
plot(1:n,err(1,:)./dEls(1,:)*100,'linewidth',2)
ylabel('\Deltaa','rotation',0), grid on, zoom on
title('Percent Error After Conversions')
subplot(322),
plot(1:n,err(2,:)./dEls(2,:)*100,'linewidth',2)
ylabel('\Delta\theta','rotation',0), grid on, zoom on
subplot(323),
plot(1:n,err(3,:)./dEls(3,:)*100,'linewidth',2)
ylabel('\Deltai','rotation',0), grid on, zoom on
subplot(324),
plot(1:n,err(4,:)./dEls(4,:)*100,'linewidth',2)
ylabel('\Deltaq_1','rotation',0), grid on, zoom on
subplot(325),
plot(1:n,err(5,:)./dEls(5,:)*100,'linewidth',2)
ylabel('\Deltaq_2','rotation',0), grid on, zoom on
subplot(326),
plot(1:n,err(6,:)./dEls(6,:)*100,'linewidth',2)
ylabel('\Delta\Omega','rotation',0), grid on, zoom on



%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2020-05-29 16:43:18 -0400 (Fri, 29 May 2020) $
% $Revision: 52566 $
