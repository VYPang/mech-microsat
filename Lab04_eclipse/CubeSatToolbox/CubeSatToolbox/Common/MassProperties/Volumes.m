function vol = Volumes(x, type)

%% Computes volumes of common objects about their c.m. 
% All objects have their axis of symmetry about z. If you enter a thickness with
% 'cylinder', 'box' or 'sphere' it will automatically compute the hollow
% versions. The 'cylindrical end caps' type has spherical end caps with the
% given radius.
%--------------------------------------------------------------------------
%   Form:
%   vol = Volumes( x, type)
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x 		           Relevant dimensions
%   type             Type of solid
%                     'sphere'           x = [radius]
%                     'cylinder'         x = [radius, zLength] 
%                     'box'              x = [xLength, yLength, zLength]
%                     'ellipsoid'        x = [a b c]
%                     'plate'            x = [xLength, yLength]
%                     'disk'			       x = [radius, thickness]
%                     'hollow cylinder'  x = [outer radius, zLength, thickness]
%                     'hollow box'       x = [xLength, yLength, zLength, thickness]
%                     'hollow sphere'    x = [radius, thickness]
%                     'torus'            x = [R major,r minor]
%                     'elliptical torus' x = [R major,a minor,b minor]
%                     'cone'             x = [radius,height]
%                     'pyramid'          x = [base,height]
%                     'cylindrical end caps'   x = [radius,length]
%
%   -------
%   Outputs
%   -------
%   vol     (1,1)  Volume
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995-2011, 2017 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 10.
%   2017.1 Add some more shapes (torus, cone, pyramid)
%--------------------------------------------------------------------------

if( nargin < 1 )
  Volumes([2,3,4],'ellipsoid');
  return;
end

type = lower(type);

% If thickness is entered use the hollow types
lX = length(x);
if( strcmp(type,'sphere') == 1 && lX == 2 )
  type = 'hollow sphere';
elseif( strcmp(type,'box') == 1 && lX == 4 )
  type = 'hollow box';
elseif( strcmp(type,'cylinder') == 1 && lX == 3 )
  type = 'hollow cylinder';
end

switch lower( deblank(type) )
  case 'sphere'
    vol = 4/3*pi*x^3;

  case 'ellipsoid'
    a   = x(1);
    b   = x(2);
    c   = x(3);
    vol = 4/3*pi*a*b*c;
  
  case 'box'
    a   = x(1);
    b   = x(2);
    c   = x(3);
    vol = a*b*c;
  
  case 'plate'
    a   = x(1);
    b   = x(2);
    c   = x(3);
    vol = a*b*c;
  
  case 'disk'
    r   = x(1);
    t   = x(2);
	  vol = pi*r^2*t;
  
  case 'cylinder'
    r   = x(1);
    h   = x(2);
	  vol = pi*r^2*h;
  
  case 'hollow cylinder'
    r   = x(1);
    b   = x(1)-x(3);
    h   = x(2);
    vol = pi*h*(r^2-b^2);
  
  case 'hollow sphere'
    R = x(1);
    r = x(1)-x(2);
    vol = 4/3*pi*(R^3-r^3);
  
  case 'hollow box'
    a   = x(1);
    b   = x(2);
    c   = x(3);
    a2  = x(1)-x(4);
    b2  = x(2)-x(4);
    c2  = x(3)-x(4); 
    vol = a*b*c-a2*b2*c2;
  
  case 'triangle'
    d = x(1);
    b = x(2);
    h = x(3);
    vol = 1/2*b*h*d;
      
  case 'torus'
    Rmajor = x(1);
    Rminor = x(2);
    vol = (pi*Rminor^2)*2*pi*Rmajor;
    
  case 'elliptical torus'
    Rmajor = x(1);
    Aminor = x(2);
    Bminor = x(2);
    vol = pi*Aminor*Bminor*2*pi*Rmajor;
     
  case 'cone'
    radius = x(1);
    height = x(2);
    vol = (1/3)*pi*radius^2*height;
    
  case 'pyramid'
    base = x(1);
    height = x(2);
    vol = (1/3)*base*height;
    
  case 'cylindrical end caps'
    radius = x(1);
    l = x(2);
    vol = pi*radius^2*(l + (4/3)*radius);
    
  otherwise
    error([type,' is an unknown shape']);  
end

% Default output
if( nargout < 1 )
    fprintf(1,'Volume of the %s is %f\n',type,vol);
    clear v;
end


%--------------------------------------
% $Date: 2020-04-22 14:36:52 -0400 (Wed, 22 Apr 2020) $
% $Revision: 51915 $

