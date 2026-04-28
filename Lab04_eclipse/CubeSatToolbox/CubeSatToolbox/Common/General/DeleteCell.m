function c = DeleteCell( c, k )

%% Delete a cell element of a one dimensional cell array.
% If k is a logical array, the cells that will be deleted are the ones
% with true values, i.e. c = c(~k)
%--------------------------------------------------------------------------
%   Form:
%   c = DeleteCell( c, k )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   c        {}  Cell array
%   k        (:) Array of elements, or logical array
%
%   -------
%   Outputs
%   -------
%   c        {}  Cell array
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------

if islogical(k)
  c = c(~k);
  return;
end

k = sort(k);

for j = 1:length(k)
  i = k(j) - j + 1;
  c = [c(1:(i-1)) c((i+1):end)];
end


%--------------------------------------
% $Date: 2019-12-27 14:31:09 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50728 $
