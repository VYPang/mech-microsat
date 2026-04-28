function [logWMin, logWMax] = LogLimit( wV )

%% Given a frequency vector, find the logarithm of the frequency
% limits that span the set.
%
%--------------------------------------------------------------------------
%   Form:
%   [logWMin, logWMax] = LogLimit( wV )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   wV          Frequency vector
%
%   -------
%   Outputs
%   -------
%   logWMin     Log of the minimum frequency
%   logWMax     Log of the maximum frequency
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% 	Copyright (c) 1993 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

if isempty(wV)
  logWMin = -4;
  logWMax = 1;
else
  w    = wV(find(wV~=0));
  wMin = min(w);
  wMax = max(w); 

  if (isempty(w))
    logWMin = -4;
    logWMax =  1;
  elseif ( length(w) == 1 || wMin==wMax  )
    logWMin = ceil(log10(wMin))-2;
    logWMax = logWMin+4;
  else
    logWMax =  ceil(log10(wMax))+1; 
    logWMin = floor(log10(wMin))-1; 
  end
end

%--------------------------------------
% $Date: 2019-12-27 15:51:53 -0500 (Fri, 27 Dec 2019) $
% $Revision: 50729 $
