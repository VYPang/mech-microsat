function f = FrictionSmooth( x, d )

%% Rotary friction model using differentiable functions. 
% This model uses functions that are differentiable making it suitable for 
% numerical simulations. 
%--------------------------------------------------------------------------
%   Form:
%   f = FrictionSmooth;
%   f = FrictionSmooth( x, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x             (:)     Rates
%   d             (:)     .fStatic   - Static friction maximum
%                         .kStatic   - Static friction scaling coefficient
%                         .fCoulomb  - Coulomb friction maximum
%                         .kCoulomb  - Coulomb friction scaling coefficient
%                                        (higher means a faster rise)
%                         .bViscous  - Viscous friction coefficient
%
%   -------
%   Outputs
%   -------
%   f             (:)    Friction
%
%--------------------------------------------------------------------------
%   See also RWA.m and SmoothFrictionDemo.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1999 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   2019.1 Added default data structure
%--------------------------------------------------------------------------

if( nargin < 1 )
  f = struct('fStatic',10,'kStatic',10,'fCoulomb',0,'kCoulomb',1,'bViscous',0);
  return
end

% Check input lists
%------------------
if( nargin < 2 )
  fCoulomb = 0; % 1
  kCoulomb = 1;
  fStatic  = 3; % 3
  kStatic  = 10;
  bViscous = 0; % 1
end

if( nargin < 1 )
  x = linspace(-5,5);
  
else
  % Convert struct fields to vectors
  %---------------------------------
  
  fCoulomb = [];
  kCoulomb = [];
  fStatic  = [];
  kStatic  = [];
  bViscous = [];
  
  for i = 1:length(d)
      fCoulomb = [ fCoulomb; d(i).fCoulomb ];
      kCoulomb = [ kCoulomb; d(i).kCoulomb ];
      fStatic  = [ fStatic;  d(i).fStatic  ];
      kStatic  = [ kStatic;  d(i).kStatic  ];
      bViscous = [ bViscous; d(i).bViscous ];
  end
    
  [rowsX, colsX] = size(x);
  [rowsC, colsC] = size(kCoulomb);
  if( rowsC == colsX )
    x = x';
  end
end


% Coulomb
%--------
eC = 1./(1 + exp(- kCoulomb .* x));
fC = fCoulomb.*(eC - 0.5);

u  = kStatic.*x;
fS = 2*fStatic.*u./(1 + u.^2);
fV = bViscous.*x;

f  = fC + fS + fV;

% Plotting
%---------
if( nargout == 0 )
  Plot2D( x, [f;fC;fS;fV],'Velocity',['Total  ';'Coulomb';'Static ';'Viscous'],'Friction' );
  clear f
end

%--------------------------------------
% $Date: 2019-12-17 23:29:53 -0500 (Tue, 17 Dec 2019) $
% $Revision: 50623 $
