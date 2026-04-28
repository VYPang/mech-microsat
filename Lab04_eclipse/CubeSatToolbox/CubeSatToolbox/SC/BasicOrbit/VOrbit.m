function v = VOrbit( r, a, mu )

%% Computes the orbital velocity.
%
%   If you don't enter a, you will get v for a circular orbit.
%
%   Either a or r can be scalars. It will plot v against whichever is a 
%   vector.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   v = VOrbit( r, a, mu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r             (1,:)   Radius
%   a             (1,:)   Semi major axis (inf for parabola)
%   mu            (1,1)   Gravitational parameter [default is Earth]
%
%   -------
%   Outputs
%   -------
%   v             (1,:)   Velocity
%
%--------------------------------------------------------------------------
%   References:	Bates, R.B. Fundamentals of Astrodynamics, pp. 28,34.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993, 2013 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    VOrbit(linspace(7000,10000),7500);
    return;
end

if( nargin < 2 )
	a = [];
end

% Default is earth
%-----------------
if( nargin < 3 )
  mu = 3.98600436e5;
end

% Default is circular orbit
%--------------------------
if( isempty(a) )
	a = r;
end

if (a == inf)
  v = sqrt(2*mu./r);
else
  i = find(2./r < 1./a, 1);
  if( ~isempty(i) )
    error('PSS:VOrbit:error','2/r must be greater than 1/a')
  end  
  v = sqrt(mu*(2./r - 1./a));
end

% If no outputs are specified, plot
%----------------------------------
if( nargout == 0 && length(r) > 1 )
    if( length(r) > 1 )
        Plot2D(r,v,'Radius','Velocity','VOrbit')
    else
        Plot2D(a,v,'Semi-major Axis','Velocity','VOrbit')
    end

    clear v;
end

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 16:08:09 -0400 (Thu, 11 May 2017) $
% $Revision: 44568 $
