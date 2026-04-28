function [mFront, mBack] = ArrayPatch( d )

%% Get vertices and faces for solar array CAD models.
% Two sets are created, one for the front and one for the back. The array is
% nominally in the xz-plane. Its center is at x = 0 and it goes from z = 0 to z
% = length. The cell face normal is +Y. 
%
% If there are no outputs the function will draw the components in a figure.
%--------------------------------------------------------------------------
%   Form:
%   [mFront, mBack] = ArrayPatch( d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   d                 Data structure
%                     d.nZ          Number of segments along z
%                     d.nX          Number of segments along x
%                     d.z           Dimension of each panel in z
%                     d.x           Dimension of each panel in x
%                     d.theta(d.nX) Angle between panels along z. Sign determines
%                                   the sign of the first panel.
%                                   One element is required for each nX
%                                   If omitted will be set to zero.
%                     d.accordion   If true don't alternate angles
%                     d.dirZ        If entered gives the direction for z
%
%   -------
%   Outputs
%   -------
%   mFront            struct( 'v', 'f' )
%   mBack             struct( 'v', 'f' )
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
% Since version 2.
%--------------------------------------------------------------------------

% Input processing
%-----------------
if( nargin < 1 )
  error('One input is required');
end

if( isfield( d, 'theta' ) )
  s = d.z*sin(d.theta);
  c = d.z*cos(d.theta);
else
  s = zeros(1,d.nX);
  c = d.z*ones(1,d.nX);
end

if( isfield( d, 'flat' ) && d.flat == 1 )
  alternate = 0;
else
  alternate = 1;
end

if( ~isfield( d, 'dirZ' ) )
  d.dirZ = 1;
end

% Create the vertex list
%-----------------------
nV       = d.nX*2*(1 + d.nZ);
mFront.v = zeros(nV,3);

nV = 1;
x  = -(d.nX/2)*d.x;
for k = 1:d.nX
  z = 0;
  y = 0;
  for j = 1:(d.nZ+1)
    if( alternate )
      y = OddSign(j)*s(k);
      mFront.v(nV,:)   = [x     y z];
      mFront.v(nV+1,:) = [x+d.x y z];
    else
      mFront.v(nV,:)   = [x     y z];
      mFront.v(nV+1,:) = [x+d.x y z];
      y = y + j*s(k);
    end
    nV               = nV + 2;
    z                = z + d.dirZ*c(k);
  end
  x = x + d.x;
end

% Displace the back face a small amount
%--------------------------------------
dY       = 0.01*d.x;
n        = size(mFront.v,1);
mBack.v  = mFront.v + [zeros(n,1) dY*ones(n,1) zeros(n,1)];
mFront.v = mFront.v - [zeros(n,1) dY*ones(n,1) zeros(n,1)];

% Create the face list
%---------------------
nF       = 2*d.nX*d.nZ;
mFront.f = zeros(nF,3);
mBack.f  = zeros(nF,3);

nF = 1;
nV = 1;
for k = 1:d.nX
  for j = 1:d.nZ
    mFront.f(nF,:)   = [nV   nV+2 nV+1];
    mFront.f(nF+1,:) = [nV+2 nV+3 nV+1];
    mBack.f(nF,:)    = [nV   nV+1 nV+2];
    mBack.f(nF+1,:)  = [nV+2 nV+1 nV+3];
    nF = nF + 2;
    nV = nV + 2;
  end
  nV = nV + 2;
end

mFront.f = fliplr(mFront.f);
mBack.f  = fliplr(mBack.f);

% Draw the object
%----------------
if( nargout == 0 )
  NewFig('Array Patch')
  patch('vertices',mFront.v,'faces',mFront.f,'facecolor',[0.0 0.0 0.5]);
  patch('vertices',mBack.v, 'faces',mBack.f, 'facecolor',[0.5 0.5 0.5]);

  % Set limits on the drawing
  %--------------------------
  zLim = 1.2*[ min( mFront.v(:,3) ) max( mFront.v(:,3) ) ];
  xLim = 1.2*[ min( mFront.v(:,1) ) max( mFront.v(:,1) ) ];
  set(gca,'zlim',zLim,'xLim',xLim);
  axis equal
  XLabelS('x')
  YLabelS('y')
  ZLabelS('z')
  view([0;1;0])
  grid on
  rotate3d on
end

%--------------------------------------------------------------------------
%   Returns a -1 for odd numbers
%--------------------------------------------------------------------------
function k = OddSign( x )

k = rem( x, 2 );

if( k == 1 )
  k = -1;
else
  k =  1;
end

% PSS internal file version information
%--------------------------------------
% $Date: 2020-06-03 11:33:54 -0400 (Wed, 03 Jun 2020) $
% $Revision: 52628 $
