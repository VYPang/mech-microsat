function s = Factorl( n )

%% Computes the factorial matrix for a matrix.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   Form:
%   s = Factorl( n )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   n           (:,:)  Integer
%
%   -------
%   Outputs
%   -------
%   s           (:,:)  n!
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%	 Copyright 1993 Princeton Satellite Systems, Inc. All rights reserved.
%--------------------------------------------------------------------------

k = find( fix(n) ~= n );
if ( ~isempty(k) )
  error('Some inputs are not integers')
end

k = find( n < 0 );
if( ~isempty(k) )
  error('Inputs must be positive')
end

m       = max(max(n));
fact    = zeros(1,m);
fact(1) = 1;
s       = ones(size(n));
for k = 2:m
  fact(k) = fact(k-1)*k;
  j       = find(n == k);
  s(j)    = fact(k)*ones(size(j));
end

%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
