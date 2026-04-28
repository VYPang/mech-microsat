function x = BaromExp( z, tX, t90 )

%% Computes the barometric exponent.
% This is used by AtmJ70 by a quadrature routine.
%--------------------------------------------------------------------------
%   Form:
%   x = BaromExp( z, tX, t90 )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   z          (1,1)   Height
%   tX         (1,1)   Inflection point temperature (deg-K at altitude = 125 km)
%   t90        (1,1)   Assumed temperature at 90km altitude (deg-K)
%
%   -------
%   Outputs
%   -------
%   x          (1,1)   Barometric Exponent
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

rE  = 6.356766e3; % Earth radius (km)
R   = 8.31432;    % universal gas constant (J/mol-deg-K)
g0  = 9.80665;    % Gravitation acceleration (m/s^2)

g   = g0./(1+z/rE).^2;

% Temperature at geometric altitude levels (deg-K)
%-------------------------------------------------
t1    = 1.9*(tX-t90)/35;
dZ    = z - 125;

t4    = 3*( tX - t90 - 2*t1*35/3 )/35^4;
t3    = 4*35*t4/3 - t1/(3*35^2);
tZ	  = tX + (t1 + (t3 + t4*dZ).*dZ.^2).*dZ; % (A-16)

% Mean molecular mass (unitless)
%-------------------------------
dZ     = z - 100;
		   
eM  = 28.15204 - (0.085586 - (1.2840e-4 - (1.0056e-5 + (1.0210e-5 ...
           - (1.5044e-6 + 9.9826e-8*dZ).*dZ).*dZ).*dZ).*dZ).*dZ; % (A-18)
		   
x = -(eM.*g)./(R*tZ);

%--------------------------------------
% $Date: 2019-09-09 23:21:42 -0400 (Mon, 09 Sep 2019) $
% $Revision: 49752 $
