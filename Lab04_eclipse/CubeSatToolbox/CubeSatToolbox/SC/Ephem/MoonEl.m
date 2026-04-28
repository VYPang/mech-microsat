function el = MoonEl( jD )

%% Computes the moon orbital elements with respect to the earth inertial frame.
% These elements are only valid for short term use. Use PlanetPosJPL
% for more accurate positions and velocities.
%--------------------------------------------------------------------------
%   Form:
%   el = MoonEl( jD )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   jD            (1,1)  Julian Date
%
%   -------
%   Outputs
%   -------
%   el            (1,6)  Keplerian elements [a,i,L,w,e,M] (km,rad)
%
%--------------------------------------------------------------------------
%   Reference: Montenbruck, O., T. Fleger, "Astronomy on the Personal 
%               Computer", Springer-Verlag, p 155.
%               http://ssd.jpl.nasa.gov/?sat_elem
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1996 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%--------------------------------------------------------------------------

% Constants
%----------
degToRad  = pi/180;

% Julian centuries from J2000.0
%------------------------------
T         = JD2T( jD );

% Orbital elements
%-----------------
a         = 384400;
i         =  5.15;
L         = 125.04334 - 1934.13793*T;
w         = 318.31 - 38996.8488*T;
e         = 0.0554;
M         = 134.96292 + 477198.86753*T;
el        = [a i mod(L,360) mod(w,180) e mod(M,360)];

% Convert to radians
%-------------------
kA        = [2 3 4 6];
el(kA)    = el(kA)*degToRad;
 

%--------------------------------------
% $Date: 2019-11-01 22:48:21 -0400 (Fri, 01 Nov 2019) $
% $Revision: 50200 $
  
