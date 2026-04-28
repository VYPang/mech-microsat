function x = CellToMat( c )

%% Converts a cell array to a matrix.
%
%--------------------------------------------------------------------------
%   Form:
%   x = CellToMat( c )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   c	        {}    One dimensional cell array of strings
%
%   -------
%   Outputs
%   -------
%   x         (:)   Matrix
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 3.
%--------------------------------------------------------------------------

if( ~iscellstr( c ) )
  error( 'The input is not a cell array of strings' )
end

[rows, cols] = size( c );

if( rows > 1 && cols > 1 )
  error('Only one dimensional cell arrays are permitted')
end

if( isempty(c) )
  x = '';
else
  x = c{1};

  for k = 2:length(c)
    x = char( x, c{k} );
  end
end

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
