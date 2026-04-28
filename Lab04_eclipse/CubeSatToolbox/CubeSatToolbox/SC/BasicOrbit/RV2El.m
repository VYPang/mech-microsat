function [el, E, f] = RV2El( r, v, mu )

%% Converts Cartesian state to Keplerian orbital elements.
%--------------------------------------------------------------------------
%   Form:
%   [el, E, f] = RV2El( r, v, mu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r               (3,1) Position vector
%   v               (3,1) Velocity vector
%   mu              (1,1) Gravitational constant
%
%   -------
%   Outputs
%   -------
%   el              (1,6) Elements vector [a,i,W,w,e,M]
%   E               (1,1) Eccentric anomaly
%   f               (1,1) True anomaly
%
%   See also: El2RV, RVFromKepler
%
%--------------------------------------------------------------------------
%   References:   Vallado, D. A. (1997.) Fundamentals of Astrodynamics and
%                 Applications. pp. 144-147.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2001, 2014 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

% Default is earth
%-----------------
if( nargin < 3 )
  mu = 3.98600436e5;
end

el = zeros(1,6);

% Error Limit
%------------
tol  = 1.e-12;

% The orbit angular momentum
%---------------------------
h    = Cross(r,v);
	
% The line of nodes
%------------------
n    = Cross( [0;0;1], h );

nMag = Mag( n );
hMag = Mag( h );
rMag = Mag( r );
vMag = Mag( v );
vSq  = vMag^2;
	
% The eccentricity vector
%------------------------
rV   = r'*v;
e    = ((vSq - mu/rMag)*r - rV*v)/mu;

% Elements vector [a,i,W,w,e,M]
	
% The eccentricity
%-----------------
el(5)  = Mag( e );

% The semimajor axis
%-------------------
z    = 0.5*vSq - mu/rMag;

% The inclination
%----------------
el(2) = acos( h(3) / hMag );

% Classification based on inclination and eccentricity
%-----------------------------------------------------
equatorial = (abs(el(2)) < tol) || (abs(el(2) - pi) < tol);
circular = el(5) < tol;
parabola = abs(el(5)-1) <= eps;

if( ~parabola )
  el(1) = -0.5*mu/z;
else
  el(1) = inf;
end

f = 0;
if( circular && equatorial ) % Circular equatorial
	f = acos( r(1)/rMag );
	if( r(2) < 0 )
		f = 2*pi - f;
	end
	
elseif( circular && ~equatorial ) % Circular inclined
  arg = n'*r/(nMag*rMag);
  f   = real(acos(arg));
  if( r(3) < 0 )
    f = 2*pi - f;
  end
  
  el(3) = acos( n(1) / nMag );
  if( n(2) < 0 )
    el(3) = 2*pi - el(3);
  end
elseif( equatorial ) % Equatorial
    
  % Argument of perigee
  %--------------------
  el(4) = acos( e(1)/ el(5) );
  if( abs(el(2)) < tol && e(2) < 0 )
    el(4) = 2*pi - el(4);
  elseif (abs(el(2) - pi) < tol) && e(2) > 0
    % retrograde: change sign of test
    el(4) = 2*pi - el(4);
  end

else
	
  % The longitude of the ascending node
  %------------------------------------
  el(3) = acos( n(1) / nMag );
  if( n(2) < 0 )
    el(3) = 2*pi - el(3);
  end
  
  % The argument of perigee
  %------------------------
  arg = n'*e / ( nMag*el(5) );
  
  if( abs(arg) > 1 )
    arg = sign(arg);
  end
  
  el(4) = acos(arg);
  
  if( e(3) < 0 && abs(e(3))>eps )
    el(4) = 2*pi - el(4);
  end
end
	
% Check to see if the orbit is eccentric
%---------------------------------------
if( el(5) > tol)
	
  % The true anomaly
  %-----------------
  arg = e'*r/(rMag*el(5));

  if( abs(arg) > 1 )
    arg = sign(arg);
  end
  f = acos(arg);

  if ( rV < 0 )
    f = 2*pi - f;
  end
	  
end
	
[el(6),E] = Nu2M(el(5),f);

if( f < 0 )
  f = f + 2*pi;
end

if ~parabola
  E = Nu2E(el(5),f);
else
  E = 0;
end


%--------------------------------------
% $Date: 2020-04-21 09:32:32 -0400 (Tue, 21 Apr 2020) $
% $Revision: 51888 $
