function t = IsVersionAfter( n )

%% Checks to see if the version of MATLAB is after n
%--------------------------------------------------------------------------
%   Form:
%   t = IsVersionAfter( n )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   n             (1,1)   Number
%
%   -------
%   Outputs
%   -------
%   t             (1,1)   1 or 0
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2001 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

v = version;
nums = StringToTokens(v,'.');
ver1 = str2double(nums{1});
if length(nums) > 1
  ver2 = str2double(nums{2});
else
  ver2 = 0;
end

check1 = floor(n);
checks = StringToTokens( num2str(n),'.' );
if length(checks) > 1
  check2 = str2num(checks{2});
else
  check2 = 0;
end

t = 0;
if( ver1 > check1 )
  t = 1;
elseif ( ver1 == floor(n) && ver2 > check2 )
  t = 1;
end

%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
