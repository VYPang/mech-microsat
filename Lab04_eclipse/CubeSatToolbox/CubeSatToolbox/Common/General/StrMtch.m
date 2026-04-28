function k = StrMtch( s, sM )

%% In a matrix with each row a string finds the first matching string.
%
%--------------------------------------------------------------------------
%   Form:
%   k = StrMtch( s, sM )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   s   (1,:)   String
%   sM 	(:,:)   Strings to test
%
%   -------
%   Outputs
%   -------
%   k   (1,:)   Row index for matching string
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

[r,~] = size(sM);

for k = 1:r
  if( strcmp(s,sM(k,1:length(s))) == 1 ) 
	return
  end
end

k = 0;

%--------------------------------------
% $Date: 2019-11-05 15:12:42 -0500 (Tue, 05 Nov 2019) $
% $Revision: 50222 $
