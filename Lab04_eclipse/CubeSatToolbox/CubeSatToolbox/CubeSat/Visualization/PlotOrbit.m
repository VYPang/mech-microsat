function [h, l] = PlotOrbit( r, t, jD0 )

%% Plot the state in 3D with an Earth map. 
%
% Note that the location relative to the map is only accurate for
% Earth-fixed frame input. Enter time and Julian date to compute the
% Earth-fixed positions from ECI data automatically.
%
%--------------------------------------------------------------------------
%   Form:
%   [h, l] = PlotOrbit( rEF )
%   [h, l] = PlotOrbit( rECI, t, jD0 )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   r         (3,m)  Position vectors (km)
%           or
%              {n}   Cell array of position matrices for multiple satellites
%   t         (1,:)  Time array (sec)
%   jD0       (1,1)  Epoch Julian date
%
%   ------
%   Output
%   ------
%   h         (1,1)  Figure handle
%   l         (1,n)  Handle to orbit lines
%
%--------------------------------------------------------------------------
%   See also: LoadEarthMap
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009, 2015, 2020 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%   2020.1 Added line handle output
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  angle = linspace(0,2*pi);
  r{1}  = 8000*[cos(angle);sin(angle);zeros(1,100)];
  inc   = pi/4;
  r{2}  = 9000*[cos(angle);cos(inc)*sin(angle);sin(inc)*sin(angle)];
  PlotOrbit( r );
  return;
end

if iscell(r)
  nSats = length(r);
else
  r = {r};
  nSats = 1;
end

if nargin > 1
  % Array of Julian century
  %------------------------
  T = JD2T(jD0 + t/86400);

  % Transform to the planet fixed frame
  %------------------------------------
  nT = length(t);
  for k = 1:nT
    m = ECIToEF( T(k) );
    for j = 1:nSats
      r{j}(:,k) = m*r{j}(:,k);
    end
  end
end

% Load the Earth and plot
%------------------------
h = LoadEarthMap;
hold on
l = zeros(1,nSats);
for j = 1:nSats
  rT = r{j};
  l(j) = plot3( rT(1,:), rT(2,:),rT(3,:),'color', [1 1 1] );
end
hold off


%--------------------------------------
% $Date: 2020-04-25 12:36:39 -0400 (Sat, 25 Apr 2020) $
% $Revision: 51970 $
