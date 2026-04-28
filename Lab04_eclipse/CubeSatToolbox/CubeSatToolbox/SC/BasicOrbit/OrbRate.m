function w = OrbRate( r, a, mu )

%% Compute the orbital rate from distance and semi-major axis.
%--------------------------------------------------------------------------
%   Form:
%   w = OrbRate( r, a, mu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r             (1,1)   Radius
%   a             (1,1)   Semi major axis (inf for parabola)
%   mu            (1,1)   Gravitational parameter
%
%   -------
%   Outputs
%   -------
%   w             (1,1)   Angular velocity
%
%--------------------------------------------------------------------------
%	 References:   Bates, R.B. Fundamentals of Astrodynamics, pp. 28,34.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1994 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2019.1 Update default value of mu and added demo
%--------------------------------------------------------------------------

if( nargin < 1 )
  OrbRate(7000,8000)
  return
end

if( nargin < 3 )
  mu = 3.98600436e5;
end

if( nargin < 2 )
  a = r;
end

w = sqrt(mu*(2./r - 1./a))./r;

if( nargout == 0 )
  Plot2D(r,w,'Radius (km)','Orbit Rate (rad/sec)','Orbit Rate');
  clear w
end


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2019-11-26 22:18:03 -0500 (Tue, 26 Nov 2019) $
% $Revision: 50410 $
