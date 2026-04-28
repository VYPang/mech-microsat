function f = WordToFloat( k, kMax, kMin, resolution )

%% Convert an integer word to a floating point number. 
%   Numbers are assumed to be in standard integer format with kMax <= k <= kMax.
%--------------------------------------------------------------------------
%   Form:
%   f = WordToFloat( k, kMax, kMin, resolution )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   k			         (:)   Integer
%   kMax          (1,1)  Maximum integer
%   kMin          (1,1)  Minimum integer
%   resolution    (1,1)  Floating point value of a 1.
%
%   -------
%   Outputs
%   -------
%   f			  (:)    Floating point value
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%    Copyright (c) 1998 Princeton Satellite Systems, Inc.
%    All rights reserved.
%--------------------------------------------------------------------------

kIn    = k;
j      = find( kIn > kMax );
kIn(j) = kMax;

j      = find( kIn < kMin );
kIn(j) = kMin;

f      = resolution*kIn;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:01:46 -0400 (Thu, 11 May 2017) $
% $Revision: 44560 $
