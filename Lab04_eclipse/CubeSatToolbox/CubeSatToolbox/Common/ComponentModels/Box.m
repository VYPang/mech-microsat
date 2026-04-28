function [v, f] = Box( x, y, z, openFace )

%% Generate a box centered at the origin.
% The open face is a character string:
%
%   -x, +x, -y, +y, -z, +z
%
% Type Box for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f] = Box( x, y, z, openFace )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x           (1,1)  x length
%   y           (1,1)  y length
%   z           (1,1)  z length
%   openFace    (1,2)  Which face is open (optional)
%   
%
%   -------
%   Outputs
%   -------
%   v           ( 8,3) Vertices
%   f           (12,3) Faces
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001-2002, 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 5.5
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  x = 1;
  y = 2;
  z = 3;
  openFace = '-z';
  Box( x, y, z, openFace );
  return
end

f   = [2 3 6;3 7 6;3 4 8;3 8 7;4 5 8;4 1 5;2 6 5;2 5 1;1 3 2;1 4 3;5 6 7;5 7 8];
x   = x/2;
y   = y/2;
z   = z/2;

if( nargin > 3 )
  switch lower(openFace)
    case '+x'
	  f( 1: 2,:) = [];
	  
    case '-x'
	  f( 5: 6,:) = [];
	  
    case '+y'
	  f( 3: 4,:) = [];
	  
    case '-y'
	  f( 7: 8,:) = [];
	  
    case '+z'
	  f(11:12,:) = [];
	  
    case '-z'
	  f( 9:10,:) = [];
  end
end

v = [-x  x  x -x -x  x  x -x;...
     -y -y  y  y -y -y  y  y;...
     -z -z -z -z  z  z  z  z]';

% Default outputs
if( nargout == 0 )
	DrawVertices( v, f, 'Box' );
  clear v
end

%--------------------------------------
% $Date: 2020-04-11 23:39:44 -0400 (Sat, 11 Apr 2020) $
% $Revision: 51804 $
