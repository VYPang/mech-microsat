function p = Period( a, mu )

%% Compute the period for an orbit.
% You specify the semi-major axis. The default central body is the Earth.
%
% Type Period for a demo
%
%--------------------------------------------------------------------------
%   Form:
%   p = Period( a, mu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a   (1,:) Semi-major axis (inf for a parabola and negative for a hyperbola)
%   mu	(1,1) Gravitational parameter (default = Earth)
%
%   -------
%   Outputs
%   -------
%   p   (1,:) Period (s)
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993-2019 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%   2019.1 Removed Cartesian option and added a demo.
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  Period(linspace(6000,100000));
  return;
end

if( nargin < 2 )
  mu = 3.98600436e5;
end

i = find( a <= 0 | a == inf );

if( ~isempty(i) )
  p(i) = inf*ones(size(i));
end

i = find( a > 0 & a < inf );

if( ~isempty(i) )
  p(i) = 2*pi*sqrt(a(i).^3/mu);
end

if( nargout == 0 )
  Plot2D(a,p,'Semi-major Axis','Period','Orbit Period')
  clear p
end

%--------------------------------------
% $Date: 2019-02-12 16:59:20 -0500 (Tue, 12 Feb 2019) $
% $Revision: 48002 $
