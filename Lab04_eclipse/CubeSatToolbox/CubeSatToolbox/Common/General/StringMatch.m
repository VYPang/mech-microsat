function k = StringMatch(s,sA,~)

%% Finds which elements of sA match s
% Uses strcmp and strcmpi internally.
%  
% Type StringMatch for a demo
%
%--------------------------------------------------------------------------
%   Form:
%   k = StringMatch(s,sA,~)
%--------------------------------------------------------------------------
%
%   -------
%   Inputs
%   -------
%   s     (1,:) String
%   sA    {:}   Cell array of strings
%   nC    (1,1) If entered, ignore case
%
%   -------
%   Outputs
%   -------
%   k    (1,:)  Elements of sA that match s
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 2019 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 2019.1
%--------------------------------------------------------------------------

% Demo
if( nargin < 1 )
  strs = {'alt','lat','long','day','alt'};
  StringMatch('alt',strs)
  StringMatch('Alt',strs,1)
  return
end

if( nargin > 2 )
  m = strcmpi(s,sA);
else
  m = strcmp(s,sA);
end

k = find(m == 1);

%--------------------------------------
% $Date: 2019-12-28 21:49:35 -0500 (Sat, 28 Dec 2019) $
% $Revision: 50748 $





