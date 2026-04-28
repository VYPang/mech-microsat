function [y,k] = WrapSegments( x, tol )

%% Separate a wrapped vector into a series of segments in cells.
%
%--------------------------------------------------------------------------
%   Form:
%   [y,k] = WrapSegments( x, tol )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   x       (1,:)    Vector of data points
%   tol     (1,1)    Jump tolerance. 
%                    If x(k+1)-x(k) > tol, the segment ends at x(k).
%   
%   -------
%   Outputs
%   -------
%   y       {1,n}    Cell array of segments. 
%                    Each segment "i" is 1 x m(i) array and sum(m)=n
%   k       {1,n}    Cell array of index values so that: y{j} = x( k{j} );
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2009 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 8.
%--------------------------------------------------------------------------

if( nargin < 2 )
   tol = pi;
end

dx    = diff(x);
jump  = find(abs(dx)>=tol);
jump  = [jump,length(x)];
k     = cell(1,length(jump));
y     = cell(1,length(jump));
k{1}  = 1:jump(1);
y{1}  = x(k{1});

for i=2:length(jump)
   k{i} = jump(i-1)+1:jump(i);
   y{i} = x(k{i});
end

%--------------------------------------
% $Date: 2019-09-06 11:24:45 -0400 (Fri, 06 Sep 2019) $
% $Revision: 49727 $
