function [num, den] = SS2ND( a, b, c, d, iu )

%% Converts from state space to numerator denominator form.
%
%   Creates a transfer function model of a state-space system from
%   one input channel to all of the output channels using
%   the relationship
%
%                       det(sI-A+bc) - (1-d)det(sI-A)
%   c*inv(sI-A)*b + d = -----------------------------
%                               det(sI-A) 
%
%   where c is a row vector and b a column vector.
%
%--------------------------------------------------------------------------
%   Form:
%   [num, den] = SS2ND( a, b, c, d, iu )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Plant matrix
%   b                   Input column vector
%   c                   Output row vector
%   d                   Feedthrough element
%   iu                  Input channel
%
%   -------
%   Outputs
%   -------
%   num                 Numerator polynomial(s) one output per row
%   den                 Denominator polynomial
%
%--------------------------------------------------------------------------
%   References:	Kalaith, T., Linear System, Prentice-Hall, Englewood-Cliffs,
%               NJ, 1980.
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if ( nargin==4 )
  cb=size(b,2);
  iu = 1:cb;
end

rc=size(c,1);

if ( SizeABCD(a,b(:,iu),c,d(:,iu)) == 0 )
  return
end

% The denominator polynomial

sa  = eig(a);
den = real(poly(sa));

% The numerator polynomial(s)
num = [];
for iy=1:rc 
  sb           = eig(a-b(:,iu)*c(iy,:));
  numiy        = real(poly(sb)) - (1-d(iy,iu))* real(poly(sa)); 
  i            = find(abs(numiy)<10000*eps*norm(numiy)); 
  numiy(i)     = zeros(1,length(i));
  i            = min(find(abs(numiy)>0)); 
  n            = length(numiy);
  if (isempty(i))
    i = 1;
  end 
  [rn,cn]      = size(num); 
  if (n-i+1>cn && iy > 1)
    num = [zeros(rn,n-i+1-cn),num];
  end
  num(rn+1,i:n) = numiy(i:n);  
end

num = DelLZ(num); 
  

%--------------------------------------
% $Date: 2017-05-02 12:34:43 -0400 (Tue, 02 May 2017) $
% $Revision: 44452 $

