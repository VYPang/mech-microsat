function s = DeBlankLT( s )

%% Delete leading and trailing blanks.
%
%--------------------------------------------------------------------------
%   Form:
%   s = DeBlankLT( s )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s      (1,:)   Character string or cell array
%
%   -------
%   Outputs
%   -------
%   s      (1,:)   Character string or cell array
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998-2000 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 3.
%--------------------------------------------------------------------------

if( iscell(s) )
  for j = 1:length(s)
    k     = min(find( isspace( s{j} ) == 0 ) );
    s{j}  = deblank(s{j}(k:end));
  end
else  
  n = isspace(s);
  if( ~isempty(n) )
    k = min(find( n == 0 ) );
    s = deblank(s(k:end));
  end
end

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
