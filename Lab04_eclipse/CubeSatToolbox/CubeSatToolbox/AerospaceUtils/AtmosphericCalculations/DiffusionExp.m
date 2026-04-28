function x = DiffusionExp( z, tX, t90, tE )

%% Computes the diffusion exponent.
%--------------------------------------------------------------------------
%   Form:
%   x = DiffusionExp( z, tX, t90, tE )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   z          (1,1)   Height
%   tX         (1,1)   Inflection point temperature (deg-K at altitude = 125 km)
%   t90        (1,1)   Assumed temperature at 90km altitude (deg-K)
%   tE         (1,1)   Exospheric temperature (deg-K) 
%   
%   -------
%   Outputs
%   -------
%   x          (1,1)   Diffusion Exponent
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	  Copyright (c) 1999 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

rE  = 6.356766e3;   % Earth radius (km)
R   = 8.31432;      % universal gas constant (J/mol-deg-K)
g0  = 9.80665;		  % Gravitation acceleration (m/s^2)

g = g0./(1+z/rE).^2;

% Temperature at geometric altitude levels (deg-K)
%-------------------------------------------------
t1      = 1.9*(tX-t90)/35;
dZ      = z - 125;

k = find( dZ < 0 );
if( ~isempty(k) )
  t4    = 3*( tX - t90 - 2*t1*35/3 )/35^4;
  t3    = 4*35*t4/3 - t1/(3*35^2);
  tZ(k) = tX + t1.*dZ(k) + t3.*dZ(k).^3 + t4*dZ(k).^4; % (A-16)
end

k = find( dZ >= 0 );
if( ~isempty(k) )
  a2    = 2*(tE-tX)/pi;
  tZ(k) = tX + a2*atan( (t1.*dZ(k).*(1+(4.5e-6)*dZ(k).^2.5))./a2 ); % (A-17)
end

x = -(g)./(R*tZ);


%--------------------------------------
% $Date: 2019-09-09 23:21:42 -0400 (Mon, 09 Sep 2019) $
% $Revision: 49752 $
