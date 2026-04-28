function [sO, c, j, mu, a] = LoadGEM( unNorm )

%% Load the GEMT1 data.
% If there is only one output it will output a data structure.
% GEM is "Goddard Earth Model". GEMT1 dates to 1987.
%
% Loads the GEMT1 mat-file. Corrects the c(2,1) and s(2,1) coefficients for
% consistency with the IERS Terrestrial reference frame
%--------------------------------------------------------------------------
%   Form:
%        gravityModel = LoadGEM( unNorm )
%   [sO, c, j, mu, a] = LoadGEM( unNorm )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   unNorm           If any input here generate unnormalized coefficients
%
%   -------
%   Outputs
%   -------
%   s0       (36,36) S terms  s(n,m) where n and m are degree and order of the model.
%   c        (36,36) C terms  c(n,m)
%   j        (36)    m = 0 terms
%   mu               Spherical gravitational potential
%   a                Earth radius
%
%   or
%
%   gravityModel    (.)   Data structure
%                         .name (1,:) Model name
%                         .mu   (1,1) Gravitational constant (km^3/sec^2)
%                         .a    (1,1) Model earth radius (km)
%                         .c    (n,n) Cosine coefficients
%                         .s    (n,n) Sine coefficients
%                         .j    (1,n) Zonal harmonics
%                         .isNormalized  (1,1) Boolean
%
%--------------------------------------------------------------------------
%   Reference: Seidelmann, P.K, (ed) (1992). Explanatory Supplement to the
%              Astronomical Almanac. University Science Books, Mill Valley, CA.
%              pp. 227-233.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Copyright 1996-1998 Princeton Satellite Systems, Inc. All rights reserved.
% Since version 1.
%--------------------------------------------------------------------------

load GEMT1;

% For consistency with the IERS Terrestrial reference frame
%----------------------------------------------------------
c(2,1) = -0.17e-8;
s(2,1) =  1.19e-9;
isNormalized = true;

if( nargin > 0 )
  
  % m = 0 terms
  %------------
  for n = 1:36
    j(n) = sqrt( 2*n+1 )*j(n);
  end
  
  % Un-Normalize the coefficients
  %---------------------------
  m     = DupVect(1:36,36);
  n     = m';
  fM    = n - m;
  k     = find(fM < 0);
  fM(k) = zeros(size(k));
  fP    = n + m;
  
  f     = sqrt( 2*(2*n + 1).*Factorl(fM)./Factorl(fP) );
  c     = f.*c;
  s     = f.*s;
  
  isNormalized = false;
  
end

if( nargout == 0 )
  Mesh2(1:36,1:36,s,'m','n','Coefficient','GEM-T1 Sine   Coefficients')
  Mesh2(1:36,1:36,c,'m','n','Coefficient','GEM-T1 Cosine Coefficients')
  Plot2D(1:36,j,'Index','Zonals')
else
  sO  = s;
  mu  = 398600.436;
  a   = 6378.137;
  if( nargout == 1 )
    sO      = struct('s',s);
    sO.c    = c;
    sO.j    = j;
    sO.mu   = mu;
    sO.a    = a;
    sO.name = 'earth';
    sO.isNormalized = isNormalized;
  end
end


%--------------------------------------
% $Date: 2017-06-23 15:40:25 -0400 (Fri, 23 Jun 2017) $
% $Revision: 44929 $
