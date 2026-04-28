function m = Mag( u )

%% Magnitude of a set of vectors
% Given a 3-by-n matrix where each column represents a vector, return a row
% vector of the magnitudes of each column.
%--------------------------------------------------------------------------
%   Form:
%   m = Mag( u )
%--------------------------------------------------------------------------
%
%   ------
%   Inputs
%   ------
%   u            (:,:)  Vectors
%
%   -------
%   Outputs
%   -------
%   m            (:)   Corresponding magnitudes
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%   Copyright (c) 1995 Princeton Satellite Systems, Inc. 
%   All rights reserved.
%--------------------------------------------------------------------------
%   Since version 1.
%--------------------------------------------------------------------------

m = sqrt(sum(u.^2));


%--------------------------------------
% $Date: 2017-05-11 17:07:25 -0400 (Thu, 11 May 2017) $
% $Revision: 44577 $
