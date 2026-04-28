function [c, v, ac] = ColCompR( a, neps )

%% Computes the right column compression of a matrix. Compresses the 
%   matrix a so that
%
%   comp(a) = [ 0 c ]
%
%   c is of full column rank, i.e. the columns are linearly independent.
%   Zero columns are determined by the singular values.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form: 
%   [c, v, ac] = ColCompR( a, neps )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Matrix
%   neps                Multiple of machine epsilon to be used
%                       as the tolerance for a zero column
%
%   -------
%   Outputs
%   -------
%   c                   Right column compression of a
%   v                   ac = a*v
%   ac                  a compressed
%
%--------------------------------------------------------------------------
%     References: Maciejowski, J.M., Multivariable Feedback Design, Addison-
%                 Wesley, 1989, pp. 366.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

[u,s,v] = svd(a);   

sd      = diag(s);
 
if ( nargin == 2 ), 
  tol = neps*eps*norm(sd);
else
  tol = eps*norm(sd);
end 

i       = max(find(sd>tol));

[ra,ca] = size(a);
v       = fliplr(v);

ac      = a*v;  
[rc,cc] = size(ac);   

c       = ac(:,cc-i+1:cc);

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
