function [f, g] = C2DZOH( a, b, T )

%% Create a discrete time system using a zero order hold.
%
%   Create a discrete time system from a continuous system
%   assuming a zero-order-hold at the input.
%
%   Given
%   .
%   x = ax + bu
%
%   Find f and g where
%
%   x(k+1) = fx(k) + gu(k)
%
%--------------------------------------------------------------------------
%   Form:
%   [f, g] = C2DZOH( a, b, T )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a            (n,n)  Continuous plant matrix
%   b            (n,m)  Input matrix
%   T            (1,1)  Time step
%
%   -------
%   Outputs
%   -------
%   f            (n,n)  Discrete plant matrix
%   g            (n,m)  Discrete input matrix
%
%--------------------------------------------------------------------------
%   References:	Van Loan, C.F., Computing Integrals Involving the Matrix
%               Exponential, IEEE Transactions on Automatic Control
%               Vol. AC-23, No. 3, June 1978, pp. 395-404.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

% Check the inputs
%-----------------
[ra,ca] = size(a); 

if( isempty(b) )
  b = zeros(ra,1);
end

[rb,cb] = size(b);

if ( ra ~= rb )
  error('The number of rows in a must equal the number of rows in b')
end

if ( ra ~= ca )
  error('a must be square')
end

q  = expm([a*T b*T;zeros(cb,ra+cb)]);

f  = q(1:ra,1:ra);
g  = q(1:ra,ra+1:ra+cb); 


%--------------------------------------
% $Date: 2017-05-01 20:11:16 -0400 (Mon, 01 May 2017) $
% $Revision: 44444 $
