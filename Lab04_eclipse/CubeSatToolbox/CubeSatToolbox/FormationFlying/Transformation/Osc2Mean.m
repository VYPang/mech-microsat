function [el_mean,el_LP,el_SP1,el_SP2] = Osc2Mean(el_osc,J2)

%% Transforms osculating orbital elements to mean orbital elements.
%
%--------------------------------------------------------------------------
%   Form:
%   el_mean = Osc2Mean(el_osc,J2);
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el_osc           (1,6)    osculating orbital elements
%   J2               (1,1)    Magnitude of J2 term
%
%   -------
%   Outputs
%   -------
%   el_mean          (1,6)    mean orbital elements
%
%--------------------------------------------------------------------------
%  References:  Terry Alfriend, Texas A&M University
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%--------------------------------------------------------------------------

coef = -J2;
Re   = 6378.14;   % earth radius [km]

% Osculating orbital elements
%----------------------------
a  = el_osc(1,1);
th = el_osc(1,2);
i  = el_osc(1,3);
q1 = el_osc(1,4);
q2 = el_osc(1,5);

% Repeated Terms
%---------------
cosI    = cos(i);
sinI    = sin(i);
cosTh   = cos(th);
sinTh   = sin(th);
cosI2   = cosI*cosI;
sinI2   = sinI*sinI;
sin2I   = sin(2*i);
cos2Th  = cos(2*th);
sin2Th  = sin(2*th);
cos3Th  = cos(3*th);
sin3Th  = sin(3*th);
chi     = (1 - 5*cosI2);
aInv    = Re/a;
a2Inv   = aInv*aInv;
q1SinTh = q1*sinTh;
q2SinTh = q2*sinTh;
q1CosTh = q1*cosTh;
q2CosTh = q2*cosTh;
e       = sqrt(q1^2+q2^2);

% Long Period Terms
%------------------
aLP   = 0;
thLP  = -0.125*a2Inv*sinI2*( 1 - 10*chi*cosI2 )*( q1SinTh + q2CosTh + 0.25*sin2Th*e );
iLP   = 0;
q1LP  = -0.0625*a2Inv*q1*sinI2*( 1 - 10*chi*cosI2 );
q2LP  =  0.0625*a2Inv*q2*sinI2*( 1 - 10*chi*cosI2 );
OmLP  = 0;

% First Order Short Period Terms
%-------------------------------
aSP1   = 1.5*aInv*( 1 - 3*cosI2 )*( q1CosTh + q2SinTh );
thSP1  = 0.75*a2Inv*( 1 - 5*cosI2 )*( q1SinTh - q2CosTh ); % corrected factor of 3
iSP1   = 0;
q1SP1  = 0.375*a2Inv*( 1 - 3*cosI2 )*( 2*cosTh + 2*q1 + q1*cos2Th + q2*sin2Th );
q2SP1  = 0.375*a2Inv*( 1 - 3*cosI2 )*( 2*sinTh + 2*q2 + q1*sin2Th - q2*cos2Th );
OmSP1  = 1.5*a2Inv*( cosI )*( q1SinTh - q2CosTh ); % corrected factor of 3

% Second Order Short Period Terms
%--------------------------------
aSP2    = -1.5*aInv*( sinI2 )*( 1 + 3*q1CosTh + 3*q2SinTh )*( cos2Th );

lamSP2  = -0.125*sinI2*a2Inv*( 6*cos2Th*(q1SinTh-q2CosTh) + 3*(q1SinTh+q2CosTh) + (q1*sin3Th-q2*cos3Th) ) ...
   - 0.125*(3-5*cosI2)*a2Inv*( 3*(q1SinTh+q2CosTh) +3*sin2Th + (q1*sin3Th-q2*cos3Th) );

thSP2   = lamSP2 - 0.0625*sinI2*a2Inv*( 7*(q1SinTh+q2CosTh) - 16*sin2Th - 13*(q1*sin3Th-q2*cos3Th) );

iSP2    = -0.125*a2Inv*sin2I*( 3*cos2Th + 3*( q1CosTh - q2SinTh ) + ( q1*cos3Th + q2*sin3Th ) );
q1SP2a  =  3*q2*( 3 - 5*cosI2 )*sin2Th;
q1SP2b  =  sinI2 * ( 3*cosTh - cos3Th );
q1SP2c  = -3*sinI2*cos2Th*( 4*cosTh + 5*q1 + 3*( q1*cos2Th + q2*sin2Th ) );
q1SP2   =  0.125*a2Inv*( q1SP2a + q1SP2b + q1SP2c );
q2SP2a  = -3*q1*( 3 - 5*cosI2 )*sin2Th;
q2SP2b  = -sinI2 * ( 3*sinTh + sin3Th );
q2SP2c  = -3*sinI2*cos2Th*( 4*sinTh + 5*q2 + 3*( q1*sin2Th - q2*cos2Th ) );
q2SP2   =  0.125*a2Inv*( q2SP2a + q2SP2b + q2SP2c );
OmSP2   = -0.25*a2Inv*cosI*( 3*sin2Th + 3*( q1SinTh + q2CosTh ) + ( q1*sin3Th - q2*cos3Th ) );

% Initialize vectors
%-------------------
el_LP   = zeros(1,6);
el_SP1  = zeros(1,6);
el_SP2  = zeros(1,6);

% vectors
%--------
el_LP(1,1) = aLP*Re;
el_LP(1,2) = thLP;
el_LP(1,3) = iLP;
el_LP(1,4) = q1LP;
el_LP(1,5) = q2LP;
el_LP(1,6) = OmLP;

el_SP1(1,1) = aSP1*Re;
el_SP1(1,2) = thSP1;
el_SP1(1,3) = iSP1;
el_SP1(1,4) = q1SP1;
el_SP1(1,5) = q2SP1;
el_SP1(1,6) = OmSP1;

el_SP2(1,1) = aSP2*Re;
el_SP2(1,2) = thSP2;
el_SP2(1,3) = iSP2;
el_SP2(1,4) = q1SP2;
el_SP2(1,5) = q2SP2;
el_SP2(1,6) = OmSP2;

% mean elements
%--------------
el_mean = el_osc - coef*( el_LP + el_SP1 + el_SP2 );



%--------------------------------------
% $Date: 2019-09-13 11:11:21 -0400 (Fri, 13 Sep 2019) $
% $Revision: 49790 $
