function t = StringToTokens( s, delimiters, noSpace )

%% Converts a string to a list of tokens.
%
%--------------------------------------------------------------------------
%   Form:
%   t = StringToTokens( s, delimiters, noSpace )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s          (:)   String (may be a cell element)
%   delimiters (:)   List of delimiters added to whitespace
%   noSpace    (1,1) If entered will not use whitespace as a delimiter
%
%   -------
%   Outputs
%   -------
%   t          {}    Cell array of tokens
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 3.
%--------------------------------------------------------------------------

if( nargin > 1 && nargin < 3 )
  delimiters = [9:13 32 delimiters];
elseif( nargin < 2 )
  delimiters = [9:13 32];
end

if( iscell( s ) )
  s = char( s );
end

k = 0;
t = {};
while( ~isempty(s) )
  k      = k + 1;
  [j, s] = strtok( s, delimiters );
  if( ~isempty(j) )
    t{k} = j;
  end
end

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
