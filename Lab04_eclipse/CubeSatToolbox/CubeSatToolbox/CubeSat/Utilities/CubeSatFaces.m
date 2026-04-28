function [a,n,r] = CubeSatFaces( type, rear )

%% Returns the faces along each axis of a linear CubeSat. 
% 1U means a 10 cm cube. The x and y faces are always the long faces.
% Alternatively a custom CubeSat may be specified by the U along each 
% axis, such as [1 2 3] for a 2x3 6U CubeSat.
%--------------------------------------------------------------------------
%   Form:
%   [a,n,r] = CubeSatFaces( type, rear )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   type     (1,:)   'nU' n may be a fraction, i.e. 1.5
%                      or for a custom CubeSat, enter 3 axes: [x y z], as
%                      in [1 2 3] (U)
%   rear     (1,1)   Flag to include the rear faces, i.e. -X, -Y, -Z
%
%   -------
%   Outputs
%   -------
%   a    (1,3) or (1,6)   Areas [aX aY aZ]
%   n    (3,3) or (3,6)   Outward normals
%   r    (3,3) or (3,6)   Location from geometric center of spacecraft
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%   Since version 8.
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
    if nargout == 0
      CubeSatFaces( '1.5U', true );
      return;
    end
    [a,n,r] = CubeSatFaces( '1.5U' );
    disp(a);
    disp(n);
    disp(r);
    return;
end

d = 0.1; % Standard length (m)

if ischar(type)
  j = strfind(lower(type),'u' );
  z = str2num( type(1:(j-1)) )*d; %#ok<ST2NM>
  x = d;
  y = d;
elseif isnumeric(type)
  if length(type)~=3
    error('Please provide the U along x, y, and z.')
  end
  x = type(1)*d;
  y = type(2)*d;
  z = type(3)*d;
end
  
a(1,3) = x*y;
a(1,2) = x*z;
a(1,1) = y*z;
n      = eye(3);
r      = diag([x y z]/2)*n;

if nargin > 1
  % add rear faces
  a = [a a];
  n = [n -n];
  r = [r -r];
end

if( nargout < 1 )
  fprintf(1,'Face areas for a %s CubeSat are [%5.4f %5.4f %5.4f] m^2\n',type,a(1:3));
  [v,f] = CubeSatModel(type,0);
  DrawCubeSat( v, f, struct('rFace',r,'nFace',n) );
  clear a
end


%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
