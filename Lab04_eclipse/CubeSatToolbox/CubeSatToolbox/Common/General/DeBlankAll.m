function s = DeBlankAll( s )

%% Delete all blanks 
% Including spaces, new lines, carriage returns, tabs, vertical tabs, 
% and formfeeds.
%--------------------------------------------------------------------------
%   Form:
%   s = DeBlankAll( s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s      (1,:)   Character string
%
%   -------
%   Outputs
%   -------
%   s      (1,:)   Character string
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

if( ~isempty(s) )
  k = find( isspace( s ) == 1 );
  s(k) = [];
end

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
