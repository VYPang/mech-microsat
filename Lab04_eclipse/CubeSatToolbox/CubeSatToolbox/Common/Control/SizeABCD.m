function notok = SizeABCD( a, b, c, d )

%% Checks the dimensions of the set a,b,c,d for consistency.
%   d need not be input.
%
%--------------------------------------------------------------------------
%   Form:
%   notok = SizeABCD( a, b, c, d )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                   Plant matrix
%   b                   Input matrix
%   c                   Measurement matrix
%   d                   Input feedthrough matrix (optional)
%
%   -------
%   Outputs
%   -------
%   notok               Not correct if equal to 0
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

[ra,ca]=size(a);
[rb,cb]=size(b);
[rc,cc]=size(c);


if ( nargin==3 )
  d = zeros(rc,cb);
end

[rd,cd]=size(d);

notok = 1;

if ( ra ~= ca )
  notok = 0;
  disp('a must be square')
end

if ( ra ~= rb )
  notok = 0;
  disp('a and b must have the same number of rows')
end

if ( ca ~= cc )
  notok = 0;
  disp('a and c must have the same number of columns')
end

if ( rd ~= rc )
  notok = 0;
  disp('c and d must have the same number of rows')
end

if ( cd ~= cb )
  notok = 0;
  disp('b and d must have the same number of columns')
end

%--------------------------------------
% $Date: 2017-05-02 12:34:43 -0400 (Tue, 02 May 2017) $
% $Revision: 44452 $
