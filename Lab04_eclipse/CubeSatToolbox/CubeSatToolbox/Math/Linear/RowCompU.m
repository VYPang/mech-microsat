function [r, uh, ac] = RowCompU( a, neps )

%% Computes the upper row compression of a matrix. 
% Compresses the  matrix a so that
%
%   comp(a) = [ r ]
%             [ 0 ]
%
% r is of full row rank, i.e. the rows are linearly independent.
% Zero rows are determined by the singular values.
%
%--------------------------------------------------------------------------
%   Form: 
%   [r, uh, ac] = RowCompU( a, neps )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Matrix
%   neps                Multiple of machine epsilon to be used
%                       as the tolerance for a zero row
%
%   -------
%   Outputs
%   -------
%   r                   Upper row compression of a
%   uh                  ac = uh*a
%   ac                  a compressed
%
%--------------------------------------------------------------------------
%   References: Maciejowski, J.M., Multivariable Feedback Design, Addison-
%               Wesley, 1989, pp. 366.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

[u,s] = svd(a);

sd      = diag(s); 

if ( nargin==2 ) 
  tol = neps*eps*norm(sd);
else
  tol = eps*norm(sd);
end 

i       = find(sd>tol, 1, 'last' ); 

ac      = u'*a;

r       = ac(1:i,:);

uh      = u';


%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
