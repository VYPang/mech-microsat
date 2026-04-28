function [f,fp] = NormalizationMatrix( nN, nM )

%% Generate a normalization matrix for spherical harmonics
% c unnormalized * f = c normalized
% s unnormalized * f = s normalized
% p normalized   = p unnormalized / fp
%--------------------------------------------------------------------------
%   Form:
%   [f,fp] = NormalizationMatrix( nN, nM )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   nN	(1,1)  Rows
%   nM 	(1,1)  Columns
%
%   -------
%   Outputs
%   -------
%   f	 (nN,mM)   State derivatives 
%   fp (1,nM)    Coefficients for p (zonal terms)
%
%--------------------------------------------------------------------------
%   See also UnnormalizeGravity
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2016 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since 2016.1
%   2017.1 Separate into two outputs for c/s terms and j terms
%--------------------------------------------------------------------------


if( nargin < 1 )  
  NormalizationMatrix( 4, 4 );
  return
end

fp = zeros(1,nN);
for n = 1:nN
  fp(n) = 1/sqrt(2*n+1);
end

f = zeros(nN,nM);
for m = 1:nM
  for n = 0:nN
    if( m <= n )
      f(n,m) = sqrt( FactorialRatio(n,m)/(2*(2*n + 1)) );
    end
  end
end

j = f==0;
f(j) = 1;

if nargout == 0
  DispWithTitle( f, 'f' )
  DispWithTitle( fp, 'fp' )
end

function r = FactorialRatio(n,m)

r = 1;
for k = n-m+1:n+m
  r = r*k;
end
 

%--------------------------------------
% $Date: 2017-06-23 15:40:25 -0400 (Fri, 23 Jun 2017) $
% $Revision: 44929 $
