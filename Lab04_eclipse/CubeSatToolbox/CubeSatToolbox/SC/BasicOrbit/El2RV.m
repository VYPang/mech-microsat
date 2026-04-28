function [r, v] = El2RV( el, tol, mu )

%% Converts orbital elements to r and v for an elliptic orbit.
% Type El2RV for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [r, v] = El2RV( el, tol, mu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   el    (:,6)  Elements vector [a,i,W,w,e,M]           (angles in radians)
%   tol   (1,1)* Tolerance for Kepler's equation solver. (default = 1e-14)
%   mu    (1,1)* Gravitational constant.                 (default = 3.98600436e5)
%
%   -------
%   Outputs
%   -------
%   r     (3,:)  position vector
%   v     (3,:)  velocity vector
%
%--------------------------------------------------------------------------
%   References:	Battin, R.H., An Introduction to the Mathematics and 
%              	Methods of Astrodynamics, p 128.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993, 2015 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2019.1 Update default value of mu
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  el = [8000 0.2 3 0.1 0.2 4];
  [r, v] = El2RV( el );
  DispWithTitle(el,'Elements')
  DispWithTitle(r,'r');
  DispWithTitle(v,'v');
  clear r
  return
end

[m,n] = size(el);

if( m == 1 && n == 6 )
  el = el';
  n  = 1;
end

if( nargin < 3 )
  mu = 3.98600436e5;
end

if( nargin < 2 )
  tol = 1.e-14;
elseif( isempty(tol) )
  tol = 1.e-14;
end

%  Elements vector [a i W w e M]
%-------------------------------
v = zeros(3,n);
r = v;

for k = 1:n
  e      = el(5,k);
  M      = el(6,k);
  a      = el(1,k);
  f      = M2Nu( e, M, tol, 200 );

  if( e ~= 1 )
    p    = a*(1-e)*(1+e);
  else
    p    = a*(1+e);
  end
  
  cf     = cos(f);
  sf     = sin(f);
   
  rp     = p/(1 + e*cf)*[ cf; sf; 0 ];
  vp     = sqrt(mu/p)*[-sf; e+cf; 0];
 
  c      = CP2I( el(2,k), el(3,k), el(4,k) );

  r(:,k) = c*rp;
  v(:,k) = c*vp;
end

%--------------------------------------
% $Date: 2019-02-13 13:51:59 -0500 (Wed, 13 Feb 2019) $
% $Revision: 48010 $
