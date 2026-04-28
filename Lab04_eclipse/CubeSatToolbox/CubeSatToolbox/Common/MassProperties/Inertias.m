function inr = Inertias( m, x, type, ~ )

%% Computes inertias of common objects about their c.m. 
% All objects have their axis of symmetry about z. 
% If you enter a thickness with 'cylinder', 'box' or 'sphere' it will
% automatically compute the hollow versions. 
%
% The output is in the form:
%
% [ixx iyy izz ixy ixz iyz] 
%
% If four arguments are entered it outputs a 3 by 3 matrix.
%
%--------------------------------------------------------------------------
%   Form:
%   inr = Inertias( m, x, type, matType )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   m 		      (1,1) Mass
%   x 		            Relevant dimensions
%   type                Type of solid
%                       'sphere'          x = [radius]
%                       'box'             x = [xLength, yLength, zLength]
%                       'plate'           x = [xLength, yLength]
%                       'disk'            x = [radius]
%                       'cylinder'        x = [radius, zLength] 
%                       'ellipsoid'       x = [a b c]
%                       'hollow cylinder' x = [outer radius, zLength, thickness]
%                       'hollow box'      x = [xLength, yLength, zLength, thickness]
%                       'hollow sphere'   x = [radius, thickness]
%   matType       (1,1) Any argument causes the routine to return a 3x3 matrix
%
%   -------
%   Outputs
%   -------
%   inr     (1,6)   Inertia matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-2000, 2014 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

type = lower(type);

% If thickness is entered use the hollow types
%---------------------------------------------
lX = length(x);
if( strcmp(type,'sphere') == 1 && lX == 2 )
  type = 'hollow sphere';
elseif( strcmp(type,'box') == 1 && lX == 4 )
  type = 'hollow box';
elseif( strcmp(type,'cylinder') == 1 && lX == 3 )
  type = 'hollow cylinder';
end

switch lower( type )
  case 'sphere'
    inr = [1 1 1 0 0 0]*(2/5)*m*x^2;

  case 'ellipsoid'
    inr = [x(2)^2 + x(3)^2 x(1)^2 + x(3)^2 x(1)^2 + x(2)^2 0 0 0]*m/5;
  
  case 'box'
    a   = x(1);
    b   = x(2);
    c   = x(3);
    inr = (m/12)*[b^2 + c^2,a^2 + c^2,a^2 + b^2,0,0,0];
  
  case 'plate'
    inr = (m/12)*[x(2)^2,x(1)^2,x(1)^2+x(2)^2,0,0,0];

  case 'disk'
    a   = 0.25*m*x^2;
    b   = 0.5*m*x^2;
    inr = [a, a, b, 0, 0, 0];
  
  case 'cylinder'
    a   = x(1);
    h   = x(2);
    iP  = (m/12)*(3*a^2 + h^2);
    iA  = (m/2)*a^2;
    inr = [iP,iP,iA,0,0,0];
  
  case 'hollow cylinder'
    a   = x(1);
    b   = x(1) - x(3);
    h   = x(2);
    iP  = (m/12)*(3*a^2 + 3*b^2 + h^2);
    iA  = (m/2)*(a^2 + b^2);
    inr = [iP,iP,iA,0,0,0];
  
  case 'hollow sphere'
    if( x(2) == 0 )
      inr = zeros(1,6);
    else
      a   = x(1);
      b   = x(1) - x(2);
      inr = (2*m/5)*(a^5 - b^5)*[1 1 1 0 0 0]/(a^3 - b^3);
    end
  
  case 'hollow box'
    if( x(4) == 0 )
      inr    = zeros(1,6);
    else
      aO     = x(1);
      bO     = x(2);
      cO     = x(3);
      aI     = aO - x(4);
      bI     = bO - x(4);
      cI     = cO - x(4);
      abcO   = aO*bO*cO;
      abcI   = aI*bI*cI;
      rho    = m/(abcO - abcI);
      inr    = (rho/12)*(   abcO*[bO^2 + cO^2,aO^2 + cO^2,aO^2 + bO^2,0,0,0]...
                          - abcI*[bI^2 + cI^2,aI^2 + cI^2,aI^2 + bI^2,0,0,0]  );
    end
    
  case 'triangle'
    d = x(1);
    b = x(2);
    h = x(3);
    inr = m/6*[b^2+h^2 d^2+h^2 b^2+d^2 0 0 0];
     
  otherwise
    error([type,' is an unknown shape']);  
end

if( nargin > 3 )
  inr = IC623X3( inr );
end


%--------------------------------------
% $Date: 2019-12-27 11:41:15 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50721 $
