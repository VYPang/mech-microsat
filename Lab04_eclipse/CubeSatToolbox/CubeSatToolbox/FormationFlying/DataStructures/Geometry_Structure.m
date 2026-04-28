function g = Geometry_Structure( nU )

%% Initialize a geometry data structure.
%
%--------------------------------------------------------------------------
%   Form:
%   g = Geometry_Structure( nU );
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   nU           (1)    Number of geometry structures = # of unique states
%
%   -------
%   Outputs
%   -------
%   g            (.)    Geometry data structure with fields:
%                          - y0
%                          - aE
%                          - beta
%                          - zInc
%                          - zLan
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%  Copyright (c) 2003 Princeton Satellite Systems, Inc.
%  All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.
%--------------------------------------------------------------------------

if( nargin < 1 )
   nU = 1;
end

g = [];

if( nU < 1 )
   warning('number of unique states must be positive!');
   return;
elseif( rem(nU,1) )
   warning('number of unique states must be a whole number!');
   return;
end

for i=1:nU
   g(i).y0   = 0; % along-track offset
   g(i).aE   = 0; % semi-major axis of relative ellipse
   g(i).beta = 0; % phase on relative ellipse (measured from -x axis at equator crossing)
   g(i).zInc = 0; % cross-track amplitude due to inclination difference
   g(i).zLan = 0; % cross-track amplitude due to long. of asc. node difference
end

%--------------------------------------
% $Date: 2019-12-21 20:15:04 -0500 (Sat, 21 Dec 2019) $
% $Revision: 50675 $
