function h = Altitude( r, f, a, units )

%% Computes the altitude above an ellipsoidal planet.
%
%--------------------------------------------------------------------------
%   Form:
%   h = Altitude( r, f, a, units )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r             (3,:)   ECI position vectors (units)
%   f             (1,1)   Flattening factor
%   a             (1,1)   Equatorial radius
%   units         (1,:)   Units, mks or other
%
%   -------
%   Outputs
%   -------
%   h             (1,:)   Altitude (units)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1997-2000 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if( nargin < 1 )
  r = [];
end
 
if( nargin < 2 )
  f = [];
end

if( nargin < 3 )
  a = [];
end

if( nargin < 4 )
  units = 'mks';
else
  units = lower(deblank(units));
end

% This is for the aicraft toolbox
%--------------------------------
if( nargin == 2 && ischar(f) )
  units = f;
  f     = [];
end

if( isempty(r) )
  r = [6378140;0;0];
end

if( isempty(f) )
  f  = 1/298.257;
end

% Functions of f
%---------------
aOB   = 1/(1-f);
oMAOB = 1 - aOB;

if( isempty(a) )
  if( strcmp( units, 'mks' ) || strcmp( units, 'si' ) )
    a = 6378140;
  else
    a = 2.092565616797901e+07;
  end
end

b        = a/aOB;

tol      = 1.e-8;
tau      = 0.01;

delta    = 1;

% Find the equivalent planar problem
%-----------------------------------
xP       = sqrt(r(1,:).^2 + r(2,:).^2);
zP       = r(3,:);

rS       = sqrt(xP.^2 + zP.^2);
x        = (a./rS).*xP;
sgnSqrt  = sign(zP);
n        = length(xP);

while ( delta > tau )
  dX          = zeros(1,n);
  xOA         = x/a;
  q           = sgnSqrt*b.*sqrt((1-xOA).*(1 + xOA));
  k           = find(abs(q) > eps);
  if( ~isempty(k) )
    t     = x(k)*oMAOB + xP(k)*aOB;
    f     = q(k).*t - x(k).*zP(k);
    fD    = -(x(k)/aOB).*t./q(k) + q(k)*oMAOB - zP(k);
    dX(k) = -f./fD;
  end
  x           = x + dX;
  delta       = norm(abs(dX),'inf');
  tau         = tol*max(norm(x,'inf'),1.0);
end

k  = find(zP > 0);
if( k > 0 )
  z(k)  = real(b*sqrt(1-(x(k)/a).^2));
end

k = find(zP <= 0);
if( k > 0 )
  z(k)  = -real(b*sqrt(1-(x(k)/a).^2));
end

theta = atan2( r(2,:), r(1,:) );
y     = x.*sin(theta);
x     = x.*cos(theta);
dR    = r - [x;y;z];
hX    = real(sqrt(sum(dR.*dR)));

if( nargout == 0 )
  Plot2D(1:n,hX,'Sample','Altitude')
else
  h = hX;
end

%--------------------------------------
% $Date: 2019-12-27 11:31:14 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50720 $
