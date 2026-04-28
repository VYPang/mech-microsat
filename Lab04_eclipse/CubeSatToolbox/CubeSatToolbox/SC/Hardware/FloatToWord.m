function k = FloatToWord( f, kMax, kMin, resolution )

%% Convert floating point to word. 
%   Numbers are assumed to be in standard integer format with kMax <= k <= kMax.
%--------------------------------------------------------------------------
%   Form:
%   k = FloatToWord( f, kMax, kMin, resolution )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   f			  (:)    Floating point value
%   kMax          (1,1)  Maximum integer
%   kMin          (1,1)  Minimum integer
%   resolution    (1,1)  Floating point value of a 1.
%
%   -------
%   Outputs
%   -------
%   k			  (:)    Integer
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1998 Princeton Satellite Systems, Inc.
%   All rights reserved.
%--------------------------------------------------------------------------

k    = f/resolution;
j    = find( k > kMax );
k(j) = kMax;

j    = find( k < kMin );
k(j) = kMin;


%--------------------------------------
% PSS internal file version information
%--------------------------------------
% $Date: 2017-05-11 14:01:46 -0400 (Thu, 11 May 2017) $
% $Revision: 44560 $
