function [v, f] = Cone( p, u, halfAngle, l, n )

%% Compute the vertices for a cone.
% The cone emanates from p and points in direction u. If no outputs are
% specified the cone will be drawn in a new figure. 
%
% Type Cone for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f] = Cone( p, u, halfAngle, l, n)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   p            (3,1) Location of apex
%   u            (3,1) Cone axis unit vector
%   halfAngle    (1,1) Cone half angle (rad)
%   l            (1,1) Length of cone
%   n            (1,1) Number of divisions
%
%   -------
%   Outputs
%   -------
%   v            (:,3) Vertices
%   f            (:,3) Faces
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2007 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 7.1
%   Version 2018.1 Removed unused color input.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  Cone( [0;1;0], [1;0;0], 0.2, 2, 10 );
  return;
end

if( nargin < 5 )
  n = [];
end

if( isempty(n) )
  n = 10;
end

% Create the cone
%-----------------
rL = l*tan(halfAngle);

[v, f] = Frustrum( rL, 0, l, n, 1, 1 );

% Rotate the cone
%----------------
q  = U2Q( [0;0;1], u );

v  = QForm( q, v' )';

% Translate the cone
%-------------------
v  = v + DupVect(p',size(v,1));

% Default output
%---------------
if( nargout == 0 )
  DrawVertices(v,f,'Patch')
  clear v
end


%--------------------------------------
% $Date: 2020-07-03 12:39:22 -0400 (Fri, 03 Jul 2020) $
% $Revision: 52976 $
