function yes = IsZero( a )

%% Set = 0 if the matrix is all zeros.
%
%   Since version 1.
%--------------------------------------------------------------------------
%   yes = IsZero( a )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   a                         Matrix
%
%   -------
%   Outputs
%   -------
%   yes                       0 if matrix is zero
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1993 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

[ra,ca]=size(a);
if ( ra==0|ca==0 ),
  yes = 0;
  return;
end

yes = norm(a,1);

% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
