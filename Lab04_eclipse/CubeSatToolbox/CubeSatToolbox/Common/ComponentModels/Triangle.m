function [v, f, vol, m] = Triangle( x, y, z, mass )

%% Generate a solid triangle. 
% This function will compute the mass properties data structure if a mass is
% entered. Type Triangle for a demo.
%--------------------------------------------------------------------------
%   Form:
%   [v, f, m] = Triangle( x, y, z, mass )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x           (1,1) x length
%   y           (1,1) y length
%   z           (1,1) z length
%   mass        (1,1) mass
%   
%
%   -------
%   Outputs
%   -------
%   v           (:,3) Vertices
%   f           (:,3) Faces
%   m           (.)   Mass data structure
%
%--------------------------------------------------------------------------
%  See also Volumes, Inertias, DrawVertices
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2002 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2.
%   2017.1 Update drawing code to use DrawVertices
%--------------------------------------------------------------------------

% Demo
%-----
if( nargin < 1 )
  x = 1;
  y = 2;
  z = 3;
  Triangle( x, y, z );
  return;
end

f = [1 2 3;4 5 6;1 6 4;1 3 6;1 4 5;1 5 2;3 2 5;3 5 6];
v = [ x/2  x/2  x/2 -x/2 -x/2 -x/2;...
     -y/2  0  y/2 -y/2  0  y/2;...
      z/2 -z/2  z/2  z/2 -z/2  z/2]';
if (nargout > 2)
    vol = Volumes([x y z], 'triangle');
end
  
if( (nargin > 3) && (nargout > 3) )
  m = Inertias( mass, [x y z], 'triangle', 1 );
else
  m = [];
end
	
% Default output
%---------------
if( nargout == 0 )
  DrawVertices(v,f,'Triangle')
  clear v
end


%--------------------------------------
% $Date: 2017-05-02 10:35:58 -0400 (Tue, 02 May 2017) $
% $Revision: 44446 $
