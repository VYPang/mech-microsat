function [v, f, d] = TubeSatModel( l )

%% Generate vertices and faces for a TubeSat model.
% You can draw the TubeSat model using DrawCubeSat.
% A figure is created if there are no outputs.
%
% Type TubeSatModel for a demo of a single TubeSat.
%--------------------------------------------------------------------------
%   Form:
%   [v, f, d] = TubeSatModel( l )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   l           (1,:) Scaling factor, 1 for single, or 2, 3, 4  
%
%   -------
%   Outputs
%   -------
%   v           (:,3) Vertices
%   f           (:,3) Faces
%   dRHS	      (1,1) Data structure for the function RHSCubeSat
%
%--------------------------------------------------------------------------
%   Reference: TubeSat brochure from Interorbital.com 
%--------------------------------------------------------------------------
%   See also: TubeSatDefaultDataStructure, Frustrum, DrawCubeSat
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2013, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 11.
%   2016.1 - update to use DrawCubeSat for display
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  TubeSatModel( 1 );
  return;
end

if isnumeric(l)
  if length(l)~=1
    error('Please provide a single factor.')
  end
else
  error('Input must be a scalar factor');
end

% Determine the dimenstions from the type
%----------------------------------------
L  = 0.127*l;  % Standard length
OD = 0.0894*l; % Outer diameter

% Use Frustrum to get a cylinder approximated by 16 sides
% i.e. hexadecagon
%-----------------
[v,f] = Frustrum( OD/2, OD/2, L, 16, 0, 0 );

% offset the z axis so the center is at (0,0,0)
v(:,3) = v(:,3) - L/2;

% The first 17 vertices define the bottom of the cylinder

if( nargout == 0 || nargout == 3 )
  d = TubeSatDefaultDataStructure(l);
end

% Default output
%---------------
if( nargout == 0 )
  h = DrawCubeSat( v, f, d );
  set(h,'name',['TubeSat ' num2str(l)])
end

%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
