function s = ColumnSizeCellArray( m, f )

%% Outputs the size of each column of a cell array.
% Elements of m can be strings or scalars.
%
%--------------------------------------------------------------------------
%   Form:
%   s = ColumnSizeCellArray( m, f )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   m               (n,m)  Cell array
%   f               (1,1)  Width of number fields
%
%   -------
%   Outputs
%   -------
%   f               (1,m)  Maximum width of each column
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2010 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 9.
%--------------------------------------------------------------------------


% Demo
%-----
if( nargin < 1 )
    m = {'a' 1 'c';'bb' 32 'c2'}
    f = 3;
    ColumnSizeCellArray(m,f)
    return
end


[r,c] = size(m);

s = zeros(1,c);

for k = 1:c
    for j = 1:r
        if( ischar(m{j,k}) )
            s(k) = max(s(k),length(m{j,k}));
        else
            s(k) = max(s(k), f );
        end
    end
end



%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
